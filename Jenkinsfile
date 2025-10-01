pipeline {
    agent { label 'AI-ML-RTX-NODE' }

    parameters {
        string(
            name: 'model_version', 
            defaultValue: 'v1.0.0', 
            description: 'Version of the ML model to release'
        )
        choice(
            name: 'environment_type',
            choices: ['staging', 'development', 'production'],
            description: 'Target environment'
        )
        booleanParam(
            name: 'destroy', 
            defaultValue: false, 
            description: 'If checked, only run terraform destroy'
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

        stage('Notify Start') {
            when {
                expression { return !params.destroy }
            }
            steps {
                slackSend color: "#FFFF00", message: """
                🔔 ML Model Deployment Pipeline Started
                Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)
                Environment: ${params.environment_type}
                Model Version: ${env.MODEL_VERSION}
                """
            }
        }

        stage('Terraform Init & Validate') {
            when {
                expression { return !params.destroy }
            }
            steps {
                echo "🔍 Validating Terraform configuration..."
                sh """
                terraform -chdir=$IAC_DIR init
                terraform -chdir=$IAC_DIR validate
                """
            }
        }

        stage('Scan Terraform Config') {
            when {
                expression { return !params.destroy }
            }
            steps {
                script {
                    echo "🔍 Scanning Terraform configuration for HIGH/CRITICAL issues using Trivy..."

                    sh """
                    trivy config --severity HIGH,CRITICAL --format table .

                    # Count CRITICAL issues using jq
                    CRITICAL_COUNT=\$(trivy config --severity HIGH,CRITICAL --format json . \
                        | jq '[.Results[].Misconfigurations[]? | select(.Severity=="CRITICAL")] | length')

                    echo "⚠️ CRITICAL issues found: \$CRITICAL_COUNT"

                    # Fail pipeline if more than 5
                    if [ "\$CRITICAL_COUNT" -gt 5 ]; then
                        echo "Too many CRITICAL issues (>5). Failing pipeline."
                        exit 1
                    fi
                    """
                }
            }
        }

        stage('Provision ML Infrastructure') {
            when {
                expression { return !params.destroy }
            }
            steps {
                echo "🔧 Initializing and applying Terraform for ML infra..."
                sh """
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

        stage('Snyk Code Scan') {
            when {
                expression { return !params.destroy }
            }
            steps {
                withCredentials([string(credentialsId: 'snyk_token', variable: 'SNYK_TOKEN')]) {
                    sh """
                    echo "🔍 Running Snyk Code scan..."
                    snyk code test --severity-threshold=high
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
                    python3 -m venv /tmp/venv
                    source /tmp/venv/bin/activate

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

        stage('Scan Container Image') {
            when {
                expression { return !params.destroy }
            }
            steps {
                echo "🔍 Scanning ML model Docker image for vulnerabilities..."
                sh """
                # Scan Docker image with Trivy
                VULN_COUNT=\$(trivy image --severity HIGH,CRITICAL --format json $ECR_REPO_URL:$MODEL_VERSION \
                    | jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length')

                echo "⚠️ Number of CRITICAL vulnerabilities found: \$VULN_COUNT"

                if [ "\$VULN_COUNT" -gt 5 ]; then
                    echo "Container image has CRITICAL vulnerabilities. Failing pipeline."
                    exit 1
                fi
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
                script {
                    echo "📝 Registering new ECS task definition with updated ML model image..."

                    sh """
                    set -e

                    echo "Fetching current task definition ARN..."
                    CURRENT_TASK_DEF_ARN=\$(aws ecs describe-services \
                        --cluster "${env.ECS_CLUSTER_NAME}" \
                        --services "${env.ECS_SERVICE_NAME}" \
                        --query "services[0].taskDefinition" \
                        --output text)

                    echo "Downloading current task definition JSON..."
                    aws ecs describe-task-definition --task-definition \$CURRENT_TASK_DEF_ARN \
                    --query "taskDefinition" \
                    | jq 'del(.status,.revision,.taskDefinitionArn,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)' \
                    > base-task-def.json

                    echo "Updating container image with model version ${env.MODEL_VERSION} ..."
                    IMAGE="${env.ECR_REPO_URL}:${env.MODEL_VERSION}"
                    jq --arg IMAGE "\$IMAGE" '.containerDefinitions[0].image=\$IMAGE' base-task-def.json > task-def.json

                    echo "Registering new task definition revision..."
                    NEW_TASK_DEF_ARN=\$(aws ecs register-task-definition \
                        --cli-input-json file://task-def.json \
                        --query "taskDefinition.taskDefinitionArn" \
                        --output text)

                    echo "Registered new task definition: \$NEW_TASK_DEF_ARN"

                    echo "Updating ECS service to use new revision..."
                    aws ecs update-service \
                        --cluster "${env.ECS_CLUSTER_NAME}" \
                        --service "${env.ECS_SERVICE_NAME}" \
                        --task-definition \$NEW_TASK_DEF_ARN
                    """
                }
            }
        }

        stage('Update Model Service on ECS') {
            when {
                expression { return !params.destroy }
            }
            steps {
                echo "🚀 Starting ECS service update for ML model..."

                sh """
                set -e

                echo "🔹 Triggering new deployment for service: $ECS_SERVICE_NAME on cluster: $ECS_CLUSTER_NAME"
                aws ecs update-service \
                    --cluster $ECS_CLUSTER_NAME \
                    --service $ECS_SERVICE_NAME \
                    --force-new-deployment

                echo "⏳ Deployment triggered. Waiting for ECS service to become stable..."
                aws ecs wait services-stable \
                    --cluster $ECS_CLUSTER_NAME \
                    --services $ECS_SERVICE_NAME

                echo "✅ ECS service is now stable. All tasks are running the new revision."
                echo "🎉 ML model deployment successfully rolled out!"
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

    post {
        success {
            slackSend color: "#00FF00", message: """
            ✅ ML Model Deployment Pipeline Succeeded
            Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)
            Environment: ${params.environment_type}
            Model Version: ${env.MODEL_VERSION}
            ECS Service: ${env.ECS_SERVICE_NAME}
            API Endpoint: ${env.API_ENDPOINT}
            ALB DNS: ${env.ALB_DNS}
            """
        }
        failure {
            slackSend failOnError: true, color: "#FF0000", message: """
            ❌ ML Model Deployment Pipeline Failed
            Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)
            Environment: ${params.environment_type}
            Model Version: ${env.MODEL_VERSION}
            Check console logs for details: <${env.BUILD_URL}|Open>
            """
        }
        unstable {
            slackSend color: "#FFA500", message: """
            ⚠️ ML Model Deployment Pipeline Unstable
            Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)
            Environment: ${params.environment_type}
            Model Version: ${env.MODEL_VERSION}
            """
        }
        always {
            echo "📌 Pipeline completed. Slack notifications sent."
        }
    }

}
