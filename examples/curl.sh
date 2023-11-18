#!/bin/bash

set -eo pipefail

# Flow discussed in
# https://shankar-k.medium.com/tesla-developer-api-guide-account-setup-app-creation-registration-and-third-party-da24aba1bddd

: ${TESLA_CLIENT_ID:?required}
: ${TESLA_CLIENT_SECRET:?required}
AUDIENCE=${AUDIENCE:-https://fleet-api.prd.na.vn.cloud.tesla.com}
: ${PUBLIC_TUNNEL_HOST:?required}

# if not jwt cli installed show error:
if ! command -v jwt >/dev/null; then
  echo "'jwt' cli not installed, install with:"
  echo "brew install jwt-cli"
fi

# Generates a token to be used for managing a partner's account or devices they own.
# https://developer.tesla.com/docs/fleet-api#generating-a-partner-authentication-token
# BUT - the partner auth token isn't supported by the API
# https://github.com/teslamotors/vehicle-command/issues/17
auth_response=$(
  curl -sS --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=${TESLA_CLIENT_ID}" \
    --data-urlencode "client_secret=${TESLA_CLIENT_SECRET}" \
    --data-urlencode "scope=openid vehicle_device_data vehicle_cmds vehicle_charging_cmds" \
    --data-urlencode "audience=$AUDIENCE" \
    "https://auth.tesla.com/oauth2/v3/token"
)

echo $auth_response
partner_auth_token=$(echo "$auth_response" | jq -r .access_token)
echo "Access token is JWT that looks like:"
echo "$partner_auth_token" | jwt decode -

# openssl ecparam -name prime256v1 -genkey -noout -out private.pem
# openssl ec -in private.pem -pubout -out com.tesla.3p.public-key.pem

set -x
curl --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $partner_auth_token" \
  --data "$(jq --null-input --arg host "$PUBLIC_TUNNEL_HOST" '{"domain": $host}')" \
  "${AUDIENCE}/api/1/partner_accounts"
echo

curl --header "Content-Type: application/json" \
  --header "Authorization: Bearer $partner_auth_token" \
  "${AUDIENCE}/api/1/partner_accounts/public_key?domain=$PUBLIC_TUNNEL_HOST"
set +x
echo

echo "Visit this URL:"
echo "https://auth.tesla.com/oauth2/v3/authorize?client_id=${TESLA_CLIENT_ID}&locale=en-US&prompt=login&redirect_uri=https%3A%2F%2Frails-9292.drnicwilliams.com%2Fauth%2Ftesla%2Fcallback&response_type=code&scope=openid%20vehicle_device_data%20vehicle_cmds%20vehicle_charging_cmds&state=a4c509360a2cd8349bce6bf3a389f017292e24ee4d62c2e9"
echo
echo "When the auth sequence is finished and it fails to redirect to the callback URL"
echo "since the app is not running, copy the code=XYZ from the URL and paste it here:"
read code

# curl --header "Content-Type: application/json" \
#   --header "Authorization: Bearer $partner_auth_token" \
#   "${AUDIENCE}/api/1/users/me"
# echo

token_response=$(
  curl -sS 'https://auth.tesla.com/oauth2/v3/token' \
    -H 'Content-Type: application/json' \
    -d "$(jq -n \
      --arg client_id "$TESLA_CLIENT_ID" \
      --arg client_secret "$TESLA_CLIENT_SECRET" \
      --arg code "${code:?required}" \
      '{
            grant_type: "authorization_code",
            client_id: $client_id,
            client_secret: $client_secret,
            code: $code,
            audience: "https://fleet-api.prd.na.vn.cloud.tesla.com",
            redirect_uri: "https://rails-9292.drnicwilliams.com/auth/tesla/callback"
          }')"
)

access_token=$(echo "$token_response" | jq -r .access_token)
id_token=$(echo "$token_response" | jq -r .id_token)
token_type=$(echo "$token_response" | jq -r .token_type)

echo "access_token:"
echo $access_token | jwt decode -
