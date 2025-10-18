output "alb_dns_name" { value = aws_lb.app_alb.dns_name }
output "ecr_repo_url" { value = aws_ecr_repository.app.repository_url }
output "deploy_role_arn" { value = aws_iam_role.github_actions_deploy.arn }
output "task_execution_role_arn" { value = aws_iam_role.ecs_task_execution.arn }
output "task_role_arn" { value = aws_iam_role.ecs_task.arn }
output "region" { value = var.region }
