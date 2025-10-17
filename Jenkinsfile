pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '987686461903.dkr.ecr.ap-south-1.amazonaws.com/docker-image:1.0'
        KEY_PATH = 'C:\\Users\\AppuSummi\\.ssh\\sumanvi-key.pem'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/sumanvitummala/jenkins-aws.git', branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                bat 'docker build -t docker-image:1.0 .'
            }
        }

        stage('Tag Docker Image for ECR') {
            steps {
                echo '🏷 Tagging Docker image for ECR...'
                bat "docker tag docker-image:1.0 ${ECR_REPO}"
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    echo '🔑 Logging in to AWS ECR...'
                    bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO.split(':')[0]}"
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                echo '📦 Pushing Docker image to AWS ECR...'
                bat "docker push ${ECR_REPO}"
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\jenkins-aws') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        echo '🚀 Applying Terraform Configuration...'
                        bat 'terraform apply -auto-approve'
                        bat 'terraform output -raw instance_public_ip > instance_ip.txt'
                    }
                }
            }
        }

        stage('Deploy Docker Container on EC2') {
            steps {
                script {
                    def ec2Ip = readFile('instance_ip.txt').trim()
                    echo "✅ EC2 Instance IP: ${ec2Ip}"

                    powershell """
                    ssh -o StrictHostKeyChecking=no -i ${KEY_PATH} ec2-user@${ec2Ip} "docker run -d -p 80:80 ${ECR_REPO}"
                    """
                }
            }
        }
    }

    post {
        failure {
            echo '❌ Pipeline failed. Check the console output for errors.'
        }
    }
}






