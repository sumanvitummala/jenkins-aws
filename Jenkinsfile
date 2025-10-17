pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        REGION = 'ap-south-1'
        ECR_REPO = '987686461903.dkr.ecr.ap-south-1.amazonaws.com/docker-image:1.0'
        DOCKER_IMAGE = 'docker-image:1.0'
        KEY_PATH = 'C:/Users/AppuSummi/.ssh/sumanvi-key.pem' // path to your private key
        SSH_USER = 'ec2-user'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git url: 'https://github.com/sumanvitummala/jenkins-aws.git', branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                bat "docker build -t ${DOCKER_IMAGE} ."
            }
        }

        stage('Tag Docker Image for ECR') {
            steps {
                echo "🏷 Tagging Docker image for ECR..."
                bat "docker tag ${DOCKER_IMAGE} ${ECR_REPO}"
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo "🔑 Logging in to AWS ECR..."
                withCredentials([usernamePassword(credentialsId: 'AWS', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    bat "aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO.split(':')[0]}"
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
                echo "🚀 Applying Terraform Configuration..."
                withCredentials([usernamePassword(credentialsId: 'AWS', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir("${WORKSPACE}") {
                        bat "terraform init"
                        bat "terraform apply -auto-approve"
                        bat "terraform output -raw instance_public_ip > instance_ip.txt"
                    }
                }
            }
        }

        stage('Deploy Docker Container on EC2') {
            steps {
                script {
                    def instanceIp = readFile('instance_ip.txt').trim()
                    echo "✅ EC2 Instance IP: ${instanceIp}"

                    echo "⏳ Waiting for EC2 to be reachable on SSH..."
                    def reachable = false
                    for (int i = 0; i < 12; i++) { // retries for 2 minutes
                        def result = bat(script: "powershell -Command \"Test-NetConnection -ComputerName ${instanceIp} -Port 22 | Select-Object -ExpandProperty TcpTestSucceeded\"", returnStdout: true).trim()
                        if (result == "True") {
                            reachable = true
                            break
                        }
                        sleep 10
                    }

                    if (!reachable) {
                        error("❌ EC2 instance not reachable via SSH!")
                    }

                    echo "🔹 Connecting to EC2 and deploying Docker container..."
                    bat "powershell -Command \"ssh -o StrictHostKeyChecking=no -i ${KEY_PATH} ${SSH_USER}@${instanceIp} 'docker run -d -p 80:80 ${ECR_REPO}'\""
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check the console output for errors."
        }
    }
}



