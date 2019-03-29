# JIRA Connect orb

Updates the status of JIRA tickets as related commits building in CircleCI pass/fail.


## Setup
This Orb uses the existing Atlassian Jira token that can be configured for CircleCI Projects.


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





