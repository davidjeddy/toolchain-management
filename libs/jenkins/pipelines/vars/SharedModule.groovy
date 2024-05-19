#!groovy

// https://stackoverflow.com/questions/61106044/condition-in-jenkins-pipeline-on-the-triggers-directive
def runCron(cronSchedule) {
    if( env.BRANCH_NAME == 'main' ) {
        return cronSchedule
    }

    return ''
}

def call(
    String gitlabProjectName,
    Number gitlabProjectId,
    String cronSchedule,
    Number jobTimeout,
    Object slack,
    String slackChannel
) {
    // Static pipeline configuration
    String githubPAT            = "GH_PAT"
    String gitlabApiToken       = "jenkins-user-gitlab-test-api-token"
    String gitlabConnectionName = "gitlab-test-igdcs"
    String gitlabHost           = "gitlab.test.igdcs.com"
    String gitlabPAT            = "GL_PAT_TF_MODULE_MIRRORING"
    String gitSSHCreds          = "jenkins-gitlab-test-igdcs"
    String tfModuleHost         = "gitlab_test_igdcs_com"
    String workerNode           = "bambora-aws-slave-terraform"

    pipeline {
        agent {
            node workerNode
        }
        environment {
            GITLAB_CREDENTIALSID = credentials("${gitlabPAT}")
            GITHUB_TOKEN = credentials("${githubPAT}")
        }
        options {
            ansiColor('xterm') // https://plugins.jenkins.io/ansicolor/
            gitLabConnection(gitlabConnectionName)
            skipStagesAfterUnstable()
            timeout(time: jobTimeout, unit: 'MINUTES') // https://stackoverflow.com/questions/38096004/how-to-add-a-timeout-step-to-jenkins-pipeline
            timestamps()
        }
        // https://www.jenkins.io/doc/book/pipeline/syntax/#parameters
        parameters {
            string(name: 'TOOLCHAIN_BRANCH', defaultValue: 'main')
        }
        // source https://stackoverflow.com/questions/36651432/how-to-implement-post-build-stage-using-jenkins-pipeline-plug-in
        // source https://plugins.jenkins.io/gitlab-plugin/
        post {
            // TODO save scan reports as archive for X amount of time
            always {
                // do not archive toolchain-management
                // archiveArtifacts artifacts: "./.tmp/junit-*.xml", excludes: "./.tmp/toolchain-management/**", fingerprint: true
                junit allowEmptyResults: true, testResults: "./.tmp/junit-*.xml"
                // publishHTML([
                //     allowMissing: true,
                //     alwaysLinkToLastBuild: true,
                //     keepAll: true,
                //     reportDir: './.tmp/',
                //     reportFiles: 'index.html',
                //     reportName: 'Compliance & SAST Report'
                // ])
            }
            // TODO: send to commit author via email. use commit email to get slack username to send msg. this req. a feature add to the Groovy Slack class as it does not currently support this feature
            // always, changed, fixed, regression, aborted, failure, success, unstable, unsuccessful, and cleanup
            failure {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        slack.slackNotification(
                            slackChannel,
                            env.JOB_NAME,
                            ":alert: Build failed.\n Build URL: ${env.BUILD_URL}console",
                            ':jenkins:'
                        )
                    }
                }
                updateGitlabCommitStatus name: 'build', state: 'failed'
            }
            fixed {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        slack.slackNotification(
                            slackChannel,
                            env.JOB_NAME,
                            ":tada: Build fixed.",
                            ':jenkins:'
                        )
                    }
                }
                updateGitlabCommitStatus name: 'build', state: 'success'
            }
            success{
                updateGitlabCommitStatus name: 'build', state: 'success'
            }
            unstable {
                updateGitlabCommitStatus name: 'build', state: 'success'
            }
        }
        stages {
            stage('Notification') {
                steps {
                    script {
                        sh '''#!/usr/bin/env bash
                            set -e
                            curl \
                                --form "note=# Build Pipeline\n\nNumber: ${BUILD_NUMBER}\n\nUrl: ${BUILD_URL}console" \
                                --header "PRIVATE-TOKEN: $GITLAB_CREDENTIALSID" \
                                --request POST \
                                "https://${GITLAB_HOST}/api/v4/projects/''' + gitlabProjectId + '''/repository/commits/${GIT_COMMIT}/comments"
                        '''
                    }
                }
            }
            stage('Clean Workspace') {
                steps {
                    cleanWs()
                }
            }
            stage('Print ENV VARs') {
                steps {
                    script {
                        sh '''#!/usr/bin/env bash
                            set -e
                            echo "INFO: Printing ENV VARs"
                            # We do not want the default AWS credentials from Jenkins
                            unset JENKINS_AWS_CREDENTIALSID
                            # Prevent colors in BASH for tfenv and tgenv
                            # https://github.com/tfutils/tfenv#bashlog_colours
                            export BASHLOG_COLOURS=0
                            printenv | sort
                        '''
                    }
                }
            }
            stage('Git Checkout') {
                steps {
                    echo "Checkout main branch"
                    // Needed for compliance, sast, tagging
                    git credentialsId: gitSSHCreds,
                        url: env.GIT_URL,
                        branch: "main"
                    echo "Checkout feature branch"
                    git credentialsId: gitSSHCreds,
                        url: env.GIT_URL,
                        branch: env.BRANCH_NAME
                }
            }
            stage('Install Dependencies') {
                steps {
                    script {
                        sh '''#!/usr/bin/env bash
                            set -e
                            ${WORKSPACE}/libs/bash/install.sh ''' + params.TOOLCHAIN_BRANCH + '''
                        '''
                    }
                }
            }
            stage('Compliance & SAST') {
                steps {
                    script {
                        sh '''#!/usr/bin/env bash
                            set -e
                            ${WORKSPACE}/.tmp/toolchain-management/libs/bash/common/iac_publish.sh

                            # urlencoding using CURL https://gist.github.com/jaytaylor/5a90c49e0976aadfe0726a847ce58736https://gist.github.com/jaytaylor/5a90c49e0976aadfe0726a847ce58736
                            # Send payload via GitLab API https://docs.gitlab.com/ee/api/commits.html#post-comment-to-commit
                            curl \
                                --form "note=# Compliance Scanning Results:\n- ${BUILD_URL}testReport/" \
                                --header "PRIVATE-TOKEN: $GITLAB_CREDENTIALSID" \
                                --request POST \
                                "https://${GITLAB_HOST}/api/v4/projects/''' + gitlabProjectId + '''/repository/commits/${GIT_COMMIT}/comments"
                        '''
                    }

                    archive includes: '${WORKSPACE}/.tmp/junit*.xml'
                }
            }
            // if on the main branch and docs/CHANGELOG.md diff
            // extract version number and message from docs/CHANGELOG.md
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
                                sh '''#!/usr/bin/env bash
                                    set -e
                                    ${WORKSPACE}/.tmp/toolchain-management/libs/bash/common/sem_ver_release_tagging.sh
                                '''
                            }
                        }
                    }
                }
            }
            // if on main branch
            // create an shared module archive
            // push shared module archive to GL
            stage('Publish') {
                steps {
                    script {
                        if (env.BRANCH_NAME == 'main') {
                            withCredentials([string(
                                credentialsId:  gitlabApiToken,
                                variable:       'gitlabPAT'
                            )]) {
                                sh '''
                                    ${WORKSPACE}/.tmp/toolchain-management/libs/bash/common/publish_iac_module_version.sh \
                                    ''' + gitlabHost + ''' \
                                    ''' + gitlabProjectId + ''' \
                                    ''' + gitlabProjectName + '''
                                '''
                            }
                        }
                    }
                }
            }
        }
        triggers {
            cron( runCron(cronSchedule) )
        }
    }
}
