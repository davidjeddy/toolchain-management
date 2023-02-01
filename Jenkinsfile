#!groovy
//- Library Imports
@Library('jenkins-pipeline')
import com.ingenico.epayments.ci.common

// String var config
String workerNode       = 'bambora-aws-slave-terraform'
String gitRepoUrl       = 'git@'+ env.GITLAB_HOST + ':cicd/terraform/toolchain-management'

pipeline {
    agent {
        node workerNode
    }
    stages {
        stage('Checkout') {
            steps {
                script {
                    
                    git = new git(steps, env)
                    // PipelineCommon.groovy def gitCheckout(def reopUrl, def targetDir, def branchTag, def credentialsId, boolean noTags) {
                    gitCheckout(gitRepoUrl, ".", "main", false)
                }
            }
        }
        stage('Install toolchain') {
            steps {
                sh './lib/bash/run.sh'
            }
        }
        stage('Update toolchain') {
            steps {
                sh './lib/bash/run.sh --update true'
            }
        }
    }
}
