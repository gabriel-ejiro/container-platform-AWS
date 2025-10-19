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
  Dev[Developer pushes to main] --> CI[GitHub Actions]
  CI -->|OIDC AssumeRole| IAM[(IAM Role: demo-gh-deploy)]
  CI --> ECR[ECR (demo-web)]
  CI --> TD[Register Task Definition]
  TD --> ECSService[ECS Service: demo-web-svc]

  subgraph AWS
    ALB[Application Load Balancer :80]
    ECSCluster[ECS Cluster (EC2)]
    ASG[AutoScaling Group: 1 x t3.micro]
    EC2[EC2 host with ECS agent]
    Task[Task: demo-web container (port 3000)]
    CW[CloudWatch Logs & Metrics]
  end

  ECR --> ECSService
  ECSService --> ECSCluster
  ECSCluster --> ASG --> EC2 --> Task
  Task -->|target| ALB
  Task --> CW
  User[User] --> ALB
