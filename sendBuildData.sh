#!/usr/bin/env bash


test_url="https://eddiewebb.atlassian.net/rest/builds/0.1/bulk"
path='POST&/rest/builds/0.1/bulk&'
jwt_token=$(bash generateJWT.bash $test_url $path)
echo "Token: ${jwt_token}"

curl -H "Authorization: JWT ${jwt_token}" -H "Content-Type: application/json" -H "Accept: application/json" -X POST "${test_url}" --data @sample-66.json



