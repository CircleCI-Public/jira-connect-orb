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


@test "Basic expansion works" {
  # given
  process_config_with tests/cases/simple.yml

  # when
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["build"].steps | length' 5
  assert_jq_match '.jobs["build"].steps[0].run.command' 'echo "hello"'
  assert_jq_match '.jobs["build"].steps[4].run.name' 'Update status in Atlassian Jira'

}

@test "Basic expansion includes API token when set" {
  # given
  process_config_with tests/cases/simple_with_circle_token.yml

  # when
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["build"].steps | length' 5
  assert_jq_match '.jobs["build"].steps[0].run.command' 'echo "hello"'
  assert_jq_match '.jobs["build"].steps[4].run.name' 'Update status in Atlassian Jira'
  assert_jq_contains '.jobs["build"].steps[4].run.command' '${MY_CIRCLE_TOKEN}'
}




@test "Execution of Notify Script Works with env vars" {
  # given a test instance with valid secret
  export ATLASSIAN_CONNECT_SECRET="${ATLASSIAN_CONNECT_SECRET}"
  export JIRA_BASE_URL="https://eddiewebb.atlassian.net"

  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="64983647689364"
  export CIRCLE_BUILD_NUM="296"
  export CIRCLE_JOB="lint"
  export CIRCLE_PROJECT_USERNAME="eddiewebb"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="circleci-samples"
  export CIRCLE_REPOSITORY_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_COMPARE_URL="https://github.com/CircleCI-Public/jira-connect-orb"
  export CIRCLE_BUILD_URL="https://circleci.com/gh/project/build/23"
  export CIRCLE_BRANCH="master"
  echo 'export JIRA_BUILD_STATUS="successful"' >> /tmp/jira.status
  process_config_with tests/cases/simple.yml


  # when out command is called
  jq -r '.jobs["build"].steps[4].run.command' $JSON_PROJECT_CONFIG > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  
  # then is passes
  [[ "$status" == "0" ]]

  # and reports success
  assert_contains_text '"acceptedBuilds":[{'  # acc builds has one object
  assert_contains_text '"rejectedBuilds":[]'  #rejecte does not
}



@test "Workflow Status of Fail will override passing job" {
  # given a test instance with valid secret
  export ATLASSIAN_CONNECT_SECRET="${ATLASSIAN_CONNECT_SECRET}"
  export JIRA_BASE_URL="https://eddiewebb.atlassian.net"

  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="29ac9db7-35d5-4c31-b486-96d47c8b794f"
  export CIRCLE_BUILD_NUM="358"
  export CIRCLE_JOB="passing"
  export CIRCLE_PROJECT_USERNAME="eddiewebb"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="circleci-samples"
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
  assert_contains_text '"acceptedBuilds":[{'  # acc Deployments has one object
  assert_contains_text '"rejectedBuilds":[]'  #rejecte does not
  assert_contains_text "workflow is FAILED"
}


@test "Basic expansion for deployments" {
  # given
  process_config_with tests/cases/deployment.yml

  # when
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["build"].steps[0].run.command' 'echo "hello"'
  assert_jq_match '.jobs["build"].steps[4].run.name' 'Update status in Atlassian Jira'
  assert_jq_contains '.jobs["build"].steps[4].run.command' '-X POST "https://circleci.com/api/v1.1/project/${VCS_TYPE}/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/jira/deployment'
}


@test "Execution of Notify Script Works for Deployments" {
  # given a test instance with valid secret
  export ATLASSIAN_CONNECT_SECRET="${ATLASSIAN_CONNECT_SECRET}"
  export JIRA_BASE_URL="https://eddiewebb.atlassian.net"

  # and the infomprovied by a CCI container
  export CIRCLE_WORKFLOW_ID="64983647689364"
  export CIRCLE_BUILD_NUM="296"
  export CIRCLE_JOB="lint"
  export CIRCLE_PROJECT_USERNAME="eddiewebb"
  export CIRCLE_SHA1="aef3425"
  export CIRCLE_PROJECT_REPONAME="circleci-samples"
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
  assert_contains_text '"acceptedDeployments":[{'  # acc Deployments has one object
  assert_contains_text '"rejectedDeployments":[]'  #rejecte does not

}


