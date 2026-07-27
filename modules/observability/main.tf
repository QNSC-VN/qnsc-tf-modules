locals {
  # ALB CloudWatch dimension is the arn suffix: app/<name>/<id>
  alb_suffix   = var.alb_arn != "" ? replace(var.alb_arn, "/^.*:loadbalancer\\//", "") : ""
  ecs_services = toset(var.ecs_service_names)
}

# ── Alarm topic ──────────────────────────────────────────────────────────────
resource "aws_sns_topic" "alarms" {
  name = "${var.name}-alarms"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  for_each  = toset(var.alarm_emails)
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

# ── ECS alarms (per service) ─────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  for_each            = local.ecs_services
  alarm_name          = "${var.name}-${each.value}-cpu-high"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  dimensions          = { ClusterName = var.ecs_cluster_name, ServiceName = each.value }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.thresholds.ecs_cpu_pct
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_mem" {
  for_each            = local.ecs_services
  alarm_name          = "${var.name}-${each.value}-mem-high"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  dimensions          = { ClusterName = var.ecs_cluster_name, ServiceName = each.value }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.thresholds.ecs_mem_pct
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  tags                = var.tags
}

# ── ALB alarms ───────────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count               = var.alb_arn != "" ? 1 : 0
  alarm_name          = "${var.name}-alb-5xx-high"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  dimensions          = { LoadBalancer = local.alb_suffix }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.thresholds.alb_5xx_count
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  tags                = var.tags
}

# Closes the one real gap in this set: every other alarm fires on a SYMPTOM of load
# (CPU, latency, 5xx), so a service whose tasks are simply not running looks quiet.
# UnHealthyHostCount is the direct signal, and it lives in AWS/ApplicationELB — free
# and native, so it needs no Container Insights, which nothing else here reads either.
#
# Scoped per TARGET GROUP, not per load balancer, because the ALB is shared across
# products: a LoadBalancer-only dimension would aggregate rally and opshub into one
# number and page the wrong team.
resource "aws_cloudwatch_metric_alarm" "target_unhealthy" {
  # Guarded on alb_arn like every other ALB alarm here. Without it, `local.alb_suffix`
  # is "" and the alarm is created with an empty LoadBalancer dimension — it matches no
  # metric and can never fire, which is worse than having no alarm because it looks like
  # coverage.
  for_each = var.alb_arn != "" ? var.target_group_arns : {}

  alarm_name  = "${var.name}-${each.key}-targets-unhealthy"
  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  dimensions = {
    LoadBalancer = local.alb_suffix
    TargetGroup  = replace(each.value, "/^.*:(targetgroup\\/.*)$/", "$1")
  }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = var.thresholds.unhealthy_hosts
  comparison_operator = "GreaterThanThreshold"
  # Missing data is NOT healthy here: a target group with no registered targets
  # publishes nothing at all, which is exactly the outage this exists to catch.
  #
  # That makes the alarm wrong for any environment where zero tasks is a NORMAL state —
  # an off-hours cost-saver that scales services to 0 would hold it permanently in ALARM.
  # Wire `target_group_arns` only for environments expected to be always-on.
  treat_missing_data = "breaching"
  alarm_actions      = [aws_sns_topic.alarms.arn]
  ok_actions         = [aws_sns_topic.alarms.arn]
  tags               = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  count               = var.alb_arn != "" ? 1 : 0
  alarm_name          = "${var.name}-alb-latency-high"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = { LoadBalancer = local.alb_suffix }
  extended_statistic  = "p95"
  period              = 300
  evaluation_periods  = 3
  threshold           = var.thresholds.alb_latency_sec
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  tags                = var.tags
}

# ── RDS alarms ───────────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count               = var.rds_instance_id != "" ? 1 : 0
  alarm_name          = "${var.name}-rds-cpu-high"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = var.thresholds.rds_cpu_pct
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  count               = var.rds_instance_id != "" ? 1 : 0
  alarm_name          = "${var.name}-rds-free-storage-low"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.thresholds.rds_free_bytes
  comparison_operator = "LessThanThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  count               = var.rds_instance_id != "" ? 1 : 0
  alarm_name          = "${var.name}-rds-connections-high"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  dimensions          = { DBInstanceIdentifier = var.rds_instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = var.thresholds.rds_connections
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  tags                = var.tags
}

# ── Dashboard ────────────────────────────────────────────────────────────────
# Optional, unlike the alarms above. CloudWatch gives 3 dashboards free per ACCOUNT
# and then charges $3/mo each, so a dashboard per environment per product starts
# billing at the fourth one — and an environment nobody watches is the wrong one to
# pay for. The alarms are what page someone; this is what you open afterwards.
resource "aws_cloudwatch_dashboard" "this" {
  count          = var.create_dashboard ? 1 : 0
  dashboard_name = var.name
  dashboard_body = jsonencode({
    widgets = concat(
      [for i, svc in var.ecs_service_names : {
        type = "metric", x = (i * 12) % 24, y = 0, width = 12, height = 6
        properties = {
          title  = "ECS ${svc} — CPU/Mem %"
          region = var.region
          view   = "timeSeries"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", svc],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", svc],
          ]
        }
      }],
      var.alb_arn != "" ? [{
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "ALB — requests / 5xx / p95 latency"
          region = var.region
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_suffix],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.alb_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffix, { stat = "p95" }],
          ]
        }
      }] : [],
      var.rds_instance_id != "" ? [{
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "RDS — CPU / connections"
          region = var.region
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_id],
          ]
        }
      }] : [],
    )
  })
}
