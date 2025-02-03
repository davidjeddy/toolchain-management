#!groovy
/* groovylint-disable CompileStatic, DuplicateMapLiteral, DuplicateStringLiteral, GStringExpressionWithinString, LineLength, MethodReturnTypeRequired, MethodSize, NestedBlockDepth, NoDef, ParameterCount, UnusedImport */

def call(
    Number gitlabProjectId,
    Number jobTimeout,
    String cronSchedule,
    String slackChannel
){
    String artifactNumToKeepStr = '7'
    String githubPat            = 'GH_PAT'
    String gitlabApiPat         = 'gitlab-kazan-technical-api-token'
    String gitlabConnectionName = 'gitlab.kazan.myworldline.com'
    String gitlabGitSa          = 'cicd-technical-user'
    String gitTargetBranch      = 'main'
    String jenkinsNodeLabels    = 'aws && container && ec2 && podman'
    String numToKeepStr         = '7'
    String shellPreamble        = 'set -eo pipefail; if [[ $LOG_LEVEL == "TRACE" ]]; then set -x; fi; if [[ -f "$HOME/.bashrc" ]]; then source "$HOME/.bashrc"; fi; export PLATFORM="linux/amd64"; export DOCKER_DEFAULT_PLATFORM="${PLATFORM}"; export CONTAINER_DEFAULT_PLATFORM="${PLATFORM}"'
    String slackWebhook         = 'SlackWebhook'

    List targetAccounts = [
        // dev deployment is typically decommissioned; keep this for when it is needed
        // [
        //     env: 'development',
        //     credentials: [
        //         $class:             'AmazonWebServicesCredentialsBinding',
        //         accessKeyVariable:  'AWS_ACCESS_KEY_ID',
        //         credentialsId:      'worldline-gc-cicd-build-dev',
        //         secretKeyVariable:  'AWS_SECRET_ACCESS_KEY'
        //     ]
        // ],
        [
            env: 'production',
            credentials: [
                $class:             'AmazonWebServicesCredentialsBinding',
                accessKeyVariable:  'AWS_ACCESS_KEY_ID',
                credentialsId:      'worldline-gc-cicd-build-prod',
                secretKeyVariable:  'AWS_SECRET_ACCESS_KEY'
            ]
        ],
    ]

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
            string(name: 'AWS_ECR_DNS', defaultValue: '1234567890.dkr.ecr.aws-region-here.amazonaws.com/env/app/cmp/src/rnd')
            string(name: 'AWS_REGION', defaultValue: 'eu-west-1')
            string(name: 'IMAGE_TAG_VERSION', defaultValue: '0.0.0')
            string(name: 'TOOLCHAIN_BRANCH', defaultValue: gitTargetBranch)
        }
        post { // always, changed, fixed, regression, aborted, failure, success, unstable, unsuccessful, and cleanup
            failure {
                script {
                    if (env.BRANCH_NAME == gitTargetBranch) {
                        // slackChannel argument must NOT include the leading # character, we add it here
                        sh(shellPreamble + '''
                            curl \
                                --data '{
                                    "channel": "#''' + slackChannel + '''",
                                    "text": ":pipeline-failed: ''' + env.JOB_NAME + ''' build FAILED.\n''' + env.BUILD_URL + '''console."
                                }' \
                                --header "Content-type: application/json" \
                                --location \
                                --verbose \
                                "''' + env.SLACK_WEBHOOK + '''"
                        ''')
                    }
                }
                updateGitlabCommitStatus name: 'build', state: 'failed'
            }
            fixed {
                script {
                    if (env.BRANCH_NAME == gitTargetBranch) {
                        // slackChannel argument must NOT include the leading # character, we add it here
                        sh(shellPreamble + '''
                            curl \
                                --data '{
                                    "channel": "#''' + slackChannel + '''",
                                    "text": ":tada: ''' + env.JOB_NAME + ''' build FIXED.\n''' + env.BUILD_URL + '''console."
                                }' \
                                --header "Content-type: application/json" \
                                --location \
                                --verbose \
                                "''' + env.SLACK_WEBHOOK + '''"
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
                    git branch: gitTargetBranch,
                        credentialsId: gitlabGitSa,
                        url: env.GIT_URL
                    echo 'Checkout feature branch for pipeline execution'
                    git branch: env.BRANCH_NAME,
                        credentialsId: gitlabGitSa,
                        url: env.GIT_URL
                }
            }
            // Project specific stages, special logic for this project
            stage('Install Dependencies') {
                steps {
                    script {
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
            // Project specific stages
            stage('Build Image') {
                steps {
                    script {
                        // loop targetAccounts
                        targetAccounts.eachWithIndex { item, index ->
                            // using the configured credentials
                            withCredentials([item.credentials]) {
                                println '''INFO: targetAccounts is: ''' + index + ''' : ''' + item
                                // to build and tag the image for that specific account + deployment
                                sh(shellPreamble + '''
                                    podman build . \
                                        --file "Containerfile" \
                                        --platform "${PLATFORM}" \
                                        --squash \
                                        --tag "''' + params.AWS_ECR_DNS + ''':''' + params.IMAGE_TAG_VERSION + '''" \
                                        | tee "build_$(date +%s).log"
                                    podman images -q "''' + params.AWS_ECR_DNS + ''':''' + params.IMAGE_TAG_VERSION + '''"
                                ''')
                            }
                        }
                    }
                }
            }
            stage('Validate Image') {
                steps {
                    script {
                        // loop targetAccounts
                        targetAccounts.eachWithIndex { item, index ->
                            // using the configured credentials
                            withCredentials([item.credentials]) {
                                println '''INFO: targetAccounts is: ''' + index + ''' : ''' + item
                                sh(shellPreamble + '''
                                    CI=true dive podman://''' + params.AWS_ECR_DNS + ''':''' + params.IMAGE_TAG_VERSION + ''' --ci | tee .tmp/dive.log
                                ''')
                            }
                        }
                    }
                }
            }
            stage('Auth and Push Image') {
                steps {
                    script {
                        if (env.BRANCH_NAME == gitTargetBranch && params.IMAGE_TAG_VERSION != '0.0.0') {
                            // loop targetAccounts
                            targetAccounts.eachWithIndex { item, index ->
                                // using the configured credentials
                                withCredentials([item.credentials]) {
                                    println '''INFO: targetAccounts is: ''' + index + ''' : ''' + item
                                    sh(shellPreamble + '''
                                        aws ecr get-authorization-token \
                                            --region "''' + params.AWS_REGION + '''" \
                                            --output text \
                                            --query 'authorizationData[].authorizationToken' \
                                            | base64 -d \
                                            | cut -d: -f2 \
                                            | podman login \
                                                --username "AWS" \
                                                --password-stdin \
                                                "https://''' + params.AWS_ECR_DNS + '''"
                                        podman push ''' + params.AWS_ECR_DNS + ''':''' + params.IMAGE_TAG_VERSION + '''
                                    ''')
                                }
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
                        if (env.BRANCH_NAME == gitTargetBranch && params.IMAGE_TAG_VERSION != '0.0.0') {
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
            cron(env.BRANCH_NAME == gitTargetBranch ?  'H 5 * * 1-5' : '')
            pollSCM(env.BRANCH_NAME == gitTargetBranch ? 'H 10 * * 1-5' : '')
        }
    }
}
