#!/usr/bin/env bats

# load custom assertions and functions
load bats_helper


# setup is run beofre each test
function setup {
  export RESULT_DIR="${BATS_TMPDIR}/jira-tests"
  mkdir -p $RESULT_DIR
  INPUT_PROJECT_CONFIG=${RESULT_DIR}/input_config-${BATS_TEST_NUMBER}
  PROCESSED_PROJECT_CONFIG=${RESULT_DIR}/packed_config-${BATS_TEST_NUMBER} 
  JSON_PROJECT_CONFIG=${RESULT_DIR}/json_config-${BATS_TEST_NUMBER} 
	echo "#using temp file ${RESULT_DIR}/"

  # the name used in example config files.
  INLINE_ORB_NAME="jira"

  export JIRA_ISSUE_REGEX="[A-Z]{2,30}-[0-9]+"
  export JIRA_ENVIRONMENT_TYPE="development"
  export JIRA_STATE_PATH="${RESULT_DIR}/jira.status"
  export JIRA_SCAN_BODY="false"
  export CIRCLECI_TOKEN="${CIRCLE_TOKEN}"
  export ORB_TEST_ENV="bats-core"

  cp tests/mocks/me.json /tmp/me.json
}

@test "1: Execution of Notify Script Works with env vars" {
  cp tests/mocks/pipeline.json /tmp/pipeline_info.json
  cp tests/mocks/workflow.json /tmp/workflow.json
  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="lint"
  export JIRA_ENVIRONMENT="${CIRCLE_JOB}"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/23"
  export CIRCLE_BRANCH="master"
  export JIRA_JOB_TYPE="build"

  echo 'export JIRA_BUILD_STATUS="successful"' >> ${RESULT_DIR}/jira.status

  run bash src/scripts/notify.sh
  echo $output > ${RESULT_DIR}/script-${BATS_TEST_NUMBER}-builds.out

  # then is passes
  [[ "$status" == "0" ]]

  # and reports success
  assert_jq_match '.acceptedBuilds | length' 1 ${BATS_TMPDIR}/curl_response.txt # acc Deployments has one object
}

@test "2: Workflow Status of Fail will override passing job" {
  cp tests/mocks/pipeline.json /tmp/pipeline_info.json
  cp tests/mocks/workflow_fail.json /tmp/workflow.json

  export CIRCLE_WORKFLOW_ID="5ddcc736-89ec-477b-bbd6-ec4cbbf5f211"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="passing"
  export JIRA_ENVIRONMENT="${CIRCLE_JOB}"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/355"
  export CIRCLE_BRANCH="master"
  export JIRA_JOB_TYPE="build"

  echo 'export JIRA_BUILD_STATUS="successful"' >> ${RESULT_DIR}/jira.status

  run bash src/scripts/notify.sh
  
  [[ "$status" == "0" ]]

  assert_jq_match '.builds | length' 1 ${BATS_TMPDIR}/jira-status.json
  assert_jq_match '.builds[0].state' "failed" ${BATS_TMPDIR}/jira-status.json
  assert_jq_match '.acceptedBuilds | length' 1 ${BATS_TMPDIR}/curl_response.txt 
  assert_jq_match '.rejectedBuilds | length' 0 ${BATS_TMPDIR}/curl_response.txt 
  assert_contains_text "workflow is failed"
}

@test "3: Execution of Notify Script Works for Deployments" {
  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="lint"
  export JIRA_ENVIRONMENT="${CIRCLE_JOB}"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/23"
  export CIRCLE_BRANCH="master"
  export JIRA_JOB_TYPE="deploy"

  echo 'export JIRA_BUILD_STATUS="successful"' >> ${RESULT_DIR}/jira.status

  run bash src/scripts/notify.sh
  cp ${BATS_TMPDIR}/curl_response.txt ${RESULT_DIR}/curl_3_response.txt

  # then is passes
  [[ "$status" == "0" ]]

  # and reports success
  assert_jq_match '.acceptedDeployments | length' 1 ${BATS_TMPDIR}/curl_response.txt # acc Deployments has one object
  assert_jq_match '.rejectedDeployments | length' 0 ${BATS_TMPDIR}/curl_response.txt   #rejecte does not
  cp ${BATS_TMPDIR}/curl_response.txt ${RESULT_DIR}/curl_3_response.txt
}


