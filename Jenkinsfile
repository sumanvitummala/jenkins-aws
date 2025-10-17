pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '987686461903.dkr.ecr.ap-south-1.amazonaws.com/docker-image'
        EC2_SSH_CREDENTIALS = 'EC2_SSH_KEY' // Jenkins credential ID for private key
        EC2_USER = 'ec2-user'               // Change if your instance uses a different user
    }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/sumanvitummala/jenkins-aws.git', branch: 'main'
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
                echo "🏷 Tagging Docker image for ECR..."
                bat "docker tag docker-image:1.0 %ECR_REPO%:1.0"
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS_CREDENTIALS']]) {
                    echo "🔑 Logging in to AWS ECR..."
                    bat 'aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPO%'
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                echo "📦 Pushing Docker image to AWS ECR..."
                bat "docker push %ECR_REPO%:1.0"
            }
        }

        stage('Terraform Init & Import') {
            steps {
                dir('C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\jenkins-aws') {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS_CREDENTIALS']]) {
                        echo "🚀 Initializing Terraform..."
                        bat 'terraform init'

                        echo "🔄 Importing existing EC2..."
                        bat 'terraform import -ignore-remote-version aws_instance.my_ec2 i-0b83b3b2b8e15b0f8 || echo "EC2 already imported or not present"'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\jenkins-aws') {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS_CREDENTIALS']]) {
                        echo "🚀 Applying Terraform configuration..."
                        bat 'terraform apply -auto-approve'

                        echo "📡 Getting EC2 public IP..."
                        bat 'terraform output -raw instance_public_ip > instance_ip.txt'
                    }
                }
            }
        }

        stage('Deploy Docker Container on EC2') {
            steps {
                echo "🚀 Deploying Docker container on EC2..."
                sshagent(credentials: [env.EC2_SSH_CREDENTIALS]) {
                    script {
                        def ec2IP = readFile('C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\jenkins-aws\\instance_ip.txt').trim()
                        sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${ec2IP} \\
                        "docker pull ${ECR_REPO}:1.0 && docker stop my-container || true && docker rm my-container || true && docker run -d --name my-container -p 80:80 ${ECR_REPO}:1.0"
                        """
                    }
                }
            }
        }
    }

    post {
        failure {
            echo "❌ Pipeline failed. Check the console output for errors."
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
    }
}

