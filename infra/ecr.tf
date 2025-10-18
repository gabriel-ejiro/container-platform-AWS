resource "aws_ecr_repository" "app" {
  name                 = "demo-web"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = { Project = var.project_name }
}
