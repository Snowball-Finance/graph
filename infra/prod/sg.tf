resource "aws_security_group" "ecs_alb_https_sg" {
  name        = "${local.cluster_name}-${local.service_name}-alb-sg"
  description = "Security group for ALB to cluster"
  vpc_id      = data.terraform_remote_state.vpc.outputs.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${local.cluster_name}-${local.service_name}-alb-sg"
    Environment = local.env
  }
}

resource "aws_security_group" "ecs_task_sg" {
  name   = "${local.cluster_name}-${local.service_name}-task-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.id

  ingress {
    from_port   = local.graph_port
    to_port     = local.graph_port
    protocol    = "TCP"
    cidr_blocks = ["${data.terraform_remote_state.vpc.outputs.vpc_cidr_block}"]
  }

  ingress {
    from_port   = local.admin_port
    to_port     = local.admin_port
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${local.cluster_name}-${local.service_name}-task-sg"
    Project     = local.cluster_name
    environment = local.env
  }
}

data "aws_security_group" "rds_write_client_sg" {
  name   = "${local.env}-graph-write-master-client-RDS"
  vpc_id = data.terraform_remote_state.vpc.outputs.id
}

resource "aws_security_group_rule" "to_client_write_db_sg" {
  type                     = "ingress"
  protocol                 = "TCP"
  from_port                = local.db_port
  to_port                  = local.db_port
  source_security_group_id = aws_security_group.ecs_task_sg.id
  security_group_id        = data.aws_security_group.rds_write_client_sg.id
}