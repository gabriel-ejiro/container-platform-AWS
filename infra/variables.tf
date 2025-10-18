variable "region" {
  type        = string
  description = "AWS region"
  default     = "eu-north-1"
}

variable "project_name" {
  type        = string
  default     = "demo"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro" # or t2.micro
}

variable "github_owner" { type = string } # e.g., "gabriel-ejiro"
variable "github_repo"  { type = string } # e.g., "container-platform"

cd infra
terraform init
terraform apply -auto-approve \
  -var github_owner="YOUR_GH_USER" \
  -var github_repo="YOUR_REPO_NAME"

