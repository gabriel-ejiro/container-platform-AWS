# CloudWatch dashboard for ECS + ALB + Logs
resource "aws_cloudwatch_dashboard" "ecs_alb_ops" {
  dashboard_name = "${var.project_name}-ops"

  dashboard_body = jsonencode({
    widgets = [

      # ===== ECS Service CPU (%) =====
      {
        "type": "metric",
        "width": 12, "height": 6, "x": 0, "y": 0,
        "properties": {
          "title": "ECS Service CPU (%)",
          "region": var.region,
          "stat": "Average",
          "view": "timeSeries",
          "metrics": [
            ["AWS/ECS","CPUUtilization","ClusterName", aws_ecs_cluster.this.name, "ServiceName", aws_ecs_service.app.name]
          ],
          "yAxis": { "left": { "min": 0, "max": 100 } }
        }
      },

      # ===== ALB RequestCount (sum) =====
      {
        "type": "metric",
        "width": 12, "height": 6, "x": 12, "y": 0,
        "properties": {
          "title": "ALB Request Count (sum)",
          "region": var.region,
          "stat": "Sum",
          "view": "timeSeries",
          "metrics": [
            ["AWS/ApplicationELB","RequestCount","LoadBalancer", aws_lb.app_alb.arn_suffix]
          ]
        }
      },

      # ===== Target Response Time (avg) =====
      {
        "type": "metric",
        "width": 12, "height": 6, "x": 0, "y": 6,
        "properties": {
          "title": "Target Response Time (avg)",
          "region": var.region,
          "stat": "Average",
          "view": "timeSeries",
          "metrics": [
            ["AWS/ApplicationELB","TargetResponseTime",
              "TargetGroup", aws_lb_target_group.app_tg.arn_suffix,
              "LoadBalancer", aws_lb.app_alb.arn_suffix
            ]
          ]
        }
      },

      # ===== ALB 5XX Errors (sum) =====
      {
        "type": "metric",
        "width": 12, "height": 6, "x": 12, "y": 6,
        "properties": {
          "title": "ALB 5XX Errors (sum)",
          "region": var.region,
          "stat": "Sum",
          "view": "timeSeries",
          "metrics": [
            ["AWS/ApplicationELB","HTTPCode_ELB_5XX_Count","LoadBalancer", aws_lb.app_alb.arn_suffix]
          ]
        }
      },

      # ===== Logs Insights: last 20 lines from /ecs/demo-web =====
      {
        "type": "log",
        "width": 24, "height": 6, "x": 0, "y": 12,
        "properties": {
          "title": "Latest app logs (/ecs/demo-web)",
          "region": var.region,
          "query": "SOURCE '/ecs/demo-web' | fields @timestamp, @message | sort @timestamp desc | limit 20",
          "view": "table"
        }
      }
    ]
  })
}
