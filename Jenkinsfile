#!groovy
//- Library Imports
@Library('jenkins-pipeline')
import com.ingenico.epayments.ci.common.PipelineCommon
import com.ingenico.epayments.ci.common.Slack

// String var config
String gitBranch    = 'main'
String gitRepoUrl   = 'git@'+ env.GITLAB_HOST + ':cicd/terraform/tools/toolchain-management.git'
String slackChannel = 'nl-pros-centaurus-squad-releases'
String workerNode   = 'bambora-aws-slave-terraform'

pipeline {
    agent {
        node workerNode
    }
    environment {
        GITLAB_CREDENTIALSID = credentials('GL_PAT_TF_MODULE_MIRRORING')
    }
    options {
        timestamps ()
    }
    // source https://stackoverflow.com/questions/36651432/how-to-implement-post-build-stage-using-jenkins-pipeline-plug-in
    // source https://plugins.jenkins.io/gitlab-plugin/
    post {
        // TODO: send to commit author via email. use commit email to get slack username to send msg. this req. a feature add to the Groovy Slack class as it does not currently support this feature
        // always, changed, fixed, regression, aborted, failure, success, unstable, unsuccessful, and cleanup
        failure {
            script {
                if (env.gitlabBranch == 'main') {
                    // if main, send to nl-pros-equad-releases
                    def slack = new Slack(this.steps, this.env)
                    slack.slackNotification(
                        slackChannel,
                        "Terraform Toolchain Management",
                        ":alert: Terraform Toolchain main branch pipeline failed.",
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
        stage('Git: checkout') {
            steps {
                script {
                    pipelineCommon = new PipelineCommon(steps, env)
                    pipelineCommon.gitCheckout(gitRepoUrl, ".", gitBranch, env.GITLAB_CREDENTIALSID)
                }
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
        cron('H 4 * * 1-5')
    }
}
