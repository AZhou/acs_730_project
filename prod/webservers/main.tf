# Terraform Config file (main.tf). This has provider block (AWS) and config for provisioning one EC2 instance resource.  

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.27"
    }
  }

  required_version = ">=0.14"
}
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "terraform_remote_state" "public_subnet" { // This is to use Outputs from Remote State
  backend = "s3"
  config = {
    bucket = "azhou23-project-prod-bucket"   // Bucket from where to GET Terraform State
    key    = "dev/network/terraform.tfstate" // Object name in the bucket to GET Terraform State
    region = "us-east-1"                     // Region where bucket created
  }
}
data "terraform_remote_state" "private_subnet" { // This is to use Outputs from Remote State
  backend = "s3"
  config = {
    bucket = "azhou23-project-prod-bucket"   // Bucket from where to GET Terraform State
    key    = "dev/network/terraform.tfstate" // Object name in the bucket to GET Terraform State
    region = "us-east-1"                     // Region where bucket created
  }
}


# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

# Define tags locally
locals {
  default_tags = merge(var.default_tags, { "env" = var.env })
  name_prefix  = "${var.prefix}-${var.env}"

}

resource "aws_instance" "web_test_public" {

  count                       = data.terraform_remote_state.public_subnet.outputs.number_of_public_subnet_ids
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = lookup(var.instance_type, var.env)
  key_name                    = aws_key_pair.prod_key.key_name
  security_groups             = [aws_security_group.web_test_public_sg.id]
  subnet_id                   = data.terraform_remote_state.public_subnet.outputs.public_subnet_ids[count.index]
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/install_httpd.sh.tpl",
    {
      env    = upper(var.env),
      prefix = upper(var.prefix)
    }
  )

  root_block_device {
    encrypted = var.env == "test" ? true : false
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${var.prefix}-webserver-${count.index + 1}"
    }
  )
}

resource "aws_instance" "web_test_private" {

  count                       = data.terraform_remote_state.private_subnet.outputs.number_of_private_subnet_ids
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = lookup(var.instance_type, var.env)
  key_name                    = aws_key_pair.prod_key.key_name
  security_groups             = [aws_security_group.web_test_private_sg.id]
  subnet_id                   = data.terraform_remote_state.private_subnet.outputs.private_subnet_ids[count.index]
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/install_httpd.sh.tpl",
    {
      env    = upper(var.env),
      prefix = upper(var.prefix)
    }
  )

  root_block_device {
    encrypted = var.env == "test" ? true : false
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${var.prefix}-webserver-${count.index + 5}"
    }
  )
}

# Adding SSH  key to instance
resource "aws_key_pair" "prod_key" {
  key_name   = var.prefix
  public_key = file("../../keys/production/${var.prefix}.pub")
}

#security Group
resource "aws_security_group" "web_test_public_sg" {
  name        = "allow_http_ssh_public"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.public_subnet.outputs.vpc_id

  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${var.prefix}-public-sg"
    }
  )
}

resource "aws_security_group" "web_test_private_sg" {
  name        = "allow_http_ssh_private"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.private_subnet.outputs.vpc_id

  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${var.prefix}-private-sg"
    }
  )
}



# Elastic IP
resource "aws_eip" "static_eip" {
  count    = length(aws_instance.web_test_public)
  instance = aws_instance.web_test_public[count.index].id
  tags = merge(local.default_tags,
    {
      "Name" = "${var.prefix}-eip-${count.index + 1}"
    }
  )
}



# Load Balancer

resource "aws_lb" "web_alb" {
  name                       = "web-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.web_test_public_sg.id]
  subnets                    = data.terraform_remote_state.public_subnet.outputs.public_subnet_ids[*]
  enable_deletion_protection = false
  tags = {
    Name = "Web ALB"
  }
}


# Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.public_subnet.outputs.vpc_id

  health_check {
    interval            = 30
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = {
    Name = "Web Target Group"
  }
}

# ALB Listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Register Web Servers to Target Group
resource "aws_lb_target_group_attachment" "web_attachment" {
  count            = data.terraform_remote_state.public_subnet.outputs.number_of_public_subnet_ids
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_test_public[count.index].id
  port             = 80
}



