pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '987686461903.dkr.ecr.ap-south-1.amazonaws.com/docker-image:1.0'
        EC2_PUBLIC_IP = 'YOUR_EC2_PUBLIC_IP' // Replace with your EC2 public IP
        EC2_USER = 'ec2-user' // or ubuntu, depending on your AMI
        SSH_KEY = credentials('jenkins-ec2-key') // Jenkins SSH private key credential ID
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/sumanvitummala/jenkins-aws.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                bat 'docker build -t docker-image:1.0 .'
            }
        }

        stage('Tag Docker Image for ECR') {
            steps {
                echo "🏷️ Tagging Docker image for ECR..."
                bat "docker tag docker-image:1.0 ${ECR_REPO}"
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins']]) {
                    bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO.split(':')[0]}"
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                echo "📦 Pushing Docker image to AWS ECR..."
                bat "docker push ${ECR_REPO}"
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins']]) {
                    dir('.') {
                        bat 'terraform init'
                        bat 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Run Docker Container on EC2') {
            steps {
                echo "🚀 Running Docker container on EC2..."
                // Using SSH to run Docker commands on EC2
                sh """
                ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${EC2_USER}@${EC2_PUBLIC_IP} \\
                "docker pull ${ECR_REPO} && \\
                 docker stop my-container || true && \\
                 docker rm my-container || true && \\
                 docker run -d --name my-container -p 80:80 ${ECR_REPO}"
                """
            }
        }
    }
}



