pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'                  // Updated region
        ECR_ACCOUNT_ID = '987686461903'           // Your AWS account ID
        ECR_REPO = 'docker-image'                 // Your ECR repository name
        IMAGE_TAG = '1.0'                          // Docker image version tag
        IMAGE_NAME = "${ECR_REPO}:${IMAGE_TAG}"    // Local Docker image name
        FULL_ECR_NAME = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}" // Full ECR image path
    }

    stages {

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                bat "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Tag Docker Image for ECR') {
            steps {
                echo "Tagging Docker image for ECR..."
                bat "docker tag ${IMAGE_NAME} ${FULL_ECR_NAME}"
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo "Logging in to AWS ECR..."
                bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                echo "Pushing Docker image to AWS ECR..."
                bat "docker push ${FULL_ECR_NAME}"
            }
        }

    }

    post {
        success {
            echo "Docker image successfully pushed to AWS ECR!"
        }
        failure {
            echo "Build failed. Check the console output for errors."
        }
    }
}

