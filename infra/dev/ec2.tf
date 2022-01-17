locals {
  env = "dev"
}

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
  owners = ["099720109477"]
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name   = "${local.env}-the-node-graph-key"
  public_key = tls_private_key.key.public_key_openssh
  
  # Uncomment if you want to write the key to a file
  # provisioner "local-exec" {
  #   command = "echo '${tls_private_key.key.private_key_pem}' > ./${local.env}-the-node-graph-key.pem"
  # }
}

resource "aws_instance" "graph" {
  ami                         = data.aws_ami.ubuntu.id
  key_name                    = aws_key_pair.key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnets.0
  instance_type               = "t3.medium"
  tags = {
    name = "${local.env}-the-graph-node"
  }
}

resource "aws_security_group" "sg" {
  name   = "${local.env}-the-graph-node-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8001
    to_port   = 8001
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port = 8020
    to_port   = 8020
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
