#!groovy
/* groovylint-disable CompileStatic, GStringExpressionWithinString, LineLength, NestedBlockDepth, UnusedImport */

//- Library Imports
@Library('jenkins-pipeline-lib')
import com.ingenico.epayments.ci.common.PipelineCommon
import com.ingenico.epayments.ci.common.Slack

// configuration vars

Number jobTimeout           = 30
String githubPat            = 'GH_PAT'
String gitlabApiPat         = 'gitlab-kazan-technical-api-token'
String gitlabConnectionName = 'gitlab.kazan.myworldline.com'
String gitlabGitSa          = 'cicd-technical-user'
String gitlabProjectId      = 78445
String gitTargetBranch      = 'main'
String slackChannel         = 'nl-pros-centaurus-squad-releases'
String slackMsgSourceAcct   = ':jenkins:'
String workerNode           = 'bambora-aws-slave-terraform'

// global scope container vars

// No need to edit below this line

// helper functions

// execution

pipeline {
    agent {
        node workerNode
    }
    environment {
        GITLAB_CREDENTIALSID = credentials("${gitlabApiPat}")
        GITHUB_TOKEN = credentials("${githubPat}")
    }
    options {
        ansiColor('xterm') // https://plugins.jenkins.io/ansicolor/
        gitLabConnection(gitlabConnectionName)
        skipStagesAfterUnstable()
        timeout(time: jobTimeout, unit: 'MINUTES') // https://stackoverflow.com/questions/38096004/how-to-add-a-timeout-step-to-jenkins-pipeline
        timestamps()
    }
    // https://stackoverflow.com/questions/36651432/how-to-implement-post-build-stage-using-jenkins-pipeline-plug-in
    // https://plugins.jenkins.io/gitlab-plugin/
    post {
        // always, changed, fixed, regression, aborted, failure, success, unstable, unsuccessful, and cleanup
        failure {
            script {
                if (env.gitlabBranch == gitTargetBranch) {
                    // if main, send to nl-pros-equad-releases
                    object slack = new Slack(this.steps, this.env)
                    slack.slackNotification(
                        slackChannel,
                        env.JOB_NAME,
                        ':alert: Build failed.\n ${env.BUILD_URL}console',
                        slackMsgSourceAcct
                    )
                }
            }
            updateGitlabCommitStatus name: 'build', state: 'failed'
        }
        fixed {
            script {
                if (env.gitlabBranch == gitTargetBranch) {
                    // if main, send to nl-pros-equad-releases
                    object slack = new Slack(this.steps, this.env)
                    slack.slackNotification(
                        slackChannel,
                        env.JOB_NAME,
                        ':tada: Build fixed.\n${env.BUILD_URL}console',
                        slackMsgSourceAcct
                    )
                }
            }
            /* groovylint-disable-next-line DuplicateMapLiteral, DuplicateStringLiteral */
            updateGitlabCommitStatus name: 'build', state: 'failed'
        }
        success {
            /* groovylint-disable-next-line DuplicateStringLiteral */
            updateGitlabCommitStatus name: 'build', state: 'success'
        }
        unstable {
            /* groovylint-disable-next-line DuplicateMapLiteral, DuplicateStringLiteral */
            updateGitlabCommitStatus name: 'build', state: 'success'
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
                            set -exo pipefail

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
                    set -exo pipefail

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
        // Typical direct re/install
        stage('Execute toolchain re/install') {
            steps {
                sh('''#!/bin/bash
                    set -exo pipefail

                    ${WORKSPACE}/libs/bash/install.sh
                    source ~/.bashrc
                ''')
            }
        }
        stage('Execute Aqua install/update') {
            steps {
                sh('''#!/bin/bash
                    set -exo pipefail
                    
                    # pipeline runs non-interactive, but we still want the tools from an interactive session
                    source ~/.bashrc 

                    aqua install
                    aqua update
                ''')
            }
        }
        // if pipeline is running the main branch, tag a new release using changes content of CHANGLOG.md
        stage('Tagging') {
            steps {
                script {
                    withCredentials([string(
                        credentialsId:  gitlabApiPat,
                        variable:       'gitlabPAT'
                    )]) {
                        if (env.BRANCH_NAME == gitTargetBranch) {
                            sh('''#!/bin/bash
                                set -exo pipefail

                                ./libs/bash/common/sem_ver_release_tagging.sh
                            ''')
                        }
                    }
                }
            }
        }
    }
    triggers {
        cron(env.BRANCH_NAME == gitTargetBranch ?  'H 0 * * 1-5' : '')      // Run during the midnight hour Mon-Fri
        pollSCM(env.BRANCH_NAME == gitTargetBranch ? 'H 23 * * 1-5' : '')   // Check branch status during the 2300 hour Mon-Fri daily
    }
}
