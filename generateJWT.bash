#!/usr/bin/env bash


# Question
# How to get base URL
# Confirm "token" is actually "secret"
# Confirm scope of CircleCI JIRA app
# App Key (is is cireclic.jira, or something else)
# Does "Write" scope include read?
# need to add module to atlassian-connect.json - https://developer.atlassian.com/cloud/jira/software/modules/build/




#
# JWT Encoder Bash Script - https://willhaley.com/blog/generate-jwt-with-bash/
#

secret=$CONNECT_SECRET

test_url="https://eddiewebb.atlassian.net/rest/api/2/project"
# see https://developer.atlassian.com/cloud/jira/platform/understanding-jwt/#a-name-qsh-a-creating-a-query-string-hash
path='GET&/rest/api/2/project&'
qsh=$(printf %s "$path" | openssl sha -sha256 | cut -d" " -f2)


# Static header fields.
header='{
	"typ": "JWT",
	"alg": "HS256"
}'


claim='{
	"iss": "circleci.jira"
}'

# Use jq to set the dynamic `qsh`, `iat` and `exp`
# fields on the header using the current time.
# `iat` is set to now, and `exp` is now + 1 second.
claims=$(
	echo "${claim}" | jq --arg time_str "$(date +%s)" --arg qsh "$qsh" \
	'
	($time_str | tonumber) as $time_num
	| .iat=$time_num
	| .exp=($time_num + 100)
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


curl -H "Authorization: JWT ${jwt_token}" "${test_url}" 


