#!groovy
//- Library Imports
@Library('jenkins-pipeline')
import com.ingenico.epayments.ci.common.Slack
import com.ingenico.epayments.ci.common.PipelineCommon

// String var config
String gitBranch    = 'main'
String gitRepoUrl   = 'git@'+ env.GITLAB_HOST + ':cicd/terraform/toolchain-management'
String slackChannel = 'nl-pros-centaurus-squad-releases'
String workerNode   = 'bambora-aws-slave-terraform'

pipeline {
    agent {
        node workerNode
    }
    environment {
        GITLAB_CREDENTIALSID = credentials('GL_PAT_TF_MODULE_MIRRORING')
    }
    stages {
        stage('Git: checkout') {
            steps {
                script {
                    pipelineCommon = new PipelineCommon(steps, env)
                    pipelineCommon.gitCheckout(gitRepoUrl, ".", gitBranch, env.GITLAB_CREDENTIALSID)
                }
            }
        }
        // This stage must be first to ensure system packages and language runtimes are availabe
        stage('Toolchain Mngr: run.sh --update only for System tools') {
            steps {
                // RHEL users do not typically have /usr/local/bin in the PATH. Override with the available /usr/bin location.
                // Jenkins worker nodes have [cracklib](https://github.com/cracklib/cracklib) system package installed.
                // It provides a `packer` in the PATH, ie name collision with Hashcorp Packer.
                // So, skip installing misc tools for now
                sh './libs/bash/run.sh --bin_dir /usr/bin --skip_aws_tools true --skip_misc_tools true --skip_terraform_tools true --update true'
            }
        }
        stage('Toolchain Mngr: run.sh --update only for AWS tools') {
            steps {
                sh './libs/bash/run.sh --bin_dir /usr/bin --skip_misc_tools true --skip_terraform_tools true --skip_system_tools true --update true'
            }
        }
        stage('Toolchain Mngr: run.sh --update only for Terraform tools') {
            steps {
                sh './libs/bash/run.sh --bin_dir /usr/bin --skip_aws_tools true --skip_misc_tools true --skip_system_tools true --update true'
            }
        }
    }
    post {
        failure {
            steps {
                script {
                    if (env.branch == 'main') {
                        script {
                            def slack = new Slack(this.steps, this.env)
                            slack.slackNotification(
                                slackChannel,
                                "Terraform Toolchain Management MAIN branch failed",
                                ":alert: :alert: :alert: Terraform Toolchain Management MAIN branch failed. This is critical and needs fixed ASAP.",
                                ':jenkins:'
                            )
                        }
                    } else {
                        script {
                            def slack = new Slack(this.steps, this.env)
                            slack.slackNotification(
                                slackChannel,
                                "Terraform Toolchain Management  working branch failed",
                                ":alert: Terraform Toolchain Management  pipeline for a working branch failed. Please contact the module owner.",
                                ':jenkins:'
                            )
                        }
                    }
                }
            }
        }
        success {
            script {
                def slack = new Slack(this.steps, this.env)
                slack.slackNotification(
                    slackChannel,
                    "Terraform Toolchain Management ",
                    ":white_check_mark: Terraform PToolchain Management  pipeline successful. All changes module changes validated and ready for apply.",
                    ':jenkins:'
                )
            }
        }
    }
}
