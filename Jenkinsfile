#!groovy
/* groovylint-disable CompileStatic, GStringExpressionWithinString, LineLength, NestedBlockDepth, UnusedImport */

//- Library Imports
@Library('jenkins-pipeline-lib')
import com.ingenico.epayments.ci.common.PipelineCommon
import com.ingenico.epayments.ci.common.Slack

// configuration vars

Number jobTimeout           = 30
String artifactNumToKeepStr = '7'
String githubPat            = 'GH_PAT'
String gitlabApiPat         = 'gitlab-kazan-technical-api-token'
String gitlabConnectionName = 'gitlab.kazan.myworldline.com'
String gitlabGitSa          = 'cicd-technical-user'
String gitlabProjectId      = 78445
String gitTargetBranch      = 'main'
String numToKeepStr         = '7'
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
    options { // https://www.jenkins.io/doc/book/pipeline/syntax/#options
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: numToKeepStr, artifactNumToKeepStr: artifactNumToKeepStr))
        disableConcurrentBuilds()
        gitLabConnection(gitlabConnectionName)
        skipStagesAfterUnstable()
        timeout(time: jobTimeout, unit: 'MINUTES')
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
                        sh('''#!/bin/bash -l
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
                sh('''#!/bin/bash -l
                    set -exo pipefail
                    source $HOME/.bashrc

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
                sh('''#!/bin/bash -l
                    set -exo pipefail
                    source $HOME/.bashrc

                    ${WORKSPACE}/libs/bash/install.sh
                    source ~/.bashrc
                ''')
            }
        }
        stage('Execute Aqua install/update') {
            steps {
                sh('''#!/bin/bash -l
                    set -exo pipefail
                    source $HOME/.bashrc 

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
                            sh('''#!/bin/bash -l
                                set -exo pipefail
                                source $HOME/.bashrc

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
