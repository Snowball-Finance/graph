data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name   = "${local.env}-graph-node"
  public_key = tls_private_key.key.public_key_openssh
}

resource "aws_spot_instance_request" "this" {
  ami                            = data.aws_ami.ubuntu.id
  instance_type                  = "c5.2xlarge"
  spot_price                     = "0.86"
  associate_public_ip_address    = true
  wait_for_fulfillment           = true
  subnet_id                      = data.terraform_remote_state.vpc.outputs.public_subnets.0
  vpc_security_group_ids         = ["${aws_security_group.node_sg.id}"]
  iam_instance_profile           = aws_iam_instance_profile.profile.name
  key_name                       = aws_key_pair.key.key_name
  instance_interruption_behavior = "stop"

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp3"
    iops        = 16000
    throughput  = 1000
    volume_size = 400
  }

  tags = {
    Name        = "${local.env}-${local.project}-graph-node"
    Project     = local.project
    Environment = local.env
  }

  lifecycle {
    ignore_changes = [ebs_block_device]
  }
}
