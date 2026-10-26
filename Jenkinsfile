@Library('twn-devops-bootcamp-jenkins-shared-library@feat/library-foundation') _

// Candidate pipeline: never grant cloud access to untrusted branch builds.
// Pin a reviewed Shared Library commit/tag before a real release.
pipeline {
    agent { label 'docker-aws-kubectl' }
    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 45, unit: 'MINUTES')
    }
    tools {
        maven 'maven-3.9'
    }
    parameters {
        booleanParam(name: 'PUBLISH_AND_DEPLOY', defaultValue: false,
                     description: 'Explicitly enable an approved release from main')
        string(name: 'EKS_CLUSTER', defaultValue: '',
               description: 'Approved pre-existing EKS cluster (required for release)')
    }
    environment {
        AWS_ACCOUNT_ID = '591132357918'
        AWS_REGION = 'eu-north-1'
        ECR_REPOSITORY = 'twn-devops-bootcamp/java-maven-app'
        EKS_NAMESPACE = 'default'
        DEPLOYMENT_NAME = 'capstone01-app'
        CONTAINER_NAME = 'capstone01-app'
    }
    stages {
        stage('Checkout and identify source') {
            steps {
                checkout scm
                script {
                    if (!(env.GIT_COMMIT ==~ /[a-fA-F0-9]{40}/)) {
                        error('Checkout did not provide a complete Git commit SHA')
                    }
                    env.IMAGE_TAG = "git-${env.GIT_COMMIT.substring(0, 12)}"
                }
            }
        }
        stage('Verify Maven application') {
            steps {
                mavenVerify()
            }
        }
        stage('Package application') {
            steps {
                mavenBuild(skipTests: true)
            }
        }
        stage('Build Docker image') {
            steps {
                script {
                    env.BUILT_IMAGE = ecrBuild(
                        accountId: env.AWS_ACCOUNT_ID,
                        region: env.AWS_REGION,
                        repository: env.ECR_REPOSITORY,
                        tag: env.IMAGE_TAG
                    )
                }
            }
        }
        stage('Approve release') {
            when {
                allOf {
                    branch 'main'
                    expression { params.PUBLISH_AND_DEPLOY }
                }
            }
            steps {
                script {
                    if (!params.EKS_CLUSTER?.trim()) {
                        error('Approved EKS_CLUSTER is required')
                    }
                }
                input message: 'Authorize ECR image publishing and EKS rollout?',
                      ok: 'Approve release'
            }
        }
        stage('Publish image and resolve digest') {
            when {
                allOf {
                    branch 'main'
                    expression { params.PUBLISH_AND_DEPLOY }
                }
            }
            steps {
                script {
                    ecrPush(
                        accountId: env.AWS_ACCOUNT_ID,
                        region: env.AWS_REGION,
                        repository: env.ECR_REPOSITORY,
                        tag: env.IMAGE_TAG
                    )
                    env.IMMUTABLE_IMAGE = ecrImageDigest(
                        accountId: env.AWS_ACCOUNT_ID,
                        region: env.AWS_REGION,
                        repository: env.ECR_REPOSITORY,
                        tag: env.IMAGE_TAG
                    )
                    echo "Immutable artifact: ${env.IMMUTABLE_IMAGE}"
                }
            }
        }
        stage('Deploy verified EKS target') {
            when {
                allOf {
                    branch 'main'
                    expression { params.PUBLISH_AND_DEPLOY }
                }
            }
            steps {
                script {
                    eksDeployVerified(
                        accountId: env.AWS_ACCOUNT_ID,
                        region: env.AWS_REGION,
                        cluster: params.EKS_CLUSTER.trim(),
                        namespace: env.EKS_NAMESPACE,
                        deployment: env.DEPLOYMENT_NAME,
                        container: env.CONTAINER_NAME,
                        image: env.IMMUTABLE_IMAGE
                    )
                }
            }
        }
    }
    post {
        always {
            echo "Capstone 01 build outcome: ${currentBuild.currentResult}"
        }
    }
}
