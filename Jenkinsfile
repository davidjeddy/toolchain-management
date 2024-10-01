#!groovy
/* groovylint-disable CompileStatic, DuplicateMapLiteral, DuplicateStringLiteral, GStringExpressionWithinString, LineLength, NestedBlockDepth, UnnecessaryGString, UnusedImport */

//- Library Imports
@Library('jenkins-pipeline-lib')
import com.ingenico.epayments.ci.common.Slack

// configuration vars

Number jobTimeout           = 30
String artifactNumToKeepStr = '7'
// Intentionally left blank
String githubPat            = 'GH_PAT'
String gitlabApiPat         = 'gitlab-kazan-technical-api-token'
String gitlabConnectionName = 'gitlab.kazan.myworldline.com'
String gitlabGitSa          = 'cicd-technical-user'
String gitlabProjectId      = 78445
String gitTargetBranch      = 'main'
String jenkinsNodeLabels    = 'ec2 && fedora && toolchain'
String numToKeepStr         = '7'
String slackChannel         = 'nl-pros-centaurus-squad-releases'
String slackMsgSourceAcct   = ':jenkins:'

// global scope container vars

// No need to edit below this line

// helper functions

// execution

pipeline {
    agent { // https://digitalvarys.com/jenkins-declarative-pipeline-with-examples/
        // node workerNode
        node {
            label jenkinsNodeLabels
        }
    }
    environment {
        GITLAB_CREDENTIALSID = credentials("${gitlabApiPat}")
        GITHUB_TOKEN = credentials("${githubPat}")
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
    post {
        // always, changed, fixed, regression, aborted, failure, success, unstable, unsuccessful, and cleanup
        failure {
            script {
                if (env.gitlabBranch == gitTargetBranch) {
                    // if main, send to nl-pros-equad-releases
                    object slack = new Slack(this.steps, this.env)
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
                    object slack = new Slack(this.steps, this.env)
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
                        sh('''#!/bin/bash
                            set -eo pipefail
                            # shellcheck disable=SC1091
                            source "$HOME/.bashrc" || exit 1

                            if [[ $LOG_LEVEL == "TRACE" ]]
                            then
                                set -x
                            fi

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
        stage('System ENV VARs') {
            steps {
                sh('''#!/bin/bash
                    set -eo pipefail
                    # shellcheck disable=SC1091
                    source "$HOME/.bashrc" || exit 1

                    if [[ $LOG_LEVEL == "TRACE" ]]
                    then
                        set -x
                    fi

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
        // Project specific stages
        stage('Reset Host') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main') { // re/install only if on main branch
                        sh('''#!/bin/bash
                            set -eo pipefail
                            # shellcheck disable=SC1091
                            source "$HOME/.bashrc" || exit 1

                            if [[ $LOG_LEVEL == "TRACE" ]]
                            then
                                set -x
                            fi

                            ${WORKSPACE}/libs/bash/reset.sh
                        ''')
                    }
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main') { // re/install only if on main branch
                        withCredentials([
                            gitUsernamePassword(credentialsId: gitlabGitSa)
                        ]) {
                            sh('''#!/bin/bash
                                set -eo pipefail
                                # shellcheck disable=SC1091
                                source "$HOME/.bashrc" || exit 1

                                if [[ $LOG_LEVEL == "TRACE" ]]
                                then
                                    set -x
                                fi

                                ${WORKSPACE}/libs/bash/install.sh ''' + params.TOOLCHAIN_BRANCH + '''
                            ''')
                        }
                    }
                }
            }
        }
   }
    triggers {
        cron(env.BRANCH_NAME == gitTargetBranch ?  'H 3 * * 1-5' : '')
        pollSCM(env.BRANCH_NAME == gitTargetBranch ? 'H 3 * * 1-5' : '')
    }
}
