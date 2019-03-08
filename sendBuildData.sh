#!/usr/bin/env bash


secret="${CONNECT_SECRET}"


test_url="https://eddiewebb.atlassian.net/rest/builds/0.1/bulk"
# see https://developer.atlassian.com/cloud/jira/platform/understanding-jwt/#a-name-qsh-a-creating-a-query-string-hash
path='POST&/rest/builds/0.1/bulk&'
qsh=$(printf %s "$path" | openssl sha -sha256 | cut -d" " -f2)


# Static header fields.
header='{
  "typ": "JWT",
  "alg": "HS256"
}'


claims='{
  "iss": "my-add-on"
}'

# Use jq to set the dynamic `qsh`, `iat` and `exp`
# fields on the header using the current time.
claims=$(
  echo "${claims}" | jq --arg time_str "$(date +%s)" --arg qsh "$qsh" \
  '
  ($time_str | tonumber) as $time_num
  | .iat=$time_num
  | .exp=($time_num + 1800)
  | .qsh=$qsh
  '
)


base64_encode()
{
  declare input=${1:-$(</dev/stdin)}
  # Use `tr` to URL encode the output from base64.
  printf '%s' "${input}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'
}

json() {
  declare input=${1:-$(</dev/stdin)}
  printf '%s' "${input}" | jq -c .
}

hmacsha256_sign()
{
  declare input=${1:-$(</dev/stdin)}
  printf '%s' "${input}" | openssl dgst -binary -sha256 -hmac "${secret}"
}



header_base64=$(echo "${header}" | json | base64_encode)
claims_base64=$(echo "${claims}" | json | base64_encode)

signing_input=$(echo "${header_base64}.${claims_base64}")
signature=$(echo "${signing_input}" | hmacsha256_sign | base64_encode)
jwt_token="${signing_input}.${signature}"

#debug
echo $header | json
echo $claims | json
echo "Token: ${jwt_token}"

curl -H "Authorization: JWT ${jwt_token}" -H "Content-Type: application/json" -H "Accept: application/json" -X POST "${test_url}" --data @sample-66.json



