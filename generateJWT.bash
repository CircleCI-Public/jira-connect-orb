#!/usr/bin/env bash

#
# JWT Encoder Bash Script 
# Original from https://willhaley.com/blog/generate-jwt-with-bash/, modified for Atlassian Connect
#
app_key="circleci.jira.buildsbeta"
secret="${ATLASSIAN_CONNECT_SECRET}"

USAGE=$(cat <<-END
    returns a JWT token valid for POST ops to the Build Status Bulk Upload API

    $0 <cannonical_url>

    Example:
    TOKEN=\$(bash generateJWT.bash "/rest/builds/0.1/bulk")
END
)

if [ $# -ne 1 ]; then
	echo $USAGE >&2
	exit 1
fi
query_string="POST&${1}&"




# Static header fields.
header='{
	"typ": "JWT",
	"alg": "HS256"
}'

# Use jq to set the dynamic `qsh`, `iat` and `exp`
# fields on the header using the current time.
# For more on "qsh" see https://developer.atlassian.com/cloud/jira/platform/understanding-jwt/#a-name-qsh-a-creating-a-query-string-hash
qsh=$(printf %s "$query_string" | openssl sha -sha256 | cut -d" " -f2)
claims=$(
	echo "{}" | jq --arg time_str "$(date +%s)" --arg qsh "$qsh" --arg iss "$app_key" \
	'
	($time_str | tonumber) as $time_num
	| .iat=$time_num
	| .exp=($time_num + 1800)
	| .qsh=$qsh
	| .iss=$iss
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


echo -n "${jwt_token}"


