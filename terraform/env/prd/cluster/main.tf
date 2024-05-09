terraform {
  required_version = "~> 1.8.0"

  backend "s3" {
    bucket = "kubernetes-work-tfstate"
    key    = "eks-work-iac/prd/cluster/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
  }

  required_providers {
    // AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.48.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      PROJECT = "EKS_WORK_IAC_PRD_CLUSTER",
    }
  }
}


module eks {
  source = "../../../modules/eks"
  cluster_name = "eks-work-prd"
  // ALBにアクセスする際のIPアドレス
  my_ip_adress = "0.0.0.0/0"
}