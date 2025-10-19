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
graph TD
  Dev[Developer push to main] --> CI[GitHub Actions]
  CI -->|OIDC AssumeRole| IAM[(IAM Role: demo-gh-deploy)]
  CI --> ECR[ECR (demo-web)]
  CI --> TD[Register Task Definition]
  TD --> ECS[ECS Service: demo-web-svc]
  ECR --> ECS

  subgraph AWS
    ALB[Application Load Balancer :80]
    CLU[ECS Cluster (EC2)]
    ASG[AutoScaling Group: 1 x t3.micro]
    EC2[EC2 host w/ ECS agent]
    TASK[Task: demo-web container (port 3000)]
    CW[CloudWatch Logs + Metrics]
  end

  ECS --> CLU
  CLU --> ASG --> EC2 --> TASK
  TASK -->|target| ALB
  TASK --> CW
  User[User] --> ALB
