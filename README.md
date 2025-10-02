# 🛠️ End-to-End MLOps Pipeline

This repository demonstrates a **complete MLOps pipeline** that takes a machine learning model from training to production deployment on AWS, using **Jenkins**, **Terraform**, and **Docker**.

It encapsulates **DevSecOps + ML lifecycle automation**, including: infrastructure provisioning, training, testing, security scanning, containerization, deployment, and monitoring.


## 📌 Overview

* **Pipeline as Code**: Implemented using a Jenkins declarative pipeline.
* **Infrastructure Automation**:

  * Uses **Terraform** to provision and update ML infrastructure on AWS.
  * Supports both **deployment** and **destruction** of resources.
* **Secure by Design**:

  * **Trivy** scans Terraform configs and container images.
  * **Snyk** performs code security scans.
  * Pipeline enforces approval gates when critical vulnerabilities or infra changes are detected.
* **Model Lifecycle**:

  * Trains a **house price prediction model** with scikit-learn.
  * Runs **unit tests** (pytest) before containerization.
  * Builds, scans, and publishes **Docker images** to AWS ECR.
* **Continuous Delivery to AWS ECS**:

  * Deploys model inference service as ECS tasks behind an ALB.
  * Supports rolling updates with approval gates.
* **Notifications**:

  * **Slack integration** for start, success, failure, unstable builds, and approvals.
* **Multi-Environment Ready**:

  * Configurable for `dev`, `staging`, or `prod`.
  * Dynamically sets AWS region, task counts, and model versions per environment.


## ⚙️ Tech Stack

* **Infrastructure as Code (IaC)**: Terraform
* **CI/CD Orchestration**: Jenkins Pipeline (declarative)
* **Cloud Provider**: AWS

  * ECS (Elastic Container Service)
  * ECR (Elastic Container Registry)
  * ALB (Application Load Balancer)
  * API Gateway
  * IAM for security and access control
* **Containerization**: Docker
* **Machine Learning**: Python, scikit-learn
* **Testing**: Pytest
* **Security & Compliance**:

  * **Snyk** → Code security scan
  * **Trivy** → Terraform and container image scan
* **Observability & Notifications**: Slack integration


## 🤖 Model Details

This repository implements a **House Price Prediction** model trained on synthetic data. The model is packaged, versioned, and deployed as a REST API.

### 📊 Dataset

* The dataset is synthetically generated with the following features:

  * **Size**: House size in square feet (500–5000).
  * **Bedrooms**: Number of bedrooms (1–5).
  * **Age**: Age of the house in years (0–50).
* **Target Variable**: House price, calculated as:

  ```
  price = (size * 300) + (bedrooms * 10000) - (age * 500) + noise
  ```

  where `noise` is Gaussian noise with mean `0` and std deviation `50,000`.

### 🧠 Model Training

* Algorithm: **Linear Regression** (from scikit-learn).
* Data Split: **80/20** train-test split.
* Metrics evaluated:

  * **Mean Squared Error (MSE)**
  * **R² Score**
* The trained model is serialized and saved as:

  ```
  models/house_price_model-latest.pkl
  ```

### 🚀 Inference Service

* Framework: **FastAPI** (with CORS middleware enabled).
* Endpoints:

  * `GET /` → Welcome + status.
  * `POST /predict` → Predict house price given features (`Size`, `Bedrooms`, `Age`).
  * `GET /health` → Health check endpoint.
  * `GET /version` → Returns the deployed **model version** (from environment variable).
* Input validation: **Pydantic** schema (`House` class).
* Returns a rounded prediction in JSON:

  ```json
  {
    "predicted_price": 450123.45
  }
  ```

### 🔖 Model Versioning

* Models are versioned and tagged during CI/CD:

  * Naming convention → `<environment>-<version>` (e.g., `prod-v1.0.0`).
* Docker images are pushed to AWS ECR with two tags:

  * **Specific version** (e.g., `prod-v1.0.0`).
  * **latest** (always points to the newest build).



## Pipeline Detail

## 🧩 Pipeline Parameters

The Jenkins pipeline is parameterized for flexible deployments:

| Parameter                | Type                              | Default      | Description                                              |
| ------------------------ | --------------------------------- | ------------ | -------------------------------------------------------- |
| `model_version`          | String                            | `v1.0.0`     | Version of the ML model to release                       |
| `environment_type`       | Choice (`dev`, `staging`, `prod`) | `dev`        | Target environment for deployment                        |
| `aws_region`             | String                            | `ap-south-2` | AWS region to deploy resources in                        |
| `ecs_desired_task_count` | String                            | `3`          | Number of ECS tasks to run for the service               |
| `destroy`                | Boolean                           | `false`      | If checked, runs Terraform destroy instead of deployment |


Example Usage:

