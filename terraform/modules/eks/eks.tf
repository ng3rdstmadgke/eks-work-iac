// terraform-aws-modules/eks/aws: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8.5"

  cluster_name = var.cluster_name
  cluster_version = "1.29"

  // Amazon EKSパブリックAPIサーバーエンドポイントが有効かどうかを示します。
  // NOTE: 「APIサーバーエンドポイント」「パブリックアクセス」とは？: https://dev.classmethod.jp/articles/eks-public-endpoint-access-restriction/#toc-1
  cluster_endpoint_public_access = true

  cluster_addons = {
    // クラスター内でサービス検出を有効にする
    coredns = {
      most_recent = true
    }
    // クラスター内でサービスネットワーキングを有効にする
    kube-proxy = {
      most_recent = true
    }
    // クラスター内でポッドネットワーキングを有効にする
    vpc-cni = {
      most_recent = true
    }
    // Kubernetes サービスアカウントを通じてポッドに AWS IAM アクセス許可を付与する
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  vpc_id = module.vpc.vpc_id

  // ノード/ノードグループがプロビジョニングされるサブネット ID
  // control_plane_subnet_idsが省略された場合、EKS クラスタの制御プレーン (ENI) はこれらのサブネットにプロビジョニングされる
  // パブリックサブネットを含める場合: subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)
  subnet_ids = module.vpc.private_subnets

  // IAM Roles for Service Accounts (IRSA) を有効にするためにEKS用のOpenID Connect Providerを作成するかどうか
  enable_irsa     = true

  // マネージド型ノードグループ: https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/managed-node-groups.html
  eks_managed_node_group_defaults = {
    instance_types = ["t2.medium"]
  }

  eks_managed_node_groups = {
    group_01 = {
      min_size = 1
      max_size = 5
      desired_size   = 1
    }

    group_02 = {
      min_size = 1
      max_size = 5
      desired_size   = 1
      capacity_type = "SPOT"
    }
  }

  // クラスタ作成者(Terraformが使用するID)をアクセスエントリ経由で管理者として追加する
  enable_cluster_creator_admin_permissions = true

  // クラスターに対するIAMプリンシパルアクセスの有効化: https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/add-user-role.html
  authentication_mode = "API_AND_CONFIG_MAP"

  // クラスタSG
  // クラスタSGは下記に適用される
  //   - EKSコントロールプレーン通信用ENI
  //   - マネージドノードグループ内のEC2ノード (ただし、ノードSGが付与されている場合は、クラスタSGは付与されない)
  //
  // EKSのセキュリティグループについて理解する | Qiita: https://qiita.com/MAKOTO1995/items/4e70998e50aaea5e9882
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  // ノードSG
  // マネージドノードグループ内のEC2ノードに付与するSG
  // EKSのセキュリティグループについて理解する | Qiita: https://qiita.com/MAKOTO1995/items/4e70998e50aaea5e9882
  node_security_group_additional_rules = {
    admission_webhook = {
      description                   = "Admission Webhook"
      protocol                      = "tcp"
      from_port                     = 0
      to_port                       = 65535
      type                          = "ingress"
      source_cluster_security_group = true
    }

    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

// ~/.kube/configの自動生成
// kubeconfig ファイルを自動で作成する: https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/create-kubeconfig.html
resource "null_resource" "kubeconfig" {
  triggers = {
    cluster_name = module.eks.cluster_name
  }
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name}"
  }
  depends_on = [
    module.eks,
  ]
}
