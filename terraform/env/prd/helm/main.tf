terraform {
  required_version = "~> 1.8.0"

  backend "s3" {
    bucket = "kubernetes-work-tfstate"
    key    = "eks-work-iac/prd/helm/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
  }

  required_providers {
    // AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.48.0"
    }
    // Kubernetes Provider: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29.0"
    }
    // Helm Provider: https://registry.terraform.io/providers/hashicorp/helm/latest/docs
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.1"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      PROJECT = "EKS_WORK_IAC_PRD_HELM",
    }
  }
}

// Helm Provider: https://registry.terraform.io/providers/hashicorp/helm/latest/docs
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token

    // eks clusterを操作するためのクレデンシャルを取得するコマンドを指定
    // Exec plugins: https://registry.terraform.io/providers/hashicorp/helm/latest/docs#exec-plugins
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
    // config_path            = "~/.kube/config"
  }
}


// Kubernetes Provider: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
provider "kubernetes" {
  // kubenetesAPIのホスト名(URL形式)。KUBE_HOST環境変数で指定している値に基づく。
  host                   = data.aws_eks_cluster.eks.endpoint
  // TLS認証用のPEMエンコードされたルート証明書のバンドル
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)

  // eks clusterを操作するためのクレデンシャルを取得するコマンドを指定
  // Exec plugins: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#exec-plugins
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
  }
  //token                  = data.aws_eks_cluster_auth.eks.token
}

// Data Source: aws_eks_cluster
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster
data "aws_eks_cluster" "eks" {
  name = local.cluster_name
}

// Data Source: aws_eks_cluster_auth
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth
data "aws_eks_cluster_auth" "eks" {
  name = local.cluster_name
}


module albc {
  source = "../../../modules/albc"
  cluster_name = local.cluster_name
  // このコマンドで取得できる: aws eks describe-cluster --name eks-work-prd --query "cluster.identity.oidc.issuer"
  eks_oidc_issure_url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}