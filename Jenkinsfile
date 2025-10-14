pipeline {
    agent any
    stages {
        stage('Build Docker Image') {
            steps {
                // This uses Dockerfile in the same folder
                bat 'docker build -t myhtml-image:1.0 .'
            }
        }
        stage('Run Docker Container') {
            steps {
                // Stop and remove previous container if exists
                bat 'docker stop myhtml-container || exit 0'
                bat 'docker rm myhtml-container || exit 0'
                // Run container
                bat 'docker run -d -p 8081:80 --name myhtml-container myhtml-image:1.0'
            }
        }
    }
}
