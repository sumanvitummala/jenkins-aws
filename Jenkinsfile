pipeline {
    agent any

    environment {
        // AWS & ECR configuration
        AWS_REGION = 'ap-south-1'
        ECR_ACCOUNT_ID = '987686461903'
        ECR_REPO = 'docker-image'
        IMAGE_TAG = '1.0'
        IMAGE_NAME = "${ECR_REPO}:${IMAGE_TAG}"
        FULL_ECR_NAME = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"

        // Terraform configuration
        TERRAFORM_DIR = '.'   // terraform.tf is in repo root

        // EC2 configuration
        EC2_USER = 'ubuntu'
        EC2_HOST = '13.203.66.99'
        SSH_KEY_CREDENTIALS = 'ec2-key' // Jenkins SSH key credential ID
        CONTAINER_NAME = 'web-container'
        CONTAINER_PORT = '80'
    }

    stages {

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                bat "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Tag Docker Image for ECR') {
            steps {
                echo "🏷 Tagging Docker image for ECR..."
                bat "docker tag ${IMAGE_NAME} ${FULL_ECR_NAME}"
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo "🔑 Logging in to AWS ECR..."
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    bat """
                    set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                    set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                echo "📦 Pushing Docker image to AWS ECR..."
                bat "docker push ${FULL_ECR_NAME}"
            }
        }

        stage('Terraform Init') {
            steps {
                echo "⚙ Initializing Terraform..."
                dir("${TERRAFORM_DIR}") {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        bat """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        set PATH=%PATH%;C:/Terraform
                        terraform init
                        """
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                echo "🧩 Running Terraform Plan..."
                dir("${TERRAFORM_DIR}") {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        bat """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        set PATH=%PATH%;C:/Terraform
                        terraform plan
                        """
                    }
                }
            }
        }

        
    
stage('Terraform Apply') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                echo "🚀 Applying Terraform Configuration..."
                dir("${TERRAFORM_DIR}") {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        bat """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        set PATH=%PATH%;C:/Terraform
                        terraform apply -auto-approve
                        for /f "delims=" %%i in ('terraform output -raw instance_public_ip') do set INSTANCE_IP=%%i
                echo %INSTANCE_IP% > instance_ip.txt

                        """
                    }
                }
            }
        }

    stage('Deploy Docker Container on EC2') {
    steps {
        echo "🚀 Deploying Docker container on EC2..."
        script {
            def INSTANCE_IP = readFile('instance_ip.txt').trim()
            echo "✅ EC2 Instance IP: ${INSTANCE_IP}"

            withCredentials([sshUserPrivateKey(
                credentialsId: 'ec2-key',
                keyFileVariable: 'EC2_KEY_PATH',
                usernameVariable: 'EC2_USER'
            )]) {
                bat """
                ssh -o StrictHostKeyChecking=no -i "%EC2_KEY_PATH%" %EC2_USER%@${INSTANCE_IP} "docker stop my-container || true && docker rm my-container || true"
                ssh -i "%EC2_KEY_PATH%" %EC2_USER%@${INSTANCE_IP} "docker run -d --name my-container -p 80:80 987686461903.dkr.ecr.ap-south-1.amazonaws.com/docker-image:1.0"
                """
            }
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




