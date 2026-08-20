# Abacus Consulting Internship - Cloud & DevOps Engineering

This repository contains the projects and tasks completed during my 6-week internship as a **Cloud & DevOps Engineer** at **Abacus Consulting (Pvt.) Ltd.** (July 13, 2026 – August 23, 2026). 

The focus of this internship was on Cloud Infrastructure (AWS), DevOps automation, Containerization (Docker, Kubernetes), CI/CD pipelines, and Infrastructure as Code (Terraform).

## 🛠️ Technologies & Tools Used
- **Cloud Provider:** Amazon Web Services (AWS) - EC2, VPC, ALB, ASG, EFS, ECR, SSM, CodeBuild
- **Containerization & Orchestration:** Docker, Docker Compose, Kubernetes (K8s)
- **Infrastructure as Code (IaC):** Terraform
- **CI/CD:** GitHub Actions, AWS CodeBuild
- **Web Servers & Applications:** Apache2, PHP-FPM, Laravel (PHP)
- **OS / Scripting:** Ubuntu Linux, Bash

---

## 📁 Repository Structure & Projects

### [Task 1 - AWS Scalable Infrastructure Setup](./Task%201)
Designed and provisioned a highly available AWS infrastructure from scratch.
- Configured a custom VPC across two Availability Zones with public and private subnets.
- Set up Internet Gateway, NAT Gateway, and custom route tables.
- Deployed an Application Load Balancer (ALB) and an Auto Scaling Group (ASG) with a Target Tracking scaling policy (maintaining 60% CPU utilization) for high availability.

### [Task-2 - Laravel Application Deployment on EC2](./Task-2)
Configured web servers and deployed a production-grade PHP Laravel application.
- Installed and configured Apache2 and PHP-FPM on Ubuntu EC2 instances.
- Deployed a Laravel application, configuring the virtual host, required Apache modules, and application dependencies via Composer.

### [Task-3 - EFS Attachment & GitHub Actions OIDC](./Task-3)
Extended the cloud infrastructure with persistent shared storage and secure authentication.
- Provisioned Amazon Elastic File System (EFS) and mounted it to the ASG instances to share persistent data across scaled servers.
- Configured an OpenID Connect (OIDC) Identity Provider in AWS IAM to enable secure, keyless authentication for GitHub Actions.

### [Task-4 - Multi-Stage CI/CD Pipeline](./Task-4)
Built a fully automated CI/CD pipeline using GitHub Actions.
- Pipeline builds the application and creates a Docker image.
- Pushes the built image to Amazon Elastic Container Registry (ECR).
- Automatically deploys the updated container to all EC2 instances in the Auto Scaling Group using AWS Systems Manager (SSM) Run Command.

### [Task-5 - AWS CodeBuild Pipeline](./Task-5)
Explored AWS-native CI/CD tools by creating an AWS CodeBuild pipeline.
- Wrote a `buildspec.yml` file to automate the build phase.
- Integrated AWS Secrets Manager and SSM Parameter Store for secure environment variable and secret management during the build process.

### [laravel-adminpanel - Dockerizing a Laravel App](./laravel-adminpanel)
Containerized an existing Laravel Admin Panel application.
- Authored a production-optimized, multi-stage `Dockerfile` utilizing Alpine Linux and PHP-FPM.
- Configured `docker-compose.yml` to orchestrate the Laravel application container alongside an Nginx reverse proxy and a MySQL database container.

### [k8s - Kubernetes Deployment](./k8s)
Migrated the containerized Laravel application to Kubernetes.
- Wrote complete Kubernetes manifests including:
  - `Namespace` isolation.
  - `ConfigMap` and `Secret` for secure environment injection.
  - `StatefulSet` with headless Service for the MySQL database.
  - `Deployment` and `Service` (NodePort) for the Laravel application pods.

### [terraform-task - Infrastructure as Code](./terraform-task)
Codified the entire AWS cloud infrastructure utilizing Terraform.
- Developed modular HCL code with reusable modules for VPCs, Compute, Security Groups, ALB, and ASG.
- Automated the reproducible provisioning of the complex architecture initially built manually in Task 1.

---

## 🤝 Acknowledgments
Special thanks to my supervisors and the Cloud & DevOps Engineering team at **Abacus Consulting** for their continuous mentorship and support throughout this incredible learning experience.
