pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO =   '894943009636.dkr.ecr.us-east-1.amazonaws.com/pulse'
        IMAGE_TAG = "${GIT_COMMIT.take(8)}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Lint') {
            steps {
                sh '''
                    pip3 install flake8
                    flake8 src/api/app.py
                '''
            }
        }
        stage('Test') {
            steps {
                sh '''
                    pip3 install -r src/api/requirements.txt
                    pip3 install pytest
                    pytest src/api/tests/ -v
                '''
            }
        }
        stage('Docker Build') {
            steps {
                sh '''
                    docker build \
                        --platform linux/amd64 \
                        -t ${ECR_REPO}:${IMAGE_TAG} \
                        src/api
                '''
            }
        }
        stage('ECR Push') {
            steps {
                sh '''
                    aws ecr get-login-password \
                        --region ${AWS_REGION} | \
                        docker login \
                        --username AWS \
                        --password-stdin ${ECR_REPO}

                    docker push ${ECR_REPO}:${IMAGE_TAG}
                '''
            }
        }
        stage('Terraform Plan') {
            steps {
                sh '''
                    cd infra/envs/dev
                    terraform init -reconfigure
                    terraform plan
                '''
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                    aws ecs update-service \
                        --cluster pulse-cluster \
                        --service pulse-service \
                        --force-new-deployment \
                        --region ${AWS_REGION}

                    aws ecs wait services-stable \
                        --cluster pulse-cluster \
                        --services pulse-service \
                        --region ${AWS_REGION}
                '''
            }
        }

    }

    post {
        success {
            echo 'Pulse deployed successfully'
        }
        failure {
            echo 'Pipeline failed - check logs'
        }
    }
}