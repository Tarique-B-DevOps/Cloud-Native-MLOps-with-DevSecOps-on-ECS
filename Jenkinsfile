pipeline {
    agent any
    stages {
        stage('Build') {
            when {
                tag "v*"
            }
            steps { 
                echo "Building release for tag: ${env.GIT_TAG}"
            }
        }
    }
}
