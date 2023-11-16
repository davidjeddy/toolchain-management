#!groovy
//- Library Imports
@Library('jenkins-pipeline')
import com.ingenico.epayments.ci.common.PipelineCommon
import com.ingenico.epayments.ci.common.Slack

// String var config
String gitlabApiToken       = 'jenkins-user-gitlab-test-api-token'
String gitlabConnectionName = 'gitlab-test-igdcs'
String gitlabProjectId      = 3440
String gitlabProjectPath    = 'cicd/terraform/tools/toolchain-management/-/tree'

String gitSSHCreds          = 'jenkins-gitlab-test-igdcs'
String slackChannel         = 'nl-pros-centaurus-squad-releases'
String workerNode           = 'bambora-aws-slave-terraform'

// No need to edit below this line

pipeline {
    agent {
        node workerNode
    }
    environment {
        GITLAB_CREDENTIALSID = credentials('GL_PAT_TF_MODULE_MIRRORING')
    }
    options {
        gitLabConnection(gitlabConnectionName)
        timestamps ()
        // https://stackoverflow.com/questions/38096004/how-to-add-a-timeout-step-to-jenkins-pipeline
        timeout(time: 30, unit: 'MINUTES')
    }
    // source https://stackoverflow.com/questions/36651432/how-to-implement-post-build-stage-using-jenkins-pipeline-plug-in
    // source https://plugins.jenkins.io/gitlab-plugin/
    post {
        // always, changed, fixed, regression, aborted, failure, success, unstable, unsuccessful, and cleanup
        failure {
            script {
                if (env.gitlabBranch == 'main') {
                    // if main, send to nl-pros-equad-releases
                    def slack = new Slack(this.steps, this.env)
                    slack.slackNotification(
                        slackChannel,
                        env.JOB_NAME,
                        ":alert: ${env.BRANCH_NAME} branch pipeline failed.",
                        ':jenkins:'
                    )
                }
            }
            updateGitlabCommitStatus name: 'build', state: 'failed'
        }
        fixed {
            script {
                if (env.gitlabBranch == 'main') {
                    // if main, send to nl-pros-equad-releases
                    def slack = new Slack(this.steps, this.env)
                    slack.slackNotification(
                        slackChannel,
                        env.JOB_NAME,
                        ":green_check_mark: ${env.BRANCH_NAME} branch build fixed.",
                        ':jenkins:'
                    )
                }
            }
            updateGitlabCommitStatus name: 'build', state: 'failed'
        }
        success {
            updateGitlabCommitStatus name: 'build', state: 'success'
        }
        unstable {
            updateGitlabCommitStatus name: 'build', state: 'success'
        }
    }
    stages {
        stage('Print ENV VARs') {
            steps {
                sh '''
                    echo "INFO: Printing ENV VARs"
                    export BASHLOG_COLOURS=0
                    printenv | sort
                '''
            }
        }
        stage('Notification') {
            steps {
                withCredentials([string(
                    credentialsId:  gitlabApiToken,
                    variable:       'gitlabPat'
                )]) {
                    sh '''
                        echo "INFO: Build link posted to GitLab commit"
                        NOTE_BODY="# Pipeline build\n${BUILD_URL}console"
                        printf $NOTE_BODY
                        curl \
                            --form "note=${NOTE_BODY}" \
                            --header "PRIVATE-TOKEN: ''' +  env.gitlabPat + '''" \
                            --request POST \
                            "https://${GITLAB_HOST}/api/v4/projects/'''+gitlabProjectId+'''/repository/commits/${GIT_COMMIT}/comments"
                    '''
                }
            }
        }
        stage('Clean Workspace') {
            steps {
                echo "INFO: Clean workspace"
                cleanWs()
            }
        }
        stage('Git Checkout') {
            steps {
                echo "INFO: Checkout branch"
                git credentialsId: gitSSHCreds,
                    url: env.GIT_URL,
                    branch: env.BRANCH_NAME
            }
        }
        // This stage must be first to ensure system packages and language runtimes are availabe
        stage('Toolchain Mngr: install.sh --update only for System tools') {
            steps {
                // Jenkins worker nodes have [cracklib](https://github.com/cracklib/cracklib) system package installed.
                // It provides a `packer` in the PATH, ie name collision with Hashcorp Packer.
                // So, skip installing misc tools for now until a resolution is found
                sh './libs/bash/install.sh --skip_aws_tools true --skip_misc_tools true --skip_terraform_tools true --update true'
            }
        }
        // Then we install the AWS CLI and related tools
        stage('Toolchain Mngr: install.sh --update only for AWS tools') {
            steps {
                sh './libs/bash/install.sh --skip_misc_tools true --skip_terraform_tools true --skip_system_tools true --update true'
            }
        }
        // We do not install misc tools due to a name collision with the package `packer` on RHEL based machines
        // Finally TG and related tools
        stage('Toolchain Mngr: install.sh --update only for Terraform tools') {
            steps {
                sh './libs/bash/install.sh --skip_aws_tools true --skip_misc_tools true --skip_system_tools true --update true'
            }
        }
        // if on the main branch and CHANGELOG diff
        // extract version number and message from CHANGELOG
        // create tag with message, push to origin
        // push tag to commit in GL
        stage('Tagging') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        // credentials to git push via ssh
                        withCredentials([sshUserPrivateKey(
                            credentialsId: gitSSHCreds,
                            keyFileVariable: 'key'
                        )]) {
                            // https://stackoverflow.com/questions/44330148/run-bash-command-on-jenkins-pipeline
                            sh '''#!/bin/bash
                                declare CHANGELOG_PATH
                                declare LINES_FOR_CONTEXT
                                declare MSG
                                declare SEM_VER

                                git fetch --all
                                CHANGELOG_PATH=$(git diff origin/main --name-only | grep CHANGELOG)
                                if [[ "$CHANGELOG_PATH" == "" ]]
                                then
                                    printf "INFO: No change log found, skipping tag creation.\n"
                                    exit 0
                                fi

                                # get the messge from the CHANGELOG
                                # Remove the git line leading `+` character
                                # Remove the git status title line
                                # Double backslash escape for Jenkins
                                # https://stackoverflow.com/questions/59716090/how-to-remove-first-line-from-a-string
                                MSG=$(git diff origin/main --unified=0 "$CHANGELOG_PATH" | \
                                    grep -E "^\\+" | \
                                    sed 's/+//' | \
                                    sed 1d
                                )
                                # output git diff, include --unified=2 to ensure unchanged text (up to 2 lines) in the middle of a diff is included. Specifically this ensures ### Added || ### Fixed || ### Deleted are included in the output
                                # remove Git header
                                # remove header $LINES_FOR_CONTEXT count of lines
                                # remove tail $LINES_FOR_CONTEXT count of lines
                                # remove lines starting with `-` (git remove) character
                                # remove `+` from line if the first character (git add)
                                LINES_FOR_CONTEXT=2
                                MSG=$(git diff origin/main --unified="$LINES_FOR_CONTEXT" "$CHANGELOG_PATH" | \
                                    tail -n +$(("5"+"$LINES_FOR_CONTEXT")) | \
                                    tail -n +"$LINES_FOR_CONTEXT" | \
                                    head -n -"$LINES_FOR_CONTEXT" | \
                                    sed '/^-/d' | \
                                    sed 's/+//'
                                )

                                # grep extract SemVer from string
                                # https://stackoverflow.com/questions/16817646/extract-version-number-from-a-string
                                SEM_VER=$( echo "$MSG" | head -n 1 | grep -Po "([0-9]+([.][0-9]+)+)" )

                                printf "CHANGELOG_PATH: %s\n" "$CHANGELOG_PATH"
                                printf "LINES_FOR_CONTEXT: %s\n" "$LINES_FOR_CONTEXT"
                                printf "MSG: %s\n" "$MSG"
                                printf "SEM_VER: %s\n" "$SEM_VER"

                                if [[ ! "$SEM_VER" ]]
                                then
                                    printf "ERR: Valid SEM_VER not found. Is %s properly formatted?.\n" "$CHANGELOG_PATH"
                                    exit 1
                                fi

                                # https://stackoverflow.com/questions/4457009/special-character-in-git-possible
                                git tag \
                                    --annotate "$SEM_VER" \
                                    --cleanup="verbatim" \
                                    --message="$(printf "%s" "$MSG")"
                                git config --global push.default matching

                                git push origin "$SEM_VER" --force'''
                        }
                    }
                }
            }
        }
    }
    triggers {
        cron(env.BRANCH_NAME == 'main' ?  'H */3 * * 1-5' : '')
    }
}
