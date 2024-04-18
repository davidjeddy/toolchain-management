#!groovy
/* groovylint-disable CompileStatic, GStringExpressionWithinString, LineLength, NestedBlockDepth, UnusedImport */

//- Library Imports
@Library('jenkins-pipeline')
import com.ingenico.epayments.ci.common.PipelineCommon
import com.ingenico.epayments.ci.common.Slack

// String var config
String gitlabApiToken       = 'jenkins-user-gitlab-test-api-token'
String gitlabConnectionName = 'gitlab-test-igdcs'
String gitlabProjectId      = 3440

String gitSSHCreds          = 'jenkins-gitlab-test-igdcs'
String slackChannel         = 'nl-pros-centaurus-squad-releases'
String slackMsgSourceAcct   = ':jenkins:'
String workerNode           = 'bambora-aws-slave-terraform'

String gitTargetBranch      = 'main'

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
        timestamps()
        // https://stackoverflow.com/questions/38096004/how-to-add-a-timeout-step-to-jenkins-pipeline
        timeout(time: 30, unit: 'MINUTES')
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
                        ":alert: Build failed.\n Build URL: ${env.BUILD_URL}console",
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
                        ":green_check_mark: ${env.BRANCH_NAME} branch build fixed.",
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
                        credentialsId:  gitlabApiToken,
                        variable:       'gitlabPAT'
                    )]) {
                        sh '''#!/bin/bash -e
                            curl \
                                --form "note=# Build Pipeline\n\nNumber: ${BUILD_NUMBER}\n\nUrl: ${BUILD_URL}console" \
                                --header "PRIVATE-TOKEN: ''' +  env.gitlabPAT + '''" \
                                --request POST \
                                "https://${GITLAB_HOST}/api/v4/projects/''' + gitlabProjectId + '''/repository/commits/${GIT_COMMIT}/comments"
                        '''
                    }
                }
            }
        }
        stage('Clean Workspace') {
            steps {
                echo 'INFO: Clean workspace'
                cleanWs()
            }
        }
        stage('Print ENV VARs') {
            steps {
                script {
                    sh '''#!/bin/bash -e
                        echo "INFO: Printing ENV VARs"
                        # We do not want the default AWS credentials from Jenkins
                        unset JENKINS_AWS_CREDENTIALSID
                        # Prevent colors in BASH for tfenv and tgenv
                        # https://github.com/tfutils/tfenv#bashlog_colours
                        export BASHLOG_COLOURS=0
                        printenv | sort
                    '''
                }
            }
        }
        stage('Git Checkout') {
            steps {
                echo 'Checkout main branch'
                // Needed for compliance, sast, tagging
                git credentialsId: gitSSHCreds,
                    url: env.GIT_URL,
                    branch: gitTargetBranch
                echo 'Checkout feature branch'
                git credentialsId: gitSSHCreds,
                    url: env.GIT_URL,
                    branch: env.BRANCH_NAME
            }
        }
        // Pre-flight reset
        stage('Remove pre-existing UXT PPS shell profile') {
            steps {
                sh '''
                    $(rm -rf $HOME/.worldline_pps_profile || true)
                    $(sed -i '/worldline_pps_profile/d' $HOME/.bashrc || true)
                    $(sed -i '/worldline_pps_profile/d' $HOME/.bash_profile || true)
                    source ~/.bash_profile
                '''
            }
        }
        // Typical initial install process
        stage('./libs/bash/install.sh normal install without --update true') {
            steps {
                sh './libs/bash/install.sh'
            }
        }
        // Typical >= second execution, wherein shell profile does exist
        stage('./libs/bash/install.sh all tool sets and with --update true') {
            steps {
                sh './libs/bash/install.sh --update true'
            }
        }
        // Negative runs - Sorted alphabetically by tool group
        stage('./libs/bash/install.sh focus on cloud tools without --update true') {
            steps {
                sh './libs/bash/install.sh --skip_iac_tools true --skip_misc_tools true --skip_system_tools true'
            }
        }
        stage('./libs/bash/install.sh focus on iac tools without --update true') {
            steps {
                sh './libs/bash/install.sh --skip_cloud_tools true --skip_misc_tools true --skip_system_tools true'
            }
        }
        stage('./libs/bash/install.sh focus on misc tools without --update true') {
            steps {
                sh './libs/bash/install.sh --skip_cloud_tools true --skip_iac_tools true --skip_system_tools true'
            }
        }
        stage('./libs/bash/install.sh focus on system tools without --update true') {
            steps {
                sh './libs/bash/install.sh --skip_cloud_tools true --skip_iac_tools true --skip_misc_tools true'
            }
        }
        // if pipeline is running the main branch, tag a new release using changes content of CHANGLOG.md
        stage('Tagging') {
            steps {
                script {
                    if (env.BRANCH_NAME == gitTargetBranch) {
                        withCredentials([sshUserPrivateKey(
                            credentialsId: gitSSHCreds,
                            keyFileVariable: 'key'
                        )]) {
                            sh './libs/bash/common/sem_ver_release_tagging.sh'
                        }
                    }
                }
            }
        }
    }
    triggers {
        // https://www.jenkins.io/doc/book/pipeline/syntax/
        cron(env.BRANCH_NAME == gitTargetBranch ?  'H 0 * * 1-5' : '') // Run during the midnight hour Mon-Fri
        pollSCM('H 23 * * 1-5')                                        // Check branch status during the 2300 hour Mon-Fri daily
    }
}
