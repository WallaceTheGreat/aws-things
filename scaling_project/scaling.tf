# 1. Launch Template : configuration de chaque instance
resource "aws_launch_template" "app" {
  name_prefix   = "app-template-"
  image_id      = "ami-12345678"
  instance_type = "t3.micro"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3
    python3 -m http.server 8080 &
    echo "Instance demarree : $(hostname)" > /tmp/status
  EOF
  )

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "app-instance", ManagedBy = "autoscaling" }
  }
}

# 2. Auto Scaling Group : min 1, max 5 instances
resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  min_size            = 1
  max_size            = 5
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.public.id]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "app-asg-instance"
    propagate_at_launch = true
  }
}

# 3. Politique de scale OUT (charge haute -> ajouter des instances)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 2
  cooldown               = 120
}

# 4. Alarme CloudWatch : CPU > 70% pendant 2 minutes -> scale out
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-high-70"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.app.name }
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
}

# 5. Politique de scale IN (charge faible -> retirer des instances)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

# 6. Alarme : CPU < 20% pendant 5 minutes -> scale in
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu-low-20"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 20
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.app.name }
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
}
