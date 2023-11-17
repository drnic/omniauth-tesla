#!/bin/bash

# Flow discussed in
# https://shankar-k.medium.com/tesla-developer-api-guide-account-setup-app-creation-registration-and-third-party-da24aba1bddd

: ${TESLA_CLIENT_ID:?required}
: ${TESLA_CLIENT_SECRET:?required}
AUDIENCE=${AUDIENCE:-https://fleet-api.prd.na.vn.cloud.tesla.com}

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

partner_auth_token=$(echo "$auth_response" | jq -r .access_token)
echo "Access token is JWT that looks like:"
echo "$partner_auth_token" | jwt decode -

# openssl ecparam -name prime256v1 -genkey -noout -out private.pem
# openssl ec -in private.pem -pubout -out com.tesla.3p.public-key.pem

curl --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $partner_auth_token" \
  --data '{"domain":"http://localhost:9292"}' \
  'https://fleet-api.prd.na.vn.cloud.tesla.com/api/1/partner_accounts'

# curl --header "Content-Type: application/json" \
#   --header "Authorization: Bearer $partner_auth_token" \
#   "${AUDIENCE}/api/1/users/me"
# echo
# curl --header "Content-Type: application/json" \
#   --header "Authorization: Bearer $partner_auth_token" \
#   "${AUDIENCE}/api/1/partner_accounts/public_key"
