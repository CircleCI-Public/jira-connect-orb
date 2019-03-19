#!/bin/bash

CIRCLE_WORKFLOW_ID=$1


curl -s https://circleci.com/graphql-unstable \
-H "Authorization: ${CIRCLECI_API_TOKEN}" \
-X POST \
-H 'Content-Type: application/json' \
-d '{"query":"{\n\tworkflow(id:\"'${CIRCLE_WORKFLOW_ID}'\"){\n    status\n  }\n}","variables":null}' | jq -r '.data.workflow.status'