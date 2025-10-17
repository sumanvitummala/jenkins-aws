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
        EC2_USER = 'ec2-user'  // make sure this is correct for your AMI
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

        stage('Terraform Apply & Wait for EC2') {
    steps {
        echo "🚀 Applying Terraform configuration..."
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
                terraform apply -auto-approve
                terraform output -raw instance_public_ip > instance_ip.txt
                """
            }
        }
    }
}

stage('Deploy Docker Container on EC2') {
    steps {
        script {
            def instanceIp = readFile('instance_ip.txt').trim()
            echo "✅ EC2 Instance IP: ${instanceIp}"

            // Wait until SSH port 22 is reachable
            echo "⏳ Waiting for EC2 to be reachable on SSH..."
            timeout(time: 5, unit: 'MINUTES') {
                waitUntil {
                    def reachable = sh(
                        script: "ssh -o StrictHostKeyChecking=no -i C:\\Users\\AppuSummi\\.ssh\\sumanvi-key.pem ec2-user@${instanceIp} 'echo OK'",
                        returnStatus: true
                    )
                    return (reachable == 0)
                }
            }

            // Deploy Docker container
            echo "🚀 Deploying Docker container..."
            sh """
            ssh -o StrictHostKeyChecking=no -i C:\\Users\\AppuSummi\\.ssh\\sumanvi-key.pem ec2-user@${instanceIp} '
                # Install Docker if not installed
                if ! command -v docker >/dev/null 2>&1; then
                    sudo yum install -y docker
                    sudo systemctl start docker
                    sudo systemctl enable docker
                    sudo usermod -aG docker ec2-user
                fi

                # Login to ECR and run container
                aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 987686461903.dkr.ecr.ap-south-1.amazonaws.com
                docker stop web-container || true
                docker rm web-container || true
                docker run -d --name web-container -p 80:80 987686461903.dkr.ecr.ap-south-1.amazonaws.com/docker-image:1.0
            '
            """
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


