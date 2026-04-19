#!groovy
/* groovylint-disable CompileStatic, DuplicateMapLiteral, DuplicateStringLiteral, GStringExpressionWithinString, LineLength, NestedBlockDepth, UnnecessaryGString, UnusedImport */

// configuration vars

Number jobTimeout           = 30
String artifactNumToKeepStr = '7'
String githubPat            = 'GH_PAT'
String gitlabApiPat         = 'gitlab-kazan-technical-api-token'
String gitlabConnectionName = 'gitlab.kazan.myworldline.com'
String gitlabGitSa          = 'cicd-technical-user'
String gitlabProjectId      = 78445
String gitTargetBranch      = 'main'
String jenkinsNodeLabels    = 'aws && ec2 && fedora && toolchain'
String numToKeepStr         = '7'
String shellPreamble        = 'set -eo pipefail; if [[ $LOG_LEVEL == "TRACE" ]]; then set -x; fi; if [[ -f "$HOME/.bashrc" ]]; then source "$HOME/.bashrc"; fi;'
String slackChannel         = 'nl-pros-centaurus-squad-releases'
String slackWebhook         = 'SlackWebhook'

// logic

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
        stage('Reset') {
            steps {
                script {
                    if (env.BRANCH_NAME == gitTargetBranch) { // only if on main branch
                        sh(shellPreamble + '''
                            ${WORKSPACE}/libs/bash/reset.sh
                        ''')
                    }
                }
            }
        }
        stage('Install') {
            steps {
                script {
                    if (env.BRANCH_NAME == gitTargetBranch) { // only if on main branch
                        withCredentials([
                            gitUsernamePassword(credentialsId: gitlabGitSa)
                        ]) {
                            sh(shellPreamble + '''
                                ${WORKSPACE}/libs/bash/install.sh ''' + params.TOOLCHAIN_BRANCH + '''
                            ''')
                        }
                    }
                }
            }
        }
        // if on the main branch and docs/CHANGELOG.md diff
        // extract version number and message from docs/CHANGELOG.md
        // create tag with message, push to origin
        // push tag to commit in GL
        stage('Tagging') {
            steps {
                script {
                    if (env.BRANCH_NAME == gitTargetBranch) {
                        withCredentials([string(
                            credentialsId:  gitlabApiPat,
                            variable:       'gitlabPAT'
                        )]) {
                            sh(shellPreamble + '''
                                ${WORKSPACE}/libs/bash/iac/sem_ver_release_tagging.sh
                            ''')
                        }
                    }
                }
            }
        }
    }
    triggers {
        cron(env.BRANCH_NAME == gitTargetBranch ?  'H 8 30 * 1-5' : '')
        pollSCM(env.BRANCH_NAME == gitTargetBranch ? 'H 8 25 * 1-5' : '')
    }
}
