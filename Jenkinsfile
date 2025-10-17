pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_ACCOUNT_ID = '987686461903'
        ECR_REPO = 'docker-image'
        IMAGE_TAG = '1.0'
        IMAGE_NAME = "${ECR_REPO}:${IMAGE_TAG}"
        FULL_ECR_NAME = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"

        TERRAFORM_DIR = '.'

        EC2_USER = 'ec2-user'
        SSH_KEY_PATH = 'C:\\Users\\AppuSummi\\.ssh\\sumanvi-key.pem'
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

        stage('Terraform Apply') {
            steps {
                echo "🚀 Applying Terraform..."
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
                echo "🚀 Deploying Docker container on EC2..."
                script {
                    def instanceIp = readFile('instance_ip.txt').trim()
                    echo "✅ EC2 Elastic IP: ${instanceIp}"

                    powershell """
                    echo '🔹 Connecting to EC2 instance...'
                    ssh -o StrictHostKeyChecking=no -i "${SSH_KEY_PATH}" ec2-user@${instanceIp} '
                        if ! command -v docker >/dev/null 2>&1; then
                            echo "Installing Docker..."
                            sudo yum install -y docker
                            sudo systemctl start docker
                            sudo systemctl enable docker
                            sudo usermod -aG docker ec2-user
                        fi

                        echo "🛠 Pulling image from ECR..."
                        aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 987686461903.dkr.ecr.ap-south-1.amazonaws.com

                        docker stop ${CONTAINER_NAME} || true
                        docker rm ${CONTAINER_NAME} || true

                        docker run -d --name ${CONTAINER_NAME} -p 80:80 ${FULL_ECR_NAME}

                        echo "🚀 Container started successfully!"
                    '
                    """
                }
            }
        }
    }

    post {
        success { echo "✅ Pipeline completed successfully!" }
        failure { echo "❌ Pipeline failed. Check console output." }
    }
}








