# Jira Connect orb  [![CircleCI status](https://circleci.com/gh/CircleCI-Public/jira-connect-orb.svg "CircleCI status")](https://circleci.com/gh/CircleCI-Public/jira-connect-orb) [![CircleCI Orb Version](https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/circleci/jira)](https://circleci.com/orbs/registry/orb/circleci/jira) [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/CircleCI-Public/jira-connect-orb/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

Updates the status of Atlassian Jira tickets as related commits building in CircleCI pass/fail.

## Setup
This Orb uses the existing Atlassian Jira token that can be configured for CircleCI Projects and requires that [CircleCI for Jira](https://marketplace.atlassian.com/apps/1215946) be installed in the Jira instance.  Please see [CircleCI Jira integration docs](https://circleci.com/docs/2.0/jira-plugin/)

## Examples

### See Build Status on Issues
`git commit -m"Working on CC-21"`

![Jira developer panel with CircleCI build info](/assets/new_issue_view.png)

### See Build Status on Issues
Includes Deployments too!

![Jira developer panel with CircleCI build info](/assets/deployment_support.png)

### Search by build/deployment status
Includes Deployments too!

**Failing issues?**
`project = CC AND development['builds'].failing >0`

**Tickets ready for Prod?**
`project = CC AND deploymentEnvironmentType ~ test AND deploymentEnvironmentType !~ production`

![Jira developer panel with CircleCI build info](/assets/search_deploy_status.png)
