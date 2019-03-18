#!/usr/bin/env bash


base_url="https://eddiewebb.atlassian.net"
cannonical="/rest/${1}/0.1/bulk"

jwt_token=$(bash generateJWT.bash ${cannonical})
echo "Token: ${jwt_token}"
curl -H "Authorization: JWT ${jwt_token}" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-X POST "${base_url}${cannonical}" --data @$2



