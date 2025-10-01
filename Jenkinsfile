pipeline {
    agent { label 'AI-ML-RTX-NODE' }

    parameters {
        string(
            name: 'model_version', 
            defaultValue: 'v1.0.0', 
            description: 'Version of the ML model to release'
        )
        booleanParam(
            name: 'destroy', 
            defaultValue: false, 
            description: 'If checked, only run terraform destroy'
        )
        choice(
            name: 'environment_type',
            choices: ['staging', 'development', 'production'],
            description: 'Target environment'
        )
    }

    environment {
        AWS_ACCESS_KEY_ID         = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY     = credentials('aws-secret-key')
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud-token')
        IMAGE_LATEST              = "latest"
        IAC_DIR                   = "infrastructure"
        MODEL_VERSION             = "${params.environment_type}-${params.model_version}"
    }

    stages {

        stage('Terraform Destroy') {
            when {
                expression { return params.destroy }
            }
            steps {
                echo "⚠️ Destroy parameter is checked. Running terraform destroy..."
                sh """
                terraform -chdir=$IAC_DIR init
                terraform -chdir=$IAC_DIR destroy -auto-approve
                """
            }
        }

        stage('Provision ML Infrastructure') {
            when {
                expression { return !params.destroy }
            }
            steps {
                echo "🔧 Initializing and applying Terraform for ML infra..."
                sh """
                terraform -chdir=$IAC_DIR init
                terraform -chdir=$IAC_DIR apply -auto-approve
                """
            }
        }

        stage('Extract Infra Outputs') {
            when {
                expression { return !params.destroy }
            }
            steps {
                echo "📦 Extracting ML infrastructure outputs..."
                script {
                    env.AWS_REGION       = sh(script: "terraform -chdir=$IAC_DIR output -raw region", returnStdout: true).trim()
                    env.ALB_DNS          = sh(script: "terraform -chdir=$IAC_DIR output -raw alb_dns", returnStdout: true).trim()
                    env.API_ENDPOINT     = sh(script: "terraform -chdir=$IAC_DIR output -raw api_endpoint", returnStdout: true).trim()
                    env.ECR_REPO_URL     = sh(script: "terraform -chdir=$IAC_DIR output -raw ecr_repo_url", returnStdout: true).trim()
                    env.ECS_CLUSTER_NAME = sh(script: "terraform -chdir=$IAC_DIR output -raw ecs_cluster_name", returnStdout: true).trim()
                    env.ECS_SERVICE_NAME = sh(script: "terraform -chdir=$IAC_DIR output -raw ecs_service_name", returnStdout: true).trim()

                    echo """
                    📦 Extracted Terraform Outputs:
                    AWS_REGION       = ${env.AWS_REGION}
                    ALB_DNS          = ${env.ALB_DNS}
                    API_ENDPOINT     = ${env.API_ENDPOINT}
                    ECR_REPO_URL     = ${env.ECR_REPO_URL}
                    ECS_CLUSTER_NAME = ${env.ECS_CLUSTER_NAME}
                    ECS_SERVICE_NAME = ${env.ECS_SERVICE_NAME}
                    """
                }
            }
        }

        stage('Train ML Model') {
            when {
                expression { return !params.destroy }
            }
            steps {
                script {
                    echo "📊 Training the house price prediction model..."
                    sh """
                    python3 -m venv venv
                    source venv/bin/activate

                    pip install --upgrade pip
                    pip install -r requirements.txt

                    python3 train.py
                    """
                }
            }
        }

        stage('Containerize Model Service') {
            when {
                expression { return !params.destroy }
            }
            steps {
                echo "🐳 Building ML model inference service container..."
                sh """
                
                aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin $ECR_REPO_URL

                echo "Building Docker image for ML model version $MODEL_VERSION ..."
                docker build -t $ECR_REPO_URL:$MODEL_VERSION -t $ECR_REPO_URL:$IMAGE_LATEST .
                """
            }
        }

        stage('Publish Model Image') {
            when {
                expression { return !params.destroy }
            }
            steps {
                echo "📤 Publishing ML model container images to ECR..."
                sh """
                docker push $ECR_REPO_URL:$MODEL_VERSION
                docker push $ECR_REPO_URL:$IMAGE_LATEST
                """
            }
        }

        stage('Register Updated Task Definition') {
            when {
                expression { return !params.destroy }
            }
            steps {
                echo "📝 Registering new ECS task definition with updated ML model image..."
                sh '''
                set -e

                echo "Fetching current task definition ARN..."
                CURRENT_TASK_DEF_ARN=$(aws ecs describe-services \
                    --cluster $ECS_CLUSTER_NAME \
                    --services $ECS_SERVICE_NAME \
                    --query "services[0].taskDefinition" \
                    --output text)

                echo "Downloading current task definition JSON..."
                aws ecs describe-task-definition --task-definition $CURRENT_TASK_DEF_ARN \
                --query "taskDefinition" \
                | jq "del(.status,.revision,.taskDefinitionArn,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)" \
                > base-task-def.json

                echo "Updating container image with model version $MODEL_VERSION ..."
                jq --arg IMAGE "$ECR_REPO_URL:$MODEL_VERSION" \
                ".containerDefinitions[0].image=\\$IMAGE" base-task-def.json > task-def.json

                echo "Registering new task definition revision..."
                NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
                    --cli-input-json file://task-def.json \
                    --query "taskDefinition.taskDefinitionArn" \
                    --output text)

                echo "Registered new task definition: $NEW_TASK_DEF_ARN"

                echo "Updating ECS service to use new revision..."
                aws ecs update-service \
                --cluster $ECS_CLUSTER_NAME \
                --service $ECS_SERVICE_NAME \
                --task-definition $NEW_TASK_DEF_ARN
                '''
            }
        }

        stage('Update Model Service on ECS') {
            when {
                expression { return !params.destroy }
            }
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
            when {
                expression { return !params.destroy }
            }
            steps {
                echo "✅ ML model successfully deployed and serving!"
                echo "Inference ALB DNS: $ALB_DNS"
                echo "API Gateway Endpoint: $API_ENDPOINT"
            }
        }
    }
}
