/**
 * HelmチャートをClusterにインストールします。
 *
 * 参考
 *   - AWS Load Balancer Controller - Helmを使用してインストールする
 *     https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/lbc-helm.html
 *   - AWS Load Balancer Controller
 *     https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/
 */

resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  // CHART VERSIONS
  // 最新バージョン: https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
  version    = "1.7.2"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.aws_loadbalancer_controller
  ]

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.ap-northeast-1.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    // APPLICATION VERSION
    // 最新バージョン: https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
    name  = "image.tag"
    value = "v2.7.2"
  }
}
