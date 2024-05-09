// terraform-aws-modules/vpc/aws: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.7.1"

  name = "${var.cluster_name}-vpc"
  cidr = "10.28.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = ["10.28.1.0/24"  , "10.28.2.0/24"  , "10.28.3.0/24"]
  public_subnets  = ["10.28.101.0/24", "10.28.102.0/24", "10.28.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  // パブリックサブネットを外部LB用に利用することをKubernetesとALBが認識できるようにするためのタグ
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  // プライベートネットを内部LB用に利用することをKubernetesとALBが認識できるようにするためのタグ
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

// 外部ALB用SG
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP access."
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP access."
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_adress]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "alb"
  }
}

// 内部ALB用SG
resource "aws_security_group" "internal" {
  name        = "allow_internal"
  description = "Allow internal access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow internal access."
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_http.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "internal"
  }
}
