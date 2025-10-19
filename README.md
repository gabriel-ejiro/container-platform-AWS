# container-platform-AWS

**Author:** Gabriel Ejiro  
**Project:** Production-style container platform on AWS using **ECS (EC2)**, **ALB**, **ECR**, **IAM OIDC (GitHub Actions)**, **CloudWatch**, and **Terraform** — tuned for **Free-Tier** use.

---

## What this does

- Runs a containerized web app on **Amazon ECS (EC2 launch type)** with an **ALB** in front.
- **CI/CD**: Push to `main` → GitHub Actions assumes an AWS role via **OIDC** → builds image → pushes to **ECR** → updates ECS service.
- **Observability**: App logs in **CloudWatch Logs**; ALB & ECS metrics in **CloudWatch Metrics**.
- **Security**: Least-privilege **task role** (IRSA-like) and a scoped **deploy role** for GitHub.

---

## 🧩 Architecture (Mermaid)

```mermaid
flowchart TD
  Dev["Developer pushes to main"] --> CI["GitHub Actions"]
  CI --> IAM["IAM role demo-gh-deploy"]
  CI --> ECR["ECR repo demo-web"]
  CI --> TD["Register task definition"]
  TD --> ECSService["ECS service demo-web-svc"]

  subgraph AWS
    ALB["Application Load Balancer port 80"]
    ECSCluster["ECS cluster EC2"]
    ASG["Auto Scaling Group 1 x t3.micro"]
    EC2["EC2 host with ECS agent"]
    Task["Task demo-web port 3000"]
    CW["CloudWatch logs and metrics"]
  end

  ECR --> ECSService
  ECSService --> ECSCluster
  ECSCluster --> ASG
  ASG --> EC2
  EC2 --> Task
  Task --> ALB
  Task --> CW
  User["User"] --> ALB
```
