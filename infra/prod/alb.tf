resource "aws_alb" "this" {
  name            = "${local.env}-${local.project}-${local.node}-alb"
  internal        = false
  security_groups = ["${aws_security_group.https.id}"]
  subnets         = data.terraform_remote_state.vpc.outputs.public_subnets
  tags = {
    Name = "${local.env}-${local.project}-${local.node}-alb"
  }
}

resource "aws_alb_target_group" "https" {
  name        = "${local.env}-${local.project}-${local.node}-tg"
  port        = local.node_port
  vpc_id      = data.terraform_remote_state.vpc.outputs.id
  target_type = "instance"
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
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }

  tags = {
    Name = "${local.env}-${local.project}-${local.node}-tg"
  }
}

resource "aws_alb_target_group" "http" {
  name     = "${local.env}-${local.project}-${local.node}-http-tg"
  port     = local.node_port
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.id
  tags = {
    Name = "${local.env}-${local.project}-${local.node}-http-tg"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = aws_alb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.cert.arn

  lifecycle {
    create_before_destroy = true
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.http.arn
  }
}

resource "aws_alb_listener_rule" "alb_listener_rule" {
  listener_arn = aws_alb_listener.https_listener.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.https.arn
  }

  condition {
    host_header {
      values = ["${local.domain_name}.snowapi.net"]
    }
  }
}

resource "aws_alb_target_group_attachment" "this" {
  target_group_arn = aws_alb_target_group.https.arn
  target_id        = aws_spot_instance_request.this.spot_instance_id
  port             = local.node_port
}
