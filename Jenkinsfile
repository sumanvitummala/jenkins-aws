pipeline {
    agent any

    environment {
        IMAGE_TAG = "1.0"
        ECR_REPO = "987686461903.dkr.ecr.ap-south-1.amazonaws.com/docker-image"
        AWS_REGION = "ap-south-1"
        SSH_KEY_PATH = "C:/Users/AppuSummi/.ssh/sumanvi-key.pem"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Clean Workspace') {
            steps {
                echo "🧹 Cleaning old workspace..."
                deleteDir()
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                bat "docker build -t docker-image:${IMAGE_TAG} ."
            }
        }

        stage('Tag Docker Image for ECR') {
            steps {
                echo "🏷️ Tagging Docker image for ECR..."
                bat "docker tag docker-image:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo "🔑 Logging into AWS ECR..."
                bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}"
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                echo "📤 Pushing Docker image to ECR..."
                bat "docker push ${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('Deploy Docker Container on EC2') {
            steps {
                script {
                    def instance_ip = readFile('instance_ip.txt').trim()
                    echo "🚀 Deploying Docker container on EC2..."
                    bat """
                        ssh -o StrictHostKeyChecking=no -i "${SSH_KEY_PATH}" ec2-user@${instance_ip} ^
                        "docker stop docker-container || true && docker rm docker-container || true && docker pull ${ECR_REPO}:${IMAGE_TAG} && docker run -d --name docker-container -p 80:80 ${ECR_REPO}:${IMAGE_TAG}"
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check console output for details."
        }
    }
}
