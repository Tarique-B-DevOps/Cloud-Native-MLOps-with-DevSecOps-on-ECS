# Cloud-Native MLOps with AWS

[![Python](https://img.shields.io/badge/Python-3.13%2B-blue.svg)](https://www.python.org/downloads/)
[![Terraform](https://img.shields.io/badge/Terraform-1.13%2B-623CE4.svg)](https://www.terraform.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI/CD-blue.svg)](https://www.jenkins.io/)
[![AWS ECS](https://img.shields.io/badge/AWS%20ECS-ECS%2FECR%2FALB%2FAPI%20Gateway%2FS3%2FCloudFront-FF9900.svg)](https://aws.amazon.com/)
[![Docker](https://img.shields.io/badge/Docker-Containerization-blue.svg)](https://www.docker.com/)
[![scikit-learn](https://img.shields.io/badge/scikit--learn-ML-yellow.svg)](https://scikit-learn.org/)
[![React](https://img.shields.io/badge/React-Frontend-61DAFB.svg)](https://reactjs.org/)
[![Vite](https://img.shields.io/badge/Vite-Bundler-green.svg)](https://vitejs.dev/)
[![Pytest](https://img.shields.io/badge/Pytest-Testing-005C8C.svg)](https://docs.pytest.org/)
[![Snyk](https://img.shields.io/badge/Snyk-Security-red.svg)](https://snyk.io/)
[![Trivy](https://img.shields.io/badge/Trivy-Scanning-red.svg)](https://github.com/aquasecurity/trivy)
[![Slack](https://img.shields.io/badge/Slack-Notifications-4A154B.svg)](https://slack.com/)

A **complete, production-ready MLOps pipeline** for machine learning model deployment and automation — built with **Jenkins**, **Terraform**, **Docker**, **AWS ECS**, and a **React/Vite frontend**.

This project demonstrates **end-to-end MLOps**, integrating **DevSecOps principles**, **model lifecycle automation**, and **CI/CD orchestration**. It covers everything from **training**, **testing**, and **security scanning** to **deployment** and **monitoring** — fully automated on AWS.

---

## 🔍 Why This MLOps Pipeline?

If you’re looking for a **real-world, cloud-native MLOps example**, this repository provides a **step-by-step reference implementation** for:
- Machine Learning Model Training & Deployment
- Infrastructure as Code (IaC) with Terraform
- CI/CD Pipeline using Jenkins
- Secure DevOps with Trivy & Snyk
- Monitoring & Notifications with Slack

<video width="640" height="360" controls>
  <source src="https://github.com/user-attachments/assets/735177ba-205e-4373-ba20-fe1481095872" type="video/mp4">
  Your browser does not support the video tag.
</video>

[🎥 Watch Full Demo Video on GitHub](https://github.com/user-attachments/assets/735177ba-205e-4373-ba20-fe1481095872)

---

## 📘 Overview of the MLOps Pipeline

### 🚀 Key Features
* **Pipeline-as-Code**: Jenkins Declarative Pipeline for automation.
* **Infrastructure Provisioning**: Terraform-based IaC for AWS resources.
* **Security Scanning**: Trivy & Snyk integration for code, image, and IaC scans.
* **Model Lifecycle Management**: Automated training, testing, packaging, and deployment.
* **Frontend Build & Deployment**: React/Vite frontend hosted on AWS S3 + CloudFront.
* **Continuous Delivery to AWS ECS**: Full CI/CD workflow for ML model updates.
* **Slack Notifications**: Automated messages for build and deployment events.
* **Environment-Aware Deployment**: Supports `dev`, `staging`, and `prod`.

---

## 🧰 Tech Stack

**Core Tools:**
- **Infrastructure as Code** → Terraform  
- **CI/CD Orchestration** → Jenkins  
- **Cloud Platform** → AWS (ECS, ECR, ALB, API Gateway, S3, CloudFront)  
- **Containerization** → Docker  
- **Machine Learning** → Python, scikit-learn  
- **Frontend** → React, Vite  
- **Testing** → Pytest  
- **Security & Compliance** → Snyk, Trivy  
- **Observability & Notifications** → Slack Integration  

---

## 🧠 Machine Learning Model

Implements a **House Price Prediction Model** using **Linear Regression** in **scikit-learn**.

### 📊 Dataset
Synthetic dataset with these features:
- `Size` (500–5000 sq. ft.)
- `Bedrooms` (1–5)
- `Age` (0–50 years)
- Target → House Price

Formula used:
```python
price = (size * 300) + (bedrooms * 10000) - (age * 500) + noise
```
Noise ~ Gaussian(mean=0, std=50,000)

### 🧩 Training Details
- Algorithm → Linear Regression  
- Split → 80/20 train-test  
- Metrics → Mean Squared Error (MSE), R² Score  
- Model Path → `models/house_price_model-latest.pkl`

### ⚙️ Inference Service
Built using **FastAPI** with endpoints for prediction, health, and version checks.

**Endpoints:**
- `GET /` → Status  
- `POST /predict` → Predicts house price  
- `GET /health` → Health check  
- `GET /version` → Current model version

Example JSON response:
```json
{"predicted_price": 450123.45}
```

---

## 🖥️ Frontend Application

A **React + Vite** web UI connects to the deployed model’s API for **real-time predictions**.

### Features
- API Gateway integration for dynamic backend endpoints
- Input fields for house features (Size, Bedrooms, Age)
- Displays model and frontend version
- Deployed via S3 & CloudFront for global access

This ensures each Jenkins run delivers a fully functional ML service with synced **frontend, backend, and model versions**.

---

## ⚙️ Pipeline Parameters

| Parameter | Type | Default | Description |
|------------|------|----------|--------------|
| `model_version` | String | `v1.0.0` | ML model version |
| `environment_type` | Choice (`dev`, `staging`, `prod`) | `dev` | Deployment environment |
| `aws_region` | String | `ap-south-2` | AWS region |
| `ecs_desired_task_count` | String | `3` | Number of ECS tasks |
| `destroy` | Boolean | `false` | Run Terraform destroy instead of deploy |

### Example Usage

Deploy:
```bash
curl -X POST \
  "$JENKINS_URL/job/MLOps-Prediction-Model-FullStack/buildWithParameters" \
  --user "$JENKINS_USER:$JENKINS_API_TOKEN" \
  --data "model_version=v1.0.0&environment_type=prod&aws_region=ap-south-1&ecs_desired_task_count=1"
```

Destroy:
```bash
curl -X POST \
  "$JENKINS_URL/job/MLOps-Prediction-Model-FullStack/buildWithParameters" \
  --user "$JENKINS_USER:$JENKINS_API_TOKEN" \
  --data "destroy=true"
```

---

## 🔄 Jenkins Pipeline Stages Overview

### 🔔 Start Notification
- Slack message triggered with environment and version details.

### 🌍 Terraform Init & Validate
- Initializes and validates Terraform configuration files.

### 🧭 Security Scanning
- **Trivy** → Scans Terraform for misconfigurations.  
- **Snyk** → Scans code dependencies.

### ⚙️ Infrastructure Provisioning
Deploys and manages:
- ECS Cluster, Service
- ECR Repositories
- ALB, API Gateway
- S3 Bucket, CloudFront Distribution
- IAM Roles, Security Groups

### 🧠 Model Training & Testing
- Trains model using scikit-learn.
- Runs **pytest** for validation.

### 🐳 Docker Image Build & Scan
- Builds Docker image for FastAPI service.  
- Scans image with Trivy.  
- Pushes image to **AWS ECR**.

### 🚀 Deployment to AWS ECS
- Registers new ECS task definition.  
- Performs rolling updates with manual approval.

### 🌐 Frontend Deployment
- Builds frontend with API endpoint.
- Deploys to **S3** and **CloudFront**.

### 📣 Post-Pipeline Notifications
Slack alerts for success, failure, or unstable builds.

---

## 🧩 Visual Workflow (Screenshots)

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
