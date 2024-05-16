terraform {
  required_version = "~> 1.8.0"

  backend "s3" {
    bucket = "kubernetes-work-tfstate"
    key    = "eks-work-iac/prd/app/terraform.tfstate"
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
      PROJECT = "EKS_WORK_IAC_PRD_APP",
    }
  }
}

data "aws_caller_identity" "self" { }

output repositories {
  value = [
    aws_ecr_repository.backend_repository.repository_url,
    aws_ecr_repository.frontend_repository.repository_url,
    aws_ecr_repository.nginx_repository.repository_url,
  ]
}

resource "aws_ecr_repository" "backend_repository" {
  name                 = "eks-work-app/backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "frontend_repository" {
  name                 = "eks-work-app/frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "nginx_repository" {
  name                 = "eks-work-app/nginx"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

/**
 * GitHub ActionsがAWSリソースにOIDC認証でアクセスできるようにするためのIDプロバイダを作成します。
 * 
 * 参考
 *   - AWSの「IDプロバイダーとフェデレーション」の仕組みを利用して、GoogleアカウントでAWSを利用・操作してみた
 *     https://note.com/shift_tech/n/nf5eb16948de1
 *   - IAM ロールを使用して GitHub アクションを AWS のアクションに接続する | AWS セキュリティブログ
 *     https://aws.amazon.com/jp/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/
 */

data "aws_iam_policy_document" "github_actions" {
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [
      aws_ecr_repository.backend_repository.arn,
      aws_ecr_repository.frontend_repository.arn,
      aws_ecr_repository.nginx_repository.arn,
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions" {
  name   = "ECRPushPolicy"
  policy = data.aws_iam_policy_document.github_actions.json
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.self.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_user}/${var.github_app_repository_name}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "GitHubActionsRole"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}