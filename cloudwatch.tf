resource "aws_sns_topic" "alerts"{
    name = "project1-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "userqlone@gmail.com"
}

resource "aws_cloudwatch_metric_alarm" "vm" {
  alarm_name                = "vm-metrics"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 80
  alarm_description         = "This metric monitors ec2 cpu utilization"
  alarm_actions              = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.vm.name
  }
}
