#!groovy
/* groovylint-disable CompileStatic, DuplicateMapLiteral, DuplicateStringLiteral, GStringExpressionWithinString, LineLength, MethodReturnTypeRequired, MethodSize, NestedBlockDepth, NoDef, ParameterCount, UnusedImport, UnusedMethodParameter */

// RegEx expressions are not serializable. So we have to do the evaluation outside the pipeline scope
// https://groups.google.com/g/jenkinsci-users/c/Dvqkoadvwlk/m/fv5LImmnBAAJ?pli=1
// https://stackoverflow.com/questions/37280527/regex-for-version-number-format
def isSemVer(
    String value
) {
    return (value ==~ /(\d+)\.(\d+)\.(\d+)/)
}

def call(
    Number gitlabProjectId,
    Number jobTimeout,
    String awsAccountName,
    String awsEcrDns,
    String awsRegion,
    String cronSchedule,
    String imageArchs,
    String slackChannel
){
    String artifactNumToKeepStr = '7'
    String buildNumber          = currentBuild.number + 1
    String githubPat            = 'GH_PAT'
    String gitlabApiPat         = 'gitlab-kazan-technical-api-token'
    String gitlabConnectionName = 'gitlab.kazan.myworldline.com'
    String gitlabGitSa          = 'cicd-technical-user'
    String gitTargetBranch      = 'main'
    String jenkinsNodeLabels    = 'container && dive && ec2 && podman && toolchain'
    String numToKeepStr         = '7'
    String shellPreamble        = 'set -eo pipefail; if [[ $LOG_LEVEL == "TRACE" ]]; then set -x; fi; if [[ -f "$HOME/.bashrc" ]]; then source "$HOME/.bashrc"; fi;'
    String slackWebhook         = 'SlackWebhook'

    List targetAccounts = [
        [
            env: 'production',
            credentials: [
                $class:             'AmazonWebServicesCredentialsBinding',
                accessKeyVariable:  'AWS_ACCESS_KEY_ID',
                credentialsId:      awsAccountName,
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
            string(name: 'AWS_ECR_DNS', defaultValue: awsEcrDns, trim: true)
            string(name: 'AWS_REGION', defaultValue: awsRegion, trim: true)
            string(name: 'IMAGE_PLATFORMS', defaultValue: imageArchs, trim: true)
            string(name: 'IMAGE_TAG_VERSION', defaultValue: buildNumber, trim: true)
            string(name: 'TOOLCHAIN_BRANCH', defaultValue: gitTargetBranch, trim: true)
        }
        post { // always, changed, fixed, regression, aborted, failure, success, unstable, unsuccessful, and cleanup
            always {
                script {
                    // Not main  branch
                    if (env.BRANCH_NAME != gitTargetBranch) {
                        // remove feature branch container image tag version
                        sh(shellPreamble + '''
                            podman manifest rm ''' + params.AWS_ECR_DNS + ''':''' + params.IMAGE_TAG_VERSION + ''' # Remove manifest based image builds
                            podman image prune --all --force --filter "until=168h" # Remove resources older than 7 days
                            podman image prune --force # Remove dangling images
                        ''')
                    }
                }
            }
            failure {
                script {
                    if (env.BRANCH_NAME == gitTargetBranch) {
                        // slackChannel argument must NOT include the leading # character, we add it here
                        sh(shellPreamble + '''
                            curl \
                                --data '{
                                    "channel": "#''' + slackChannel + '''",
                                    "text": ":warning: ''' + env.JOB_NAME + ''' build FAILED.\n''' + env.BUILD_URL + '''console."
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
                                        podman manifest create ''' + params.AWS_ECR_DNS + ''':''' + params.IMAGE_TAG_VERSION + '''
                                        podman build . \
                                            --file "Containerfile" \
                                            --platform "''' + params.IMAGE_PLATFORMS + '''" \
                                            --manifest "''' + params.AWS_ECR_DNS + ''':''' + params.IMAGE_TAG_VERSION + '''" \
                                            --squash
                                        podman image ls | grep "''' + params.AWS_ECR_DNS + '''" | grep "''' + params.IMAGE_TAG_VERSION + '''"
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
                        // Branch must be main and tag must be SemVer pattern
                        if (env.BRANCH_NAME == gitTargetBranch && isSemVer(params.IMAGE_TAG_VERSION) ) {
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
                                        podman manifest push ''' + params.AWS_ECR_DNS + ''':''' + params.IMAGE_TAG_VERSION + '''
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
                        // Branch must be main and tag must be SemVer pattern
                        if (env.BRANCH_NAME == gitTargetBranch && isSemVer(params.IMAGE_TAG_VERSION) ) {
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
