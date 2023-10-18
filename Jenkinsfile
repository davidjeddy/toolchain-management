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
        timeout(time: 15, unit: 'MINUTES')
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
                echo "INFO: Checkout main branch"
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
    }
    triggers {
        cron(env.BRANCH_NAME == 'main' ? 'H 4 * * 1-5' : '')
    }
}
