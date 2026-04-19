# RUNBOOK

## Operations

### Updating language, tool, runtime, etc versions

As much as possible we want to use `asdf-vm`, if a resource is not available via `asdf-vm` then we go to `dnf`, if a resource is not available via `dnf` then, and only then, should we write custom logic to `curl` download a compiled binary. We should avoid compiling from source as much as possible due to differences in host configurations.

Additionally, when updating packages, entire the package version is available for the target host type. IE Golang much publish a new version but is it available via `dnf` for the host OS release? There is often lag time between vendor publication and package manager adoption.

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

`curl: (35) Recv failure: Connection reset by peer`

**When**

Executing curl from cicd-build-* account targeting a remote host outside the VPC

**Fix**

Add the remote host DNS to the Bambora egress firewall allow list via the [tf-account-firewall](https://github.com/bambora/tf-account-firewall) project in Bambora Github.

-----

**Error**

```
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import curses
  File "/home/jenkins/.asdf/installs/python/3.13.6/lib/python3.13/curses/__init__.py", line 13, in <module>
    from _curses import *
ModuleNotFoundError: No module named '_curses'
WARNING: The Python curses extension was not compiled. Missing the ncurses lib?
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import readline
ModuleNotFoundError: No module named 'readline'
WARNING: The Python readline extension was not compiled. Missing the GNU readline lib?
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import ssl
  File "/home/jenkins/.asdf/installs/python/3.13.6/lib/python3.13/ssl.py", line 100, in <module>
    import _ssl             # if we can't import it, let the error propagate
    ^^^^^^^^^^^
ModuleNotFoundError: No module named '_ssl'
ERROR: The Python ssl extension was not compiled. Missing the OpenSSL lib?

Please consult to the Wiki page to fix the problem.
https://github.com/pyenv/pyenv/wiki/Common-build-problems
```

**When**

./libs/bash/install.sh

**Fix**

```
dnf install -y ncurses readline-devel sqlite3 sqlite-devel
```

Then re-run installer.
