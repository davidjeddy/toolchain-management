# RUNBOOK

## Operations

## Errors, When, and Fixes

**Error**

Also:   org.jenkinsci.plugins.workflow.actions.ErrorAction$ErrorId: bd09a9fb-434a-4fb0-bd98-2bce7301e0a8
hudson.remoting.ProxyException: groovy.lang.MissingPropertyException: No such property: gitlabConnectionName for class: WorkflowScript

**When**

Executing pipeline

**Fix**

Ensure Jenkinsfile contains `gitlabConnectionName` variable and valid value.

-----

**Error**

[Pipeline] // script
[Pipeline] updateGitlabCommitStatus
 > git rev-parse HEAD^{commit} # timeout=10
[Pipeline] }
[Pipeline] // stage
[Pipeline] End of Pipeline
ERROR: null
Finished: FAILURE

**When**

Executing pipeline

**Fix**

Jenkinsfile `String gitlabProjectId` value does not match the ID in GitLab.

-----

**Error**

[Pipeline] End of Pipeline
ERROR: null
Finished: FAILURE

**When**

Pipeline is run

**Fix**

Check the usage of variables inside the pipeline.environment{} block. Specifically ensure the variable being used is indeed defined.

-----

**Error**

`INFO: This is taking longer than usual. You might need to provide the dependency resolver with stricter constraints to reduce runtime. See https://pip.pypa.io/warnings/backtracking for guidance. If you want to abort this run, press Ctrl + C.`

**When**

./libs/bash/install.sh

**Fix**

Just wait. Localstack requires a lot of packages and version constraints sorting.

-----

**Error**

`curl: (35) Recv failure: Connection reset by peer`

**When**

Executing curl from cicd-build-* account targeting a remote host outside the VPC

**Fix**

Add the remote host DNS to the Bambora egress firewall allow list via the [tf-account-firewall](https://github.com/bambora/tf-account-firewall) project in Bambora Github.

-----
