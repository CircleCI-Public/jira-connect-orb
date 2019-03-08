# JIRA Connect orb

Updates the status of JIRA tickets as related commits building in CircleCI pass/fail.


## Example

`git commit -m"Working on CIRCLE-1223"`



## Needs

- The `sharedSecret` created during initial Atlassian Connect Install
- baseURL for their cloud instance (also provided to app during install)
- atlassian-connect.json updates (include [build module](https://developer.atlassian.com/cloud/jira/software/modules/build/))



