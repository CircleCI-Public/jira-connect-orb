#!/usr/bin/env bash

# ./jiraProxy.sh build|deployment <file>

curl \
-w "%{http_code}" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-X POST "https://circleci.com/api/v1.1/project/github/eddiewebb/circleci-samples/jira/${1}?circle-token=${CIRCLECI_API_TOKEN}" --data @$2



