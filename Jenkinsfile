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
        echo "🚀 Deploying Docker container on EC2..."

        // Replace the values below with your EC2 info
        def EC2_IP = "YOUR_EC2_PUBLIC_IP"
        def PEM_PATH = "C:\\Users\\AppuSummi\\.ssh\\sumanvi-key.pem"
        def ECR_IMAGE = "987686461903.dkr.ecr.ap-south-1.amazonaws.com/docker-image:1.0"

        // Run commands on EC2 via SSH
        bat """
        ssh -i ${PEM_PATH} -o StrictHostKeyChecking=no ec2-user@${EC2_IP} ^
        "aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 987686461903.dkr.ecr.ap-south-1.amazonaws.com &&
        docker pull ${ECR_IMAGE} &&
        docker stop my-app || true &&
        docker rm my-app || true &&
        docker run -d --name my-app -p 80:80 ${ECR_IMAGE}"
        """
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
