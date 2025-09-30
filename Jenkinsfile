pipeline {
    agent { label 'AI-ML-RTX-NODE' }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        GIT_TAG               = "${env.GIT_TAG}"
        IMAGE_TAG             = "${GIT_TAG}"
        IMAGE_LATEST          = "latest"
        IAC_DIR               = "infrastructure"
    }

    when {
        tag "v*"
    }

    stages {

        stage('Provision ML Infrastructure') {

            stage('Initialize IaC Backend') {
                steps {
                    echo "🔧 Initializing Terraform backend for ML infrastructure..."
                    sh "terraform -chdir=$IAC_DIR init"
                }
            }

            stage('Apply IaC Configurations') {
                steps {
                    echo "🚀 Provisioning ML infrastructure with Terraform..."
                    sh "terraform -chdir=$IAC_DIR apply -auto-approve"
                }
            }

            stage('Extract Infra Outputs') {
                steps {
                    echo "📦 Extracting ML infrastructure outputs..."
                    script {
                        env.AWS_REGION       = sh(script: "terraform -chdir=$IAC_DIR output -raw region", returnStdout: true).trim()
                        env.ALB_DNS          = sh(script: "terraform -chdir=$IAC_DIR output -raw alb_dns", returnStdout: true).trim()
                        env.API_ENDPOINT     = sh(script: "terraform -chdir=$IAC_DIR output -raw api_endpoint", returnStdout: true).trim()
                        env.ECR_REPO_URL     = sh(script: "terraform -chdir=$IAC_DIR output -raw ecr_repo_url", returnStdout: true).trim()
                        env.ECS_CLUSTER_NAME = sh(script: "terraform -chdir=$IAC_DIR output -raw ecs_cluster_name", returnStdout: true).trim()
                        env.ECS_SERVICE_NAME = sh(script: "terraform -chdir=$IAC_DIR output -raw ecs_service_name", returnStdout: true).trim()
                    }
                }
            }
        }

        stage('Model Training & Packaging') {

            stage('Train ML Model') {
                steps {
                    echo "📊 Running training pipeline for the house price prediction model..."
                    sh "python train.py"
                }
            }

            stage('Containerize Model Service') {
                steps {
                    echo "🐳 Building ML model inference service container..."
                    sh """
                    aws ecr get-login-password --region $AWS_REGION | \
                        docker login --username AWS --password-stdin $ECR_REPO_URL

                    docker build -t $ECR_REPO_URL:$IMAGE_TAG -t $ECR_REPO_URL:$IMAGE_LATEST .
                    """
                }
            }

            stage('Publish Model Image') {
                steps {
                    echo "📤 Publishing ML model container images to ECR..."
                    sh """
                    docker push $ECR_REPO_URL:$IMAGE_TAG
                    docker push $ECR_REPO_URL:$IMAGE_LATEST
                    """
                }
            }
        }

        stage('Model Deployment & Serving') {

            stage('Register Updated Task Definition') {
                steps {
                    echo "📝 Registering new ECS task definition with updated ML model image..."
                    sh """
                    TASK_DEF_JSON=\$(aws ecs describe-task-definition --task-definition $ECS_SERVICE_NAME)
                    NEW_TASK_DEF=\$(echo \$TASK_DEF_JSON | jq --arg IMAGE "$ECR_REPO_URL:$IMAGE_TAG" '.taskDefinition.containerDefinitions[0].image=$IMAGE')
                    echo \$NEW_TASK_DEF > task-def.json
                    aws ecs register-task-definition --cli-input-json file://task-def.json
                    """
                }
            }

            stage('Update Model Service on ECS') {
                steps {
                    echo "🚀 Rolling out new ML model version to ECS service..."
                    sh """
                    aws ecs update-service \
                        --cluster $ECS_CLUSTER_NAME \
                        --service $ECS_SERVICE_NAME \
                        --force-new-deployment
                    """
                }
            }

            stage('Expose Serving Endpoints') {
                steps {
                    echo "✅ ML model successfully deployed and serving!"
                    echo "Inference ALB DNS: $ALB_DNS"
                    echo "API Gateway Endpoint: $API_ENDPOINT"
                }
            }

        }

    }
}
