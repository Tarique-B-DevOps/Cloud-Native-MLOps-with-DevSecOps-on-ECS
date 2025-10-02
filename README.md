# 🛠️ End-to-End MLOps Pipeline

This repository demonstrates a **complete MLOps pipeline** that takes a machine learning model from training to production deployment on AWS, including a **frontend**. It uses **Jenkins**, **Terraform**, and **Docker**.

It encapsulates **DevSecOps + ML lifecycle automation**, including: infrastructure provisioning, training, testing, security scanning, containerization, deployment, frontend build & deployment, and monitoring.

<video width="640" height="360" controls>
  <source src="https://github.com/user-attachments/assets/735177ba-205e-4373-ba20-fe1481095872" type="video/mp4">
  Your browser does not support the video tag.
</video>

[Click here to watch the video in a new tab](https://github.com/user-attachments/assets/735177ba-205e-4373-ba20-fe1481095872)


## 📌 Overview

* **Pipeline as Code**: Implemented using a Jenkins declarative pipeline.
* **Infrastructure Automation**:

  * Uses **Terraform** to provision and update ML and frontend infrastructure on AWS.
  * Supports both **deployment** and **destruction** of resources.
* **Secure by Design**:

  * **Trivy** scans Terraform configs and container images.
  * **Snyk** performs code security scans.
  * Pipeline enforces approval gates when critical vulnerabilities or infra changes are detected.
* **Model Lifecycle**:

  * Trains a **house price prediction model** with scikit-learn.
  * Runs **unit tests** (pytest) before containerization.
  * Builds, scans, and publishes **Docker images** to AWS ECR.
* **Frontend Lifecycle**:

  * Builds frontend (Vite/React) with environment-specific API URLs.
  * Deploys frontend build to **S3 bucket** (optionally CloudFront distribution).
* **Continuous Delivery to AWS ECS**:

  * Deploys ML inference service as ECS tasks behind an ALB.
  * Supports rolling updates with approval gates.
* **Notifications**:

  * **Slack integration** for start, success, failure, unstable builds, and approvals.
* **Multi-Environment Ready**:

  * Configurable for `dev`, `staging`, or `prod`.
  * Dynamically sets AWS region, task counts, model versions, and frontend version per environment.


## ⚙️ Tech Stack

* **Infrastructure as Code (IaC)**: Terraform
* **CI/CD Orchestration**: Jenkins Pipeline (declarative)
* **Cloud Provider**: AWS

  * ECS (Elastic Container Service)
  * ECR (Elastic Container Registry)
  * ALB (Application Load Balancer)
  * API Gateway
  * S3 Bucket / CloudFront for frontend
  * IAM for security and access control
* **Containerization**: Docker
* **Machine Learning**: Python, scikit-learn
* **Frontend**: React / Vite
* **Testing**: Pytest
* **Security & Compliance**:

  * **Snyk** → Code security scan
  * **Trivy** → Terraform and container image scan
* **Observability & Notifications**: Slack integration


## 🤖 Model Details

This repository implements a **House Price Prediction** model trained on synthetic data. The model is packaged, versioned, and deployed as a REST API.

### 📊 Dataset

* Synthetic dataset with features:

  * **Size**: House size in square feet (500–5000)
  * **Bedrooms**: Number of bedrooms (1–5)
  * **Age**: Age of the house (0–50 years)
* **Target Variable**: House price

```python
price = (size * 300) + (bedrooms * 10000) - (age * 500) + noise
```

* Gaussian noise added (`mean=0`, `std=50,000`)

### 🧠 Model Training

* Algorithm: **Linear Regression**
* Train/Test Split: 80/20
* Metrics:

  * **Mean Squared Error (MSE)**
  * **R² Score**
* Serialized model location:

```text
models/house_price_model-latest.pkl
```

### 🚀 Inference Service

* Framework: **FastAPI**
* Endpoints:

  * `GET /` → Welcome + status
  * `POST /predict` → Predict house price given `Size`, `Bedrooms`, `Age`
  * `GET /health` → Health check
  * `GET /version` → Deployed **model version**
* Input validation: **Pydantic** (`House` class)
* JSON response example:

```json
{
  "predicted_price": 450123.45
}
```

### 🔖 Model & Frontend Versioning

* Model & frontend versions combined as `<environment>-<version>` (e.g., `prod-v1.0.0`)
* Docker images pushed to **AWS ECR**:

  * Specific version (e.g., `prod-v1.0.0`)
  * `latest` (points to newest build)
* Frontend deployed to **S3 bucket** (`FRONTEND_URL`)


## 🖥️ Frontend Details

The pipeline includes a **simple, dynamic frontend application** that provides a user-friendly interface to the deployed ML model. Key features:

* **Dynamic API Integration**: During the build process, the frontend automatically consumes the **API Gateway endpoint** of the deployed model, ensuring it always communicates with the correct backend version.
* **Predict House Prices**: Users can input house features (Size, Bedrooms, Age) and receive real-time predictions from the ML model.
* **Version Tracking**: Displays both **model** and **frontend version**, providing clear visibility and traceability of each deployment.
* **Deployment via CloudFront**: The built frontend is deployed to an **S3 bucket** and served globally through **CloudFront**, ensuring fast, reliable access across environments.

This ensures every pipeline run delivers a **fully operational end-to-end ML service**, with frontend, backend, and model versions fully synchronized and observable.



## Pipeline Parameters

| Parameter                | Type                              | Default      | Description                                              |
| ------------------------ | --------------------------------- | ------------ | -------------------------------------------------------- |
| `model_version`          | String                            | `v1.0.0`     | Version of the ML model to release                       |
| `environment_type`       | Choice (`dev`, `staging`, `prod`) | `dev`        | Target environment for deployment                        |
| `aws_region`             | String                            | `ap-south-2` | AWS region to deploy resources in                        |
| `ecs_desired_task_count` | String                            | `3`          | Number of ECS tasks to run for the service               |
| `destroy`                | Boolean                           | `false`      | If checked, runs Terraform destroy instead of deployment |

Example usage:

* Deploy:

```bash
curl -X POST \
  "$JENKINS_URL/job/MLOps-Prediction-Model-FullStack/buildWithParameters" \
  --user "$JENKINS_USER:$JENKINS_API_TOKEN" \
  --data "model_version=v1.0.0&environment_type=prod&aws_region=ap-south-1&ecs_desired_task_count=1"
```

* Destroy:

```bash
curl -X POST \
  "$JENKINS_URL/job/MLOps-Prediction-Model-FullStack/buildWithParameters" \
  --user "$JENKINS_USER:$JENKINS_API_TOKEN" \
  --data "destroy=true"
```


## Pipeline Stages

### 🔔 Notify Start

* Slack notification with job, environment, model & frontend version.

### 🌍 Terraform Init & Validate

* Initializes & validates Terraform configs in `infrastructure` directory.

### 🔍 Scan Terraform Config

* Scans Terraform configs for HIGH/CRITICAL misconfigurations via **Trivy**.
* Fails pipeline if >5 critical issues.

### 🔧 Provision ML & Frontend Infrastructure

* Deploys AWS resources:

  * ECS Cluster & Service (`ecs.tf`)
  * ECR repositories (`ecr.tf`)
  * ALB (`alb.tf`)
  * API Gateway (`api-gw.tf`)
  * S3 bucket and cloudfront distribution for frontend (`s3-cloudfront.tf`)
  * IAM Roles & Policies (`iam.tf`)
  * Security Groups (`sg.tf`)
  * Backend & state config (`backend.tf`)
  * Variables, main config, outputs (`locals.tf`, `main.tf`, `outputs.tf`)
  * Environment-specific values (`values.auto.tfvars`)
* Requests approval if changes detected.

### 📦 Extract Infra Outputs

* Captures outputs:

  * `API_ENDPOINT`, `ALB_DNS`, `ECR_REPO_URL`
  * `ECS_CLUSTER_NAME`, `ECS_SERVICE_NAME`
  * `S3_BUCKET_NAME`, `FRONTEND_URL`

### ⚠️ Terraform Destroy

* Allows safe teardown of ML and frontend infrastructure.
* Includes an approval gate before deleting all AWS resources and ECR images.

### 🛡️ Snyk Code Scan

* Performs static code analysis with **Snyk**.

### 📊 Train ML Model

* Creates a Python virtual environment, installs dependencies, and trains the ML model.

### 🏗️ Build Frontend

* Builds frontend using environment-specific API URL and version.

### 🧪 Run ML Service Tests

* Executes **pytest** to validate ML code correctness.

### 🐳 Containerize Model Service

* Builds Docker image for ML inference service.
* Tags with version and `latest`.

### 🔍 Scan Container Image

* Uses **Trivy** to scan Docker image for vulnerabilities.
* Fails if >5 CRITICAL issues.

### 📤 Publish Model Image

* Pushes Docker image to **AWS ECR**.

### 📝 Register Updated Task Definition

* Updates ECS task definition with new ML model image.

### 🚀 Update Model Service on ECS

* Requests manual approval for ECS rolling update of ML service.

### 🌐 Deploy Frontend to S3

* Deploys frontend build to S3 bucket.
* Frontend available at `FRONTEND_URL`.

### 🌐 Expose Serving Endpoints

* Provides API URL and frontend URL.



## 🚨 Post-Pipeline Notifications

* **✅ Success** → Slack notification with ECS, API, and frontend details.
* **❌ Failure** → Slack alert with job link.
* **⚠️ Unstable** → Slack alert for partial failures.
* **📌 Always** → Marks completion and sends notifications.



## Screenshots

<img width="1893" height="896" alt="Image" src="https://github.com/user-attachments/assets/1c1962db-4465-49f8-96eb-53cd0ccdbf24" />

<img width="1905" height="898" alt="Image" src="https://github.com/user-attachments/assets/e4302601-413c-4169-9077-43d8c8a6a78d" />

<img width="1891" height="899" alt="Image" src="https://github.com/user-attachments/assets/86273ca2-6b64-411f-a780-6f32d202cc17" />

<img width="1681" height="410" alt="Image" src="https://github.com/user-attachments/assets/5de72d52-0acd-4df2-a3c8-5e792c17e57e" />

<img width="1885" height="938" alt="Image" src="https://github.com/user-attachments/assets/6fb1626a-a068-430e-8c8b-60421ec62c3e" />

<img width="1886" height="946" alt="Image" src="https://github.com/user-attachments/assets/1ab90369-8858-40f5-b596-6f1d9fced69d" />

<img width="1494" height="402" alt="Image" src="https://github.com/user-attachments/assets/c87f8fdf-5f5a-43e6-9a59-a88ac4696732" />

<img width="1652" height="967" alt="Image" src="https://github.com/user-attachments/assets/8f010750-edc3-45c9-b624-acdab9c625a3" />

<img width="1109" height="870" alt="Image" src="https://github.com/user-attachments/assets/f1294717-5358-45c1-a2b0-aa23112557d3" />

<img width="1865" height="1025" alt="Image" src="https://github.com/user-attachments/assets/bc372bfb-589f-417b-9f2c-40079ccccc85" />