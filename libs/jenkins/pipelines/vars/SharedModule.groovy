#!groovy
/* groovylint-disable CompileStatic, DuplicateMapLiteral, DuplicateStringLiteral, GStringExpressionWithinString, LineLength, MethodReturnTypeRequired, MethodSize, NestedBlockDepth, NoDef, ParameterCount, UnusedImport */

//- Library Imports

// https://stackoverflow.com/questions/61106044/condition-in-jenkins-pipeline-on-the-triggers-directive
def runCron(String cronSchedule) {
    if ( env.BRANCH_NAME == 'main' ) {
        return cronSchedule
    }
    return ''
}

def call(
    Number gitlabProjectId,
    Number jobTimeout,
    String cronSchedule,
    String slackChannel
) {
    String artifactNumToKeepStr = '7'
    String githubPat            = 'GH_PAT'
    String gitlabApiPat         = 'gitlab-kazan-technical-api-token'
    String gitlabConnectionName = 'gitlab.kazan.myworldline.com'
    String gitlabGitSa          = 'cicd-technical-user'
    String gitTargetBranch      = 'main'
    String jenkinsNodeLabels    = 'aws && fedora && toolchain'
    String numToKeepStr         = '7'
    String shellPreamble        = 'set -eo pipefail; if [[ $LOG_LEVEL == "TRACE" ]]; then set -x; fi; if [[ -f "$HOME/.bashrc" ]]; then source "$HOME/.bashrc"; fi;'
    String slackWebhook         = 'SlackWebhook'

    pipeline {
        agent { // https://digitalvarys.com/jenkins-declarative-pipeline-with-examples/
            node {
                label jenkinsNodeLabels
            }
        }
        environment {
            GITHUB_TOKEN            = credentials("${githubPat}")
            GITLAB_CREDENTIALSID    = credentials("${gitlabApiPat}")
            SLACK_WEBHOOK           = credentials("${slackWebhook}")
        }
        options { // https://www.jenkins.io/doc/book/pipeline/syntax/#options
            ansiColor('xterm')
            buildDiscarder(logRotator(numToKeepStr: numToKeepStr, artifactNumToKeepStr: artifactNumToKeepStr))
            disableConcurrentBuilds()
            gitLabConnection(gitlabConnectionName)
            skipStagesAfterUnstable()
            timeout(time: jobTimeout, unit: 'MINUTES')
            timestamps()
        }
        parameters { // https://www.jenkins.io/doc/book/pipeline/syntax/#parameters
            string(name: 'TOOLCHAIN_BRANCH', defaultValue: 'main')
        }
        post { // always, changed, fixed, regression, aborted, failure, success, unstable, unsuccessful, and cleanup
            failure {
                script {
                    if (env.gitlabBranch == gitTargetBranch) {
                        sh(shellPreamble + '''
                            curl \
                                --data "channel=''' + slackChannel + '''" \
                                --data "emoji=:pipeline-failed: " \
                                --data "text=''' + env.JOB_NAME + ''' build FAILED.\n''' + env.BUILD_URL + '''console." \
                                --header "Authorization: Bearer ''' + env.SLACK_WEBHOOK + '''" \
                                --request POST "https://slack.com/api/chat.postMessage"
                        ''')
                    }
                }
                updateGitlabCommitStatus name: 'build', state: 'failed'
            }
            fixed {
                script {
                    if (env.gitlabBranch == gitTargetBranch) {
                        sh(shellPreamble + '''
                            curl \
                                --data "channel=''' + slackChannel + '''" \
                                --data "emoji=:tada: " \
                                --data "text=''' + env.JOB_NAME + ''' build FIXED.\n''' + env.BUILD_URL + '''console." \
                                --header "Authorization: Bearer ''' + env.SLACK_WEBHOOK + '''" \
                                --request POST "https://slack.com/api/chat.postMessage"
                        ''')
                    }
                }
                updateGitlabCommitStatus name: 'build', state: 'success'
            }
            success {
                updateGitlabCommitStatus name: 'build', state: 'success'
            }
            unstable {
                updateGitlabCommitStatus name: 'build', state: 'failed'
            }
        }
        stages {
            // Generic stages, used on most pipelines
            stage('Notification') {
                steps {
                    script {
                        withCredentials([string(
                            credentialsId:  gitlabApiPat,
                            variable:       'gitlabPAT'
                        )]) {
                            sh(shellPreamble + '''
                                curl \
                                    --form "note=# Build Pipeline\n\nNumber: ${BUILD_NUMBER}\n\nUrl: ${BUILD_URL}console" \
                                    --header "PRIVATE-TOKEN: ''' +  env.gitlabPAT + '''" \
                                    --request POST \
                                    "https://${GITLAB_HOST}/api/v4/projects/''' + gitlabProjectId + '''/repository/commits/${GIT_COMMIT}/comments"
                            ''')
                        }
                    }
                }
            }
            stage('Clean Workspace') {
                steps {
                    cleanWs()
                }
            }
            stage('ENV VARs') {
                steps {
                    sh(shellPreamble + '''
                        printenv | sort
                    ''')
                }
            }
            stage('Git Checkout') {
                steps {
                    echo 'Checkout main branch for compliance, sast, tagging operations'
                    git branch: 'main',
                        credentialsId: gitlabGitSa,
                        url: env.GIT_URL
                    echo 'Checkout feature branch for pipeline execution'
                    git branch: env.BRANCH_NAME,
                        credentialsId: gitlabGitSa,
                        url: env.GIT_URL
                }
            }
            // Project specific stages, special logic for this project
            stage('Compliance & SAST') {
                steps {
                    script {
                        sh(shellPreamble + '''
                            ${WORKSPACE}/.tmp/toolchain-management/libs/bash/common/compliance_and_security_scanning.sh
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
                                sh(shellPreamble + '''
                                    ${WORKSPACE}/.tmp/toolchain-management/libs/bash/iac/sem_ver_release_tagging.sh
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
