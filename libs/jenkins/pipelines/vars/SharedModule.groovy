#!groovy
/* groovylint-disable CompileStatic, GStringExpressionWithinString, LineLength, NestedBlockDepth, UnusedImport */

//- Library Imports

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
    String githubPAT            = 'GH_PAT'
    String gitlabApiPat         = 'gitlab-kazan-technical-api-token'
    String gitlabConnectionName = 'gitlab.kazan.myworldline.com'
    String gitlabGitSa          = 'cicd-technical-user'
    String gitTargetBranch      = 'main'
    String workerNode           = 'bambora-aws-slave-terraform'

    pipeline {
        agent {
            node workerNode
        }
        environment {
            GITLAB_CREDENTIALSID = credentials("${gitlabApiPat}")
            GITHUB_TOKEN = credentials("${githubPAT}")
        }
        options {
            // https://plugins.jenkins.io/ansicolor/
            ansiColor('xterm')
            // https://stackoverflow.com/questions/39542485/how-to-write-pipeline-to-discard-old-builds
            buildDiscarder(
                logRotator(
                    artifactNumToKeepStr: '7',
                    numToKeepStr: '7',
                )
            )
            disableConcurrentBuilds()
            gitLabConnection(gitlabConnectionName)
            skipStagesAfterUnstable()
            // https://stackoverflow.com/questions/38096004/how-to-add-a-timeout-step-to-jenkins-pipeline
            timeout(time: jobTimeout, unit: 'MINUTES')
            timestamps()
        }
        // https://www.jenkins.io/doc/book/pipeline/syntax/#parameters
        parameters {
            string(
                defaultValue: 'main',
                name: 'TOOLCHAIN_BRANCH'
            )
        }
        // source https://stackoverflow.com/questions/36651432/how-to-implement-post-build-stage-using-jenkins-pipeline-plug-in
        // source https://plugins.jenkins.io/gitlab-plugin/
        post {
            // TODO save scan reports as archive for X amount of time
            always {
                // https://plugins.jenkins.io/ws-cleanup/
                cleanWs(
                    cleanWhenAborted: true,
                    cleanWhenNotBuilt: true,
                    cleanWhenSuccess: true,
                    deleteDirs: true,
                    patterns: [
                        [pattern: '/**/.tmp/*', type: 'EXCLUDE'] // keep the artifacts
                    ]
                )
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
                    if (env.gitlabBranch == gitTargetBranch) {
                        // if main, send to nl-pros-equad-releases
                        slack.slackNotification(
                            slackChannel,
                            slackMsgSourceAcct,
                            env.JOB_NAME + 'Build FAILED.\n${env.BUILD_URL}console',
                            ':tada:'
                        )
                    }
                }
                // https://www.jenkins.io/doc/pipeline/steps/gitlab-plugin/
                /* groovylint-disable-next-line DuplicateMapLiteral, DuplicateStringLiteral */
                updateGitlabCommitStatus name: 'build', state: 'failed'
            }
            fixed {
                script {
                    if (env.gitlabBranch == gitTargetBranch) {
                        // if main, send to nl-pros-equad-releases
                        slack.slackNotification(
                            slackChannel,
                            slackMsgSourceAcct,
                            env.JOB_NAME + 'Build FIXED.\n${env.BUILD_URL}console',
                            ':tada:'
                            
                        )
                    }
                }
                /* groovylint-disable-next-line DuplicateMapLiteral, DuplicateStringLiteral */
                updateGitlabCommitStatus name: 'build', state: 'success'
            }
            success {
                /* groovylint-disable-next-line DuplicateStringLiteral */
                updateGitlabCommitStatus name: 'build', state: 'success'
            }
            unstable {
                /* groovylint-disable-next-line DuplicateMapLiteral, DuplicateStringLiteral */
                updateGitlabCommitStatus name: 'build', state: 'failed'
            }
        }
        stages {
            stage('Notification') {
                steps {
                    script {
                        withCredentials([string(
                            credentialsId:  gitlabApiPat,
                            variable:       'gitlabPAT'
                        )]) {
                        sh('''#!/bin/bash -l
                            set -eo pipefail

                            if [[ $LOG_LEVEL == "TRACE" ]]
                            then 
                                set -x
                            fi

                            source "$HOME/.bashrc"

                            curl \
                                --form "note=# Build Pipeline\n\nNumber: ${BUILD_NUMBER}\n\nUrl: ${BUILD_URL}console" \
                                --header "PRIVATE-TOKEN: $GITLAB_CREDENTIALSID" \
                                --request POST \
                                "https://${GITLAB_HOST}/api/v4/projects/''' + gitlabProjectId + '''/repository/commits/${GIT_COMMIT}/comments"
                        ''')
                        }
                    }
                }
            }
            stage('System ENV VARs') {
                steps {
                    sh('''#!/bin/bash -l
                        set -eo pipefail

                        if [[ $LOG_LEVEL == "TRACE" ]]
                        then 
                            set -x
                        fi

                        source "$HOME/.bashrc"

                        echo "INFO: Printing ENV VARs"
                        printenv | sort
                    ''')
                }
            }
            stage('Git Checkout') {
                steps {
                    echo "Checkout main branch for compliance, sast, tagging operations"
                    git branch: 'main',
                        credentialsId: gitlabGitSa,
                        url: env.GIT_URL
                    echo "Checkout feature branch for pipeline execution"
                    git branch: env.BRANCH_NAME,
                        credentialsId: gitlabGitSa,
                        url: env.GIT_URL
                }
            }
            stage('Install Dependencies') {
                steps {
                        sh('''#!/bin/bash -l
                            set -eo pipefail

                            if [[ $LOG_LEVEL == "TRACE" ]]
                            then 
                                set -x
                            fi

                            source "$HOME/.bashrc"

                        ${WORKSPACE}/libs/bash/install.sh ''' + params.TOOLCHAIN_BRANCH + '''
                        source $HOME/.bashrc
                    ''')
                }
            }
            stage('Compliance & SAST') {
                steps {
                    script {
                        sh('''#!/bin/bash -l
                            set -eo pipefail

                            if [[ $LOG_LEVEL == "TRACE" ]]
                            then 
                                set -x
                            fi

                            source "$HOME/.bashrc"
                            
                            ${WORKSPACE}/.tmp/toolchain-management/libs/bash/common/iac_publish.sh

                            # urlencoding using CURL https://gist.github.com/jaytaylor/5a90c49e0976aadfe0726a847ce58736https://gist.github.com/jaytaylor/5a90c49e0976aadfe0726a847ce58736
                            # Send payload via GitLab API https://docs.gitlab.com/ee/api/commits.html#post-comment-to-commit
                            curl \
                                --form "note=# Compliance Scanning Results:\n- ${BUILD_URL}testReport/" \
                                --header "PRIVATE-TOKEN: $GITLAB_CREDENTIALSID" \
                                --request POST \
                                "https://${GITLAB_HOST}/api/v4/projects/''' + gitlabProjectId + '''/repository/commits/${GIT_COMMIT}/comments"
                        ''')
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
                            withCredentials([string(
                                credentialsId:  gitlabApiPat,
                                variable:       'gitlabPAT'
                            )]) {
                                sh('''#!/bin/bash -l
                                    set -eo pipefail

                                    if [[ $LOG_LEVEL == "TRACE" ]]
                                    then 
                                        set -x
                                    fi

                                    source "$HOME/.bashrc"
                                    
                                    ${WORKSPACE}/.tmp/toolchain-management/libs/bash/common/sem_ver_release_tagging.sh
                                ''')
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
