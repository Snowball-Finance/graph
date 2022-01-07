resource "aws_security_group" "node_sg" {
  name   = "${local.env}-${local.project}-bc-node-SG"
  vpc_id = data.terraform_remote_state.vpc.outputs.id
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8020
    to_port     = 8020
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    protocol    = "tcp"
    from_port   = 8001
    to_port     = 8001
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.env}-${local.project}-${local.node}-SG"
    Environment = local.env
    Project     = local.project
  }
}

resource "aws_security_group" "https" {
  name        = "${local.env}-${local.project}-${local.node}-alb-sg"
  description = " ${local.project} ${local.node} HTTPS security group"
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
    Name        = "${local.env}-${local.project}-${local.node}-alb-sg"
    Environment = local.env
  }
}

resource "aws_iam_role" "role" {
  name               = "${local.env}-${local.project}-bc-node-IAM-Role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["ec2.amazonaws.com", "ssm.amazonaws.com" ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "user_connect" {
  name        = "${local.env}-${local.project}-bc-node-user-instance-connect"
  path        = "/"
  description = "Allows use of EC2 instance connect"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
  		"Effect": "Allow",
  		"Action": "ec2-instance-connect:SendSSHPublicKey",
  		"Resource": "*",
  		"Condition": {
  			"StringEquals": { "ec2:osuser": "ec2-user" }
  		}
  	},
		{
			"Effect": "Allow",
			"Action": "ec2:DescribeInstances",
			"Resource": "*"
		}
  ]
}
EOF

  depends_on = [
    aws_spot_instance_request.this
  ]
}

resource "aws_iam_policy_attachment" "instance_connect" {
  name       = "${local.env}-${local.project}-bc-node-instance-connect-policy"
  policy_arn = aws_iam_policy.user_connect.arn
  groups     = ["prod-snowball-user-group"]
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "profile" {
  name = "${local.env}-${local.project}-bc-node-instance-profile"
  role = aws_iam_role.role.id
}
