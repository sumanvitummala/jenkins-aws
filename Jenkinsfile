pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = 'docker-image'
        IMAGE_TAG = '1.0'
        TF_VAR_key_name = 'jenkins-key'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                echo '🧹 Cleaning old workspace...'
                deleteDir()
                // ✅ Re-clone repo after cleaning
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo '🐳 Building Docker image...'
                    if (fileExists('Dockerfile')) {
                        bat 'docker build -t docker-image:1.0 .'
                    } else {
                        error("❌ Dockerfile not found! Make sure it exists in your repository root.")
                    }
                }
            }
        }

        stage('Tag Docker Image for ECR') {
            steps {
                echo '🏷️ Tagging Docker image for ECR...'
                bat 'docker tag docker-image:1.0 %ECR_REPO%:1.0'
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo '🔑 Logging into AWS ECR...'
                bat 'aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REPO%'
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                echo '📦 Pushing Docker image to ECR...'
                bat 'docker push %ECR_REPO%:1.0'
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    echo '🌍 Running Terraform Apply...'
                    try {
                        bat '''
                            cd terraform
                            terraform init -input=false
                            terraform apply -auto-approve -input=false
                        '''
                    } catch (err) {
                        echo "⚠️ Terraform Apply failed: ${err}"
                        error("Terraform failed. Please check AWS IAM permissions (ec2:AllocateAddress, etc.)")
                    }
                }
            }
        }

        stage('Deploy Docker Container on EC2') {
            steps {
                script {
                    echo '🚀 Deploying Docker container on EC2...'
                    def ipFile = "terraform/instance_ip.txt"
                    def ec2Ip = ""

                    // Try reading IP from Terraform output file
                    if (fileExists(ipFile)) {
                        ec2Ip = readFile(ipFile).trim()
                    } else {
                        try {
                            ec2Ip = bat(script: 'cd terraform && terraform output -raw instance_public_ip', returnStdout: true).trim()
                        } catch (e) {
                            echo "⚠️ Could not read instance_public_ip from Terraform."
                        }
                    }

                    if (!ec2Ip) {
                        error("❌ No EC2 IP found! Check Terraform output or IAM permissions.")
                    }

                    echo "✅ EC2 Elastic IP: ${ec2Ip}"

                    // Try SSH only if IP found
                    try {
                        bat """
                            echo 🔹 Connecting to EC2 instance...
                            ssh -o StrictHostKeyChecking=no ec2-user@${ec2Ip} "docker run -d -p 80:80 %ECR_REPO%:1.0"
                        """
                    } catch (e) {
                        echo "⚠️ SSH Connection failed: ${e}"
                        error("Could not connect to EC2 instance at ${ec2Ip}")
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment Successful!'
        }
        failure {
            echo '❌ Pipeline failed. Check console output for details.'
        }
    }
}


