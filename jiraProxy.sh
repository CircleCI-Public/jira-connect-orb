#!/usr/bin/env bash

# ./jiraProxy.sh build|deployment <file>

curl \
-w "%{http_code}" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-X POST "https://circleci.com/api/v1.1/project/gh/CircleCI-Public/jira-connect-orb/jira/${1}?circle-token=${CIRCLE_TOKEN}" --data @$2