@test "4: Spec Test - Confirm ids and numbers and sequences per Jira api" {
 
  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="passing"
  export JIRA_ENVIRONMENT="${CIRCLE_JOB}"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/355"
  export CIRCLE_BRANCH="master"
  export JIRA_JOB_TYPE="build"

  echo 'export JIRA_BUILD_STATUS="successful"' >> ${RESULT_DIR}/jira.status

  run bash src/scripts/notify.sh
  echo $output > ${RESULT_DIR}/script-${BATS_TEST_NUMBER}-builds.out
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success 
  assert_jq_match '.builds | length' 1 ${BATS_TMPDIR}/jira-status.json
  assert_jq_match '.builds[0].buildNumber' 313 ${BATS_TMPDIR}/jira-status.json
  assert_jq_match '.builds[0].pipelineId' "${CIRCLE_PROJECT_REPONAME}" ${BATS_TMPDIR}/jira-status.json

  #
  # now deployment
  #
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="passing"
  export JIRA_ENVIRONMENT="${CIRCLE_JOB}"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/355"
  export CIRCLE_BRANCH="master"
  export JIRA_JOB_TYPE="deploy"

  echo 'export JIRA_BUILD_STATUS="successful"' >> ${RESULT_DIR}/jira.status
 
  run bash src/scripts/notify.sh
  echo $output > ${RESULT_DIR}/script-${BATS_TEST_NUMBER}-deploy.out
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success 
  assert_jq_match '.deployments | length' 1 ${BATS_TMPDIR}/jira-status.json
  assert_jq_match '.deployments[0].deploymentSequenceNumber' 313 ${BATS_TMPDIR}/jira-status.json
  assert_jq_match '.deployments[0].pipeline.id' "${CIRCLE_PROJECT_REPONAME}" ${BATS_TMPDIR}/jira-status.json
}

@test "5: Execution of Notify Script Works for Deployments with Service ID" {
  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="lint"
  export JIRA_ENVIRONMENT="${CIRCLE_JOB}"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/23"
  export CIRCLE_BRANCH="master"
  export JIRA_JOB_TYPE="deploy"

  echo 'export JIRA_BUILD_STATUS="successful"' >> ${RESULT_DIR}/jira.status

  run bash src/scripts/notify.sh
  echo $output > ${RESULT_DIR}/script-${BATS_TEST_NUMBER}-deploy.out
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success
  assert_jq_match '.acceptedDeployments | length' 1 ${BATS_TMPDIR}/curl_response.txt # acc Deployments has one object
  assert_jq_match '.rejectedDeployments | length' 0 ${BATS_TMPDIR}/curl_response.txt   #rejecte does not
  assert_jq_match '.unknownAssociations | length' 0 ${BATS_TMPDIR}/curl_response.txt

}

@test "6: Execution of Notify Script Works for Deployments with INVALID Service ID" {
  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="lint"
  export JIRA_ENVIRONMENT="${CIRCLE_JOB}"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/23"
  export CIRCLE_BRANCH="master"
  export JIRA_JOB_TYPE="deploy"

  echo 'export JIRA_BUILD_STATUS="successful"' >> ${RESULT_DIR}/jira.status

  run bash src/scripts/notify.sh
  echo $output > ${RESULT_DIR}/script-${BATS_TEST_NUMBER}-deploy.out
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success
  assert_jq_match '.acceptedDeployments | length' 1 ${BATS_TMPDIR}/curl_response.txt # acc Deployments has one object
  assert_jq_match '.rejectedDeployments | length' 0 ${BATS_TMPDIR}/curl_response.txt   #rejecte does not
  assert_jq_match '.unknownAssociations | length' 1 ${BATS_TMPDIR}/curl_response.txt

}