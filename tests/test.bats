#!/usr/bin/env bats

# load custom assertions and functions
load bats_helper


# setup is run beofre each test
function setup {
  INPUT_PROJECT_CONFIG=${BATS_TMPDIR}/input_config-${BATS_TEST_NUMBER}
  PROCESSED_PROJECT_CONFIG=${BATS_TMPDIR}/packed_config-${BATS_TEST_NUMBER} 
  JSON_PROJECT_CONFIG=${BATS_TMPDIR}/json_config-${BATS_TEST_NUMBER} 
	echo "#using temp file ${BATS_TMPDIR}/"

  # the name used in example config files.
  INLINE_ORB_NAME="jira"

}


@test "1: Basic expansion works" {
  # given
  process_config_with tests/cases/simple.yml

  # when
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["build"].steps | length' 5
  assert_jq_match '.jobs["build"].steps[0].run.command' 'echo "hello"'
  assert_jq_match '.jobs["build"].steps[4].run.name' 'Update status in Atlassian Jira'

}

@test "2: Basic expansion includes API token when set" {
  # given
  process_config_with tests/cases/simple_with_circle_token.yml

  # when
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["build"].steps | length' 5
  assert_jq_match '.jobs["build"].steps[0].run.command' 'echo "hello"'
  assert_jq_match '.jobs["build"].steps[4].run.name' 'Update status in Atlassian Jira'
  assert_jq_contains '.jobs["build"].steps[4].run.command' '${MY_CIRCLE_TOKEN}'
}


@test "3: Execution of Notify Script Works with env vars" {
  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="lint"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/23"
  export CIRCLE_BRANCH="master"
  echo 'export JIRA_BUILD_STATUS="successful"' >> /tmp/jira.status
  process_config_with tests/cases/simple.yml

  # when out command is called
  jq -r '.jobs["build"].steps[4].run.command' $JSON_PROJECT_CONFIG > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  echo $output > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}-builds.out

  # then is passes
  [[ "$status" == "0" ]]

  # and reports success
  cat /tmp/curl_response.txt
  assert_jq_match '.acceptedBuilds | length' 1 /tmp/curl_response.txt # acc Deployments has one object
}

@test "4: Workflow Status of Fail will override passing job" {

  # and the improvised by a CCI container
  export CIRCLE_WORKFLOW_ID="5ddcc736-89ec-477b-bbd6-ec4cbbf5f211"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="passing"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/355"
  export CIRCLE_BRANCH="master"
  echo 'export JIRA_BUILD_STATUS="successful"' >> /tmp/jira.status
  process_config_with tests/cases/simple.yml


  # when out command is called
  jq -r '.jobs["build"].steps[4].run.command' $JSON_PROJECT_CONFIG > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success 
  assert_jq_match '.builds | length' 1 /tmp/jira-status.json
  assert_jq_match '.builds[0].state' "failed" /tmp/jira-status.json
  assert_jq_match '.acceptedBuilds | length' 1 /tmp/curl_response.txt 
  assert_jq_match '.rejectedBuilds | length' 0 /tmp/curl_response.txt 
  assert_contains_text "workflow is failed"
}

@test "5: Basic expansion for deployments" {
  # given
  process_config_with tests/cases/deployment.yml

  # when
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["build"].steps[0].run.command' 'echo "hello"'
  assert_jq_match '.jobs["build"].steps[4].run.name' 'Update status in Atlassian Jira'
  assert_jq_contains '.jobs["build"].steps[4].run.command' '-X POST "https://circleci.com/api/v1.1/project/${VCS_TYPE}/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/jira/deployment'
}

@test "6: Execution of Notify Script Works for Deployments" {
  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="lint"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/23"
  export CIRCLE_BRANCH="master"
  echo 'export JIRA_BUILD_STATUS="successful"' >> /tmp/jira.status
  process_config_with tests/cases/deployment.yml


  # when out command is called
  jq -r '.jobs["build"].steps[4].run.command' $JSON_PROJECT_CONFIG > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success
  assert_jq_match '.acceptedDeployments | length' 1 /tmp/curl_response.txt # acc Deployments has one object
  assert_jq_match '.rejectedDeployments | length' 0 /tmp/curl_response.txt   #rejecte does not

}


@test "7: Spec Test - Confirm ids and numbers and sequences per Jira api" {
 
  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="passing"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/355"
  export CIRCLE_BRANCH="master"
  echo 'export JIRA_BUILD_STATUS="successful"' >> /tmp/jira.status
  process_config_with tests/cases/simple.yml


  # when out command is called
  jq -r '.jobs["build"].steps[4].run.command' $JSON_PROJECT_CONFIG > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}-builds.bash
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}-builds.bash
  echo $output > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}-builds.out
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success 
  assert_jq_match '.builds | length' 1 /tmp/jira-status.json
  assert_jq_match '.builds[0].buildNumber' 313 /tmp/jira-status.json
  assert_jq_match '.builds[0].pipelineId' "${CIRCLE_PROJECT_REPONAME}" /tmp/jira-status.json


  #
  # now deployment
  #
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="passing"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/355"
  export CIRCLE_BRANCH="master"
  echo 'export JIRA_BUILD_STATUS="successful"' >> /tmp/jira.status
  process_config_with tests/cases/deployment.yml

  # when out command is called
  jq -r '.jobs["build"].steps[4].run.command' $JSON_PROJECT_CONFIG > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}-deploy.bash
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}-deploy.bash
  echo $output > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}-deploy.out
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success 
  assert_jq_match '.deployments | length' 1 /tmp/jira-status.json
  assert_jq_match '.deployments[0].deploymentSequenceNumber' 313 /tmp/jira-status.json
  assert_jq_match '.deployments[0].pipeline.id' "${CIRCLE_PROJECT_REPONAME}" /tmp/jira-status.json
}

@test "8: Execution of Notify Script Works for Deployments with Service ID" {
  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="lint"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/23"
  export CIRCLE_BRANCH="master"
  echo 'export JIRA_BUILD_STATUS="successful"' >> /tmp/jira.status
  process_config_with tests/cases/deployment_with_service_id.yml


  # when out command is called
  jq -r '.jobs["build"].steps[4].run.command' $JSON_PROJECT_CONFIG > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  echo $output > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}-deploy.out
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success
  assert_jq_match '.acceptedDeployments | length' 1 /tmp/curl_response.txt # acc Deployments has one object
  assert_jq_match '.rejectedDeployments | length' 0 /tmp/curl_response.txt   #rejecte does not
  assert_jq_match '.unknownAssociations | length' 0 /tmp/curl_response.txt

}

@test "9: Execution of Notify Script Works for Deployments with INVALID Service ID" {
  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="ccfab95a-1ee6-4473-b4c0-d0992815d3af"
  export CIRCLE_BUILD_NUM="317"
  export CIRCLE_JOB="lint"
  export CIRCLE_PROJECT_USERNAME="circleci-public"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="jira-connect-orb"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/23"
  export CIRCLE_BRANCH="master"
  echo 'export JIRA_BUILD_STATUS="successful"' >> /tmp/jira.status
  process_config_with tests/cases/deployment_with_invalid_service_id.yml


  # when out command is called
  jq -r '.jobs["build"].steps[4].run.command' $JSON_PROJECT_CONFIG > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  echo $output > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}-deploy.out
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success
  assert_jq_match '.acceptedDeployments | length' 1 /tmp/curl_response.txt # acc Deployments has one object
  assert_jq_match '.rejectedDeployments | length' 0 /tmp/curl_response.txt   #rejecte does not
  assert_jq_match '.unknownAssociations | length' 1 /tmp/curl_response.txt

}