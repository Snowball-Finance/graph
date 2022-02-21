locals {
  cluster_name       = "graph-node"
  env                = "prod"
  service_name       = "graph"
  domain_name        = "graph"
  graph_port         = 8000
  admin_port         = 8020
  health             = 8030
  desired_task_count = "1"
  db_port            = "5432"
  memory             = 16384 // 16GB
  cpu                = 4096 // 4vCPUs
  region             = "us-west-2"
  version            = "fraction"
}

locals {
  task_definition = jsonencode([
    {
      name      = local.service_name
      image     = "graphprotocol/graph-node:${local.version}"
      essential = true,
      dockerLabels = {
        "com.datadoghq.ad.instances" : "[{\"host\":\"%%host%%\"}]",
        "com.datadoghq.ad.check_names" : "[\"graph\"]",
      },
      portMappings : [
        { containerPort = local.graph_port },
        { containerPort = local.admin_port }
      ],
      secrets = [
        {
         "name"      = "postgres_db",
         "valueFrom" = "${data.aws_ssm_parameter.db_name.arn}"
        },
        {
         "name"      = "postgres_host"
         "valueFrom" = "${data.aws_ssm_parameter.db_uri.arn}"
        },
        {
         "name"      = "postgres_user",
         "valueFrom" = "${data.aws_ssm_parameter.db_username.arn}"
        },
        {
         "name"      = "postgres_pass",
         "valueFrom" = "${data.aws_ssm_parameter.db_password.arn}"
        }
      ],
      
      environment = [
        {
          name  = "postgres_port",
          value = local.db_port
        },
        {
          name  = "GRAPH_LOG",
          value = "info"
        },
        {
          name  = "RUST_LOG",
          value = "info"
        },
        {
          name = "RUST_BACKTRACE",
          value = "full"
        },
         {
          name  = "ipfs",
          value = "https://ipfs.snowapi.net/"
        },
        {
          name  = "ethereum",
          value = "avalanche:https://api.avax.network/ext/bc/C/rpc"
        },
         {
         name      = "ETHEREUM_POLLING_INTERVAL",
         value     = "1000"
        }
      ],
      logConfiguration = {
        logDriver = "awsfirelens"
        secretOptions = [{
          "name"      = "apiKey",
          "valueFrom" = "${data.aws_ssm_parameter.dd_dog.arn}"  
        }]
        options = {
          Name             = "datadog"
          "dd_service"     = "${local.service_name}"
          "Host"           = "http-intake.logs.datadoghq.com"
          "dd_source"      = "${local.service_name}"
          "dd_message_key" = "log"
          "dd_tags"        = "project:${local.service_name}"
          "TLS"            = "on"
          "provider"       = "ecs"
        }
      }
    },
    {
      name      = "datadog-agent"
      image     = "datadog/agent:latest"
      essential = true
      secrets = [{
          "name"      = "DD_API_KEY",
          "valueFrom" = "${data.aws_ssm_parameter.dd_dog.arn}"
      }],
      environment = [
        {
          name  = "ECS_FARGATE"
          value = "true"
        },
        {
          name  = "DD_ENV"
          value = local.env
        },
        {
          name  = "DD_SERVICE"
          value = local.service_name
        }
      ]
    },
    {
      name      = "log_router"
      image     = "amazon/aws-for-fluent-bit:2.19.0"
      essential = true
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          "enable-ecs-log-metadata" = "true"
        }
      }
    }
  ])
}

data "aws_kms_key" "kms_key" {
  key_id = "alias/${local.env}-kms-key"
}

data "aws_ssm_parameter" "db_name" {
  name = "${local.env}-graph-rds-db-name"
}

data "aws_ssm_parameter" "db_password" {
  name = "${local.env}-graph-rds-db-password"
}

data "aws_ssm_parameter" "db_username" {
  name = "${local.env}-graph-rds-db-username"
}

data "aws_ssm_parameter" "db_uri" {
  name = "${local.env}-graph-write-db-host-url"
}

data "aws_ssm_parameter" "dd_dog" {
  name = "${local.env}-data-dog-api-key"
}
