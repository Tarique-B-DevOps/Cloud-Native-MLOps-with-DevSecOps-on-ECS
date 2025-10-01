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
        AWS_DEFAULT_REGION        = 'ap-south-2'
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud-token')
        IMAGE_LATEST              = "latest"
        IAC_DIR                   = "infrastructure"
        MODEL_VERSION             = "${params.environment_type}-${params.model_version}"
        RESOURCE_PREFIX           = "price-prediction-model"
        JOB_TYPE                  = "${params.destroy ? 'Destroy' : 'Deployement'}"
    }

    stages {

        stage('Notify Start') {
            steps {
                slackSend color: "#FFFF00", message: """
                🔔 ML Model Pipeline Started
                Job Type: ${env.JOB_TYPE}
                Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}console|Open>)
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
                    trivy config --severity HIGH,CRITICAL --format table ${env.IAC_DIR}

                    # Count CRITICAL issues using jq
                    CRITICAL_COUNT=\$(trivy config --severity HIGH,CRITICAL --format json ${env.IAC_DIR} \
                        | jq '[.Results[].Misconfigurations[]? | select(.Severity=="CRITICAL")] | length')

                    echo "⚠️ CRITICAL issues found: \$CRITICAL_COUNT"

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
                script {
                    echo "🔍 Running Terraform plan to detect changes..."
                    
                    // Run terraform plan and capture exit code
                    // 0 = no changes, 1 = error, 2 = changes present
                    def planExitCode = sh(
                        script: "terraform -chdir=$IAC_DIR plan -detailed-exitcode -out=tfplan.out",
                        returnStatus: true
                    )
                    
                    if (planExitCode == 0) {
                        echo "✅ No changes detected. Skipping apply."
                    } else if (planExitCode == 2) {
                        echo "⚠️ Changes detected in Terraform plan."

                        slackSend color: "#FFD700", message: """
                        ⚡  *Approval Required: Terraform Changes Detected*
                        Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}console|Review>)
                        Environment: ${params.environment_type}
                        Model Version: ${env.MODEL_VERSION}
                        """
                        input message: "Approve ML Infrastructure changes?",
                            ok: "✅ Apply Changes",
                            submitter: "tarique"
                    
                        slackSend color: "#32CD32", message: """
                        🚀 *Terraform Changes Approved by Tarique*
                        Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}console|Open>)
                        Environment: ${params.environment_type}
                        Model Version: ${env.MODEL_VERSION}
                        """

                        echo "🔧 Applying Terraform changes..."
                        sh "terraform -chdir=$IAC_DIR apply -auto-approve tfplan.out"
                    } else {
                        error "❌ Terraform plan failed with exit code ${planExitCode}. Check logs."
                    }
                }
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
                echo "Deleting all ECR images for repositories with prefix: $RESOURCE_PREFIX"

                REPOS=\$(aws ecr describe-repositories \
                            --query "repositories[?starts_with(repositoryName, '$RESOURCE_PREFIX')].repositoryName" \
                            --output text)

                for REPO in \$REPOS; do
                    echo "Deleting all images in repository: \$REPO"
                    
                    IMAGES=\$(aws ecr list-images --repository-name \$REPO --query 'imageIds[*]' --output json)
                    
                    if [ "\$IMAGES" != "[]" ]; then
                        aws ecr batch-delete-image --repository-name \$REPO --image-ids "\$IMAGES"
                        echo "Deleted all images in \$REPO"
                    else
                        echo "ℹNo images found in \$REPO"
                    fi
                done

                echo "🔧 Proceeding with Terraform destroy..."
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

                    CURRENT_TASK_DEF_ARN=\$(aws ecs describe-services \
                        --cluster "${env.ECS_CLUSTER_NAME}" \
                        --services "${env.ECS_SERVICE_NAME}" \
                        --query "services[0].taskDefinition" \
                        --output text)

                    aws ecs describe-task-definition --task-definition \$CURRENT_TASK_DEF_ARN \
                    --query "taskDefinition" \
                    | jq 'del(.status,.revision,.taskDefinitionArn,.requiresAttributes,.compatibilities,.registeredAt,.registeredBy)' \
                    > base-task-def.json

                    IMAGE="${env.ECR_REPO_URL}:${env.MODEL_VERSION}"
                    jq --arg IMAGE "\$IMAGE" '.containerDefinitions[0].image=\$IMAGE' base-task-def.json > task-def.json

                    NEW_TASK_DEF_ARN=\$(aws ecs register-task-definition \
                        --cli-input-json file://task-def.json \
                        --query "taskDefinition.taskDefinitionArn" \
                        --output text)

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
                script {
                    echo "🚀 Preparing ECS service update for ML model..."

                    slackSend color: "#FFD700", message: """
                    🛑 *Approval Required: ECS Service Update*
                    Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}console|Review>)
                    Environment: ${params.environment_type}
                    Model Version: ${env.MODEL_VERSION}
                    ECS Service: ${env.ECS_SERVICE_NAME}
                    Cluster: ${env.ECS_CLUSTER_NAME}
                    """

                    input message: "⚡ Approve deployment of ML model version ${env.MODEL_VERSION} to ECS service ${env.ECS_SERVICE_NAME}?",
                        ok: "✅ Deploy Model",
                        submitter: "tarique"

                    slackSend color: "#32CD32", message: """
                    🚀 *Deployment Approved by Tarique*
                    Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}console|Open>)
                    Environment: ${params.environment_type}
                    Deploying model version: ${env.MODEL_VERSION}
                    ECS Service: ${env.ECS_SERVICE_NAME}
                    Cluster: ${env.ECS_CLUSTER_NAME}
                    """

                    echo "🚀 Starting ECS service update for ML model..."
                    sh """
                    set -e

                    aws ecs update-service \
                        --cluster $ECS_CLUSTER_NAME \
                        --service $ECS_SERVICE_NAME \
                        --force-new-deployment

                    aws ecs wait services-stable \
                        --cluster $ECS_CLUSTER_NAME \
                        --services $ECS_SERVICE_NAME

                    echo "✅ ECS service is now stable. All tasks are running the new revision."
                    """
                }
            }
        }


        // use terraform instead of aws cli to update the task def - optional.
        // stage('Deploy with Terraform') {
        //     when {
        //         expression { return !params.destroy }
        //     }
        //     steps {
        //         echo "🔧 Deploying ML model via Terraform using the built image..."
        //         sh """
        //         terraform -chdir=$IAC_DIR apply -auto-approve -var="model_image_uri=${env.ECR_REPO_URL}:${env.MODEL_VERSION}"
        //         """
        //     }
        // }

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
            ✅ ML Model Pipeline Succeeded
            Job Type: ${env.JOB_TYPE}
            Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}console|Open>)
            Environment: ${params.environment_type}
            Model Version: ${env.MODEL_VERSION}
            ECS Service: ${env.ECS_SERVICE_NAME}
            API Endpoint: ${env.API_ENDPOINT}
            ALB DNS: ${env.ALB_DNS}
            """
        }
        failure {
            slackSend failOnError: true, color: "#FF0000", message: """
            ❌ ML Model Pipeline Failed
            Job Type: ${env.JOB_TYPE}
            Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}console/console|Open>)
            Environment: ${params.environment_type}
            Model Version: ${env.MODEL_VERSION}
            Check console logs for details: <${env.BUILD_URL}console|Open>
            """
        }
        unstable {
            slackSend color: "#FFA500", message: """
            ⚠️ ML Model Pipeline Unstable
            Job Type: ${env.JOB_TYPE}
            Job: ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}console|Open>)
            Environment: ${params.environment_type}
            Model Version: ${env.MODEL_VERSION}
            """
        }
        always {
            echo "📌 Pipeline completed. Slack notifications sent."
        }
    }

}
