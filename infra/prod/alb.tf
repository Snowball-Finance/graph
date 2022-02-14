resource "aws_alb" "alb" {
  name                       = "${local.service_name}-alb"
  drop_invalid_header_fields = true
  security_groups            = ["${aws_security_group.ecs_alb_https_sg.id}"]
  subnets                    = data.terraform_remote_state.vpc.outputs.public_subnets
  tags = {
    Name = "${local.service_name}-alb"
  }
}

resource "aws_alb_listener" "alb_https_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.cert.arn

  lifecycle {
    create_before_destroy = true
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.default.arn
  }
}

resource "aws_alb_target_group" "default" {
  name        = "${local.service_name}-default-ecs-tg"
  port        = local.graph_port
  vpc_id      = data.terraform_remote_state.vpc.outputs.id
  target_type = "ip"
  protocol    = "HTTP"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 60
    timeout             = 30
    unhealthy_threshold = 3
    healthy_threshold   = 3
  }

  tags = {
    Name = "${local.service_name}-default-ecs-tg"
  }
}

resource "aws_alb_listener_rule" "default" {
  listener_arn = aws_alb_listener.alb_https_listener.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.default.arn
  }

  condition {
    host_header {
      values = ["${local.domain_name}.snowapi.net"]
    }
  }
}

resource "aws_alb_target_group" "admin" {
  name        = "${local.service_name}-admin-ecs-tg"
  port        = local.admin_port
  vpc_id      = data.terraform_remote_state.vpc.outputs.id
  target_type = "ip"
  protocol    = "HTTP"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    port                = local.graph_port
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 60
    timeout             = 30
    unhealthy_threshold = 3
    healthy_threshold   = 3
  }

  tags = {
    Name = "${local.service_name}-admin-ecs-tg"
  }
}

resource "aws_alb_listener_rule" "admin" {
  listener_arn = aws_alb_listener.alb_https_listener.arn
  priority     = 99
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.admin.arn
  }

  condition {
    path_pattern {
      values = ["/admin"]
    }
  }

  condition {
    host_header {
      values = ["${local.domain_name}.snowapi.net"]
    }
  }
}
