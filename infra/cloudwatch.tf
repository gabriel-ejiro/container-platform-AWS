resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/demo-web"
  retention_in_days = 7
}
