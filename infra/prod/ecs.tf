resource "aws_ecs_cluster" "cluster" {
  name = local.cluster_name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  container_definitions    = local.task_definition
  family                   = local.service_name
  cpu                      = local.cpu
  memory                   = local.memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.task_ecs_role.arn
  task_role_arn            = aws_iam_role.task_ecs_role.arn
}

resource "aws_ecs_service" "ecs_service" {
  name            = local.service_name
  task_definition = local.service_name
  desired_count   = local.desired_task_count
  cluster         = aws_ecs_cluster.cluster.name
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.terraform_remote_state.vpc.outputs.public_subnets
    security_groups  = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    container_name   = local.service_name
    container_port   = local.graph_port
    target_group_arn = aws_alb_target_group.default.arn
  }

   load_balancer {
    container_name   = local.service_name
    container_port   = local.admin_port
    target_group_arn = aws_alb_target_group.admin.arn
  }

  depends_on = [
    aws_alb_listener_rule.default,
    aws_iam_role_policy.task_ecs_policy,
    aws_ecs_task_definition.task_definition
  ]
}
