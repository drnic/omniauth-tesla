#!/bin/bash

set -eo pipefail

# Flow discussed in
# https://shankar-k.medium.com/tesla-developer-api-guide-account-setup-app-creation-registration-and-third-party-da24aba1bddd

: ${TESLA_CLIENT_ID:?required}
: ${TESLA_CLIENT_SECRET:?required}
AUDIENCE=${AUDIENCE:-https://fleet-api.prd.na.vn.cloud.tesla.com}
: ${PUBLIC_TUNNEL_HOST:?required}
scope="user user2 data userdata use_data i_made_this_up user_data profile ou_code email openid offline_access vehicle_device_data vehicle_cmds vehicle_charging_cmds"
state=${state:-123456781234}

# Some scopes in developer.tesla.com own /authorize call:
# offline_access+user+profile+ou_code+email
# though it is using:
# https://auth.tesla.com/en_au/oauth2/v1/authorize
# instead of:
# https://auth.tesla.com/oauth2/v3/authorize

# if not jwt cli installed show error:
if ! command -v jwt >/dev/null; then
  echo "'jwt' cli not installed, install with:"
  echo "brew install jwt-cli"
fi

# if refresh_token.txt doesn't exist then:
if [[ -f refresh_token.txt ]]; then
  echo "refresh_token.txt exists so using it"
  echo
else
  # Generates a token to be used for managing a partner's account or devices they own.
  # https://developer.tesla.com/docs/fleet-api#generating-a-partner-authentication-token
  # BUT - the partner auth token isn't supported by the API
  # https://github.com/teslamotors/vehicle-command/issues/17
  auth_response=$(
    curl -sS -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=client_credentials" \
      --data-urlencode "client_id=${TESLA_CLIENT_ID}" \
      --data-urlencode "client_secret=${TESLA_CLIENT_SECRET}" \
      --data-urlencode "scope=${scope}" \
      --data-urlencode "audience=$AUDIENCE" \
      "https://auth.tesla.com/oauth2/v3/token"
  )

  echo $auth_response
  partner_auth_token=$(echo "$auth_response" | jq -r .access_token)
  echo "Access token is JWT that looks like:"
  echo "$partner_auth_token" | jwt decode -

  # openssl ecparam -name prime256v1 -genkey -noout -out private.pem
  # openssl ec -in private.pem -pubout -out com.tesla.3p.public-key.pem

  echo "curl ${AUDIENCE}/api/1/partner_accounts"
  curl -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $partner_auth_token" \
    --data "$(jq --null-input --arg host "$PUBLIC_TUNNEL_HOST" '{"domain": $host}')" \
    "${AUDIENCE}/api/1/partner_accounts"
  echo

  echo "curl ${AUDIENCE}/api/1/partner_accounts/public_key?domain=$PUBLIC_TUNNEL_HOST"
  curl -H "Content-Type: application/json" \
    -H "Authorization: Bearer $partner_auth_token" \
    "${AUDIENCE}/api/1/partner_accounts/public_key?domain=$PUBLIC_TUNNEL_HOST"
  echo
  echo
  echo "NOTE: Now turn off the rackup rails server."
  echo
  echo "Visit this URL:"
  echo "https://auth.tesla.com/oauth2/v3/authorize?client_id=${TESLA_CLIENT_ID}&redirect_uri=https%3A%2F%2F${PUBLIC_TUNNEL_HOST}%2Fauth%2Ftesla%2Fcallback&response_type=code&scope=${scope// /+}&state=${state}"
  echo
  echo "When the auth sequence is finished and it fails to redirect to the callback URL"
  echo "since the app is not running, copy the code=XYZ from the URL and paste it here:"
  read code

  echo "curl https://auth.tesla.com/oauth2/v3/token"
  token_response=$(
    curl -sS 'https://auth.tesla.com/oauth2/v3/token' \
      -H 'Content-Type: application/json' \
      -d "$(jq -n \
        --arg client_id "$TESLA_CLIENT_ID" \
        --arg client_secret "$TESLA_CLIENT_SECRET" \
        --arg code "${code:?required}" \
        --arg scope "$scope" \
        '{
            grant_type: "authorization_code",
            client_id: $client_id,
            client_secret: $client_secret,
            code: $code,
            scope: $scope,
            audience: "https://fleet-api.prd.na.vn.cloud.tesla.com",
            redirect_uri: "https://rails-9292.drnicwilliams.com/auth/tesla/callback"
          }')"
  )

  echo "/token response:"
  echo "$token_response" | jq -r .
  echo

  access_token=$(echo "$token_response" | jq -r .access_token)
  refresh_token=$(echo "$token_response" | jq -r .refresh_token)

  echo "access_token: ${access_token}"
  echo $access_token | jwt decode -
  echo

  echo "refresh_token: ${refresh_token}"
  # refresh token is no longer a JWT apparently
  # echo $refresh_token | jwt decode -
  echo

  echo "Saving access_token to access_token.txt"
  echo "$access_token" >access_token.txt

  echo "Saving refresh_token to refresh_token.txt"
  echo "$refresh_token" >refresh_token.txt
fi

echo
echo "Refreshing access token:"
response=$(
  curl -sS https://auth.tesla.com/oauth2/v3/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=refresh_token" \
    --data-urlencode "client_id=${TESLA_CLIENT_ID}" \
    --data-urlencode "refresh_token=$(cat refresh_token.txt)"
)
echo "Saving access_token to access_token.txt"
echo "$response" | jq -r .access_token >access_token.txt
echo

echo "Requested scopes: ${scope}"
echo "Scopes in access token:"
# cat refresh_token.txt | jwt decode --json - | jq -r .
# cat access_token.txt | jwt decode --json - | jq -r .
cat access_token.txt | jwt decode --json - | jq -r .payload.scp

# echo
# echo "curl https://auth.tesla.com/oauth2/v3/userinfo"
# curl -sS https://auth.tesla.com/oauth2/v3/userinfo \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer $(cat access_token.txt)"
# echo
echo
echo "Things that require user_data scope which isn't appearing in access token?!"
echo "curl ${AUDIENCE}/api/1/users/me"
curl "${AUDIENCE}/api/1/users/me" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat access_token.txt)"
exit
# echo "curl ${AUDIENCE}/api/1/vehicle_subscriptions"
# curl -sS "${AUDIENCE}/api/1/vehicle_subscriptions" \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer $(cat access_token.txt)" |
#   jq .

echo "curl ${AUDIENCE}/api/1/vehicles"
vehicles=$(curl -sS "${AUDIENCE}/api/1/vehicles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat access_token.txt)")
echo "$vehicles" | jq -r .

vehicle_id=$(echo "$vehicles" | jq -r '.response[0].id')

echo
echo "curl ${AUDIENCE}/api/1/vehicles/${vehicle_id}/vehicle_data?endpoints=location_data;drive_state;vehicle_state;charge_state"
curl -sS "${AUDIENCE}/api/1/vehicles/${vehicle_id}/vehicle_data?endpoints=location_data" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat access_token.txt)" |
  jq .
curl -sS "${AUDIENCE}/api/1/vehicles/${vehicle_id}/vehicle_data?endpoints=charge_state" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat access_token.txt)" |
  jq .
curl -sS "${AUDIENCE}/api/1/vehicles/${vehicle_id}/vehicle_data?endpoints=vehicle_state" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat access_token.txt)" |
  jq .
echo
echo
echo "Now let's try waking up a car"
echo "curl -X POST ${AUDIENCE}/api/1/vehicles/${vehicle_id}/wake_up"
curl -X POST "${AUDIENCE}/api/1/vehicles/${vehicle_id}/wake_up" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat access_token.txt)" |
  jq .