- Deploy
```bash
curl -X POST \
  "$JENKINS_URL/job/MLOps-Prediction-Model-ECS-Staging-v1/buildWithParameters" \
  --user "$JENKINS_USER_ID:$JENKINS_API_TOKEN" \
  --data "model_version=v1.0.0&environment_type=prod&aws_region=ap-south-1&ecs_desired_task_count=1"
```
- Destroy
```bash
curl -X POST \
  "$JENKINS_URL/job/MLOps-Prediction-Model-ECS-Staging-v1/buildWithParameters" \
  --user "$JENKINS_USER_ID:$JENKINS_API_TOKEN" \
  --data "destroy=true"
```



### 🔔 Notify Start

* Sends a Slack notification when the pipeline begins with job details, environment, and model version.

### 🌍 Terraform Init & Validate

* Initializes and validates Terraform configurations in the `infrastructure` directory.

### 🔧 Provision ML Infrastructure

* Deploys the following AWS resources via Terraform using files in the `infrastructure` directory:

  * **ECS Cluster & Service** (`ecs.tf`)
  * **ECR Repositories** for storing model images (`ecr.tf`)
  * **Application Load Balancer (ALB)** for serving traffic (`alb.tf`)
  * **API Gateway** for exposing endpoints (`api-gw.tf`)
  * **IAM Roles & Policies** for ECS and API permissions (`iam.tf`)
  * **Security Groups** (`sg.tf`)
  * **Backend & Terraform state config** (`backend.tf`)
  * **Local variables, main config, and outputs** (`locals.tf`, `main.tf`, `outputs.tf`)
  * **Values for environment-specific variables** (`values.auto.tfvars`)
* Requests approval if infrastructure changes are detected.

### 📦 Extract Infra Outputs

* Captures Terraform outputs such as:

  * `API_ENDPOINT`
  * `ALB_DNS`
  * `ECR_REPO_URL`
  * `ECS_CLUSTER_NAME`

### ⚠️ Terraform Destroy

* Allows **safe teardown** of ML infrastructure.
* Includes an approval gate before deleting all AWS resources and ECR images.

### 🛡️ Snyk Code Scan

* Performs static code analysis with **Snyk**.

### 📊 Train ML Model

* Creates a Python virtual environment.
* Installs dependencies.
* Trains the **house price prediction model**.

### 🧪 Run ML Service Tests

* Executes **pytest** on the ML codebase.
* Ensures correctness before moving forward.

### 🐳 Containerize Model Service

* Builds a Docker image for the ML inference service.
* Tags with both **model version** and `latest`.

### 🔍 Scan Container Image

* Uses **Trivy** to scan Docker image for vulnerabilities.
* Pipeline fails if >5 **CRITICAL** issues found.

### 📤 Publish Model Image

* Pushes Docker images to **AWS ECR**.

### 📝 Register Updated Task Definition

* Updates ECS Task Definition with the new model container image.

### 🚀 Update Model Service on ECS

* Requests **manual approval** to deploy the new model.
* Performs ECS rolling update.
* Waits until the service is stable.

### 🌐 Expose Serving Endpoints

* Provides inference endpoints:

  * Application Load Balancer (ALB) DNS
  * API Gateway Endpoint


## 🚨 Post-Pipeline Notifications

* **✅ Success** → Sends Slack notification with API endpoints and deployment details.
* **❌ Failure** → Sends Slack alert with job link for debugging.


## Deployment & Testing

<img width="1893" height="896" alt="Image" src="https://github.com/user-attachments/assets/7eb614fc-4c01-4fb6-9a0f-ac0cfa507008" />

<img width="1905" height="898" alt="Image" src="https://github.com/user-attachments/assets/9c3ab26d-77a7-487d-8b75-f824ba80f317" />

<img width="1891" height="899" alt="Image" src="https://github.com/user-attachments/assets/84d9bfbb-d3f6-4a8f-ab68-2af15aab5277" />

<img width="1681" height="410" alt="Image" src="https://github.com/user-attachments/assets/9cfee17f-145e-4ca6-bc19-f16e6f648e66" />

<img width="1880" height="953" alt="Image" src="https://github.com/user-attachments/assets/2813777c-3e96-4648-bb6a-a1baa9f2a5b4" />

<img width="1887" height="942" alt="Image" src="https://github.com/user-attachments/assets/ec367519-b430-46d6-87c4-a498ae306924" />

<img width="1500" height="372" alt="Image" src="https://github.com/user-attachments/assets/62aa73ee-d413-45a6-98f1-9038eaaa726d" />

<img width="1660" height="976" alt="Image" src="https://github.com/user-attachments/assets/0debbc7d-f590-4c33-9016-99b0d146a741" />

<img width="1103" height="885" alt="Image" src="https://github.com/user-attachments/assets/16ea0065-7b18-44a1-9d6d-31c57e564ae1" />