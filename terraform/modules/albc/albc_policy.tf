/**
 * AWS Load Balancer ControllerがALBを作成するために必要なPolicy/Roleを作成します。
 * このRoleをContorollerが使用することにより、Ingressリソースが作成された際に自動でALBを作成できます。
 */

resource "aws_iam_policy" "aws_loadbalancer_controller" {
  name   = "${var.cluster_name}-EKSIngressAWSLoadBalancerControllerPolicy"
  policy = file("${path.module}/albc_iam_policy.json")
}

// OpenID Connect Federated Usersを使用して信頼されたリソースが引き受けることができるIAMロールを作成
// https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-assumable-role-with-oidc
module "iam_assumable_role_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.39.0"

  create_role                  = true
  role_name                    = "${var.cluster_name}-EKSIngressAWSLoadBalancerControllerRole"
  //provider_url                 = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  provider_url                 = replace(var.eks_oidc_issure_url, "https://", "")
  role_policy_arns             = [aws_iam_policy.aws_loadbalancer_controller.arn]
  oidc_subjects_with_wildcards = ["system:serviceaccount:*:*"]
}

// IRSA(IAM Roles for Service Accounts)用のサービスアカウントを作成します。
// NOTE: IRSAとはPodにIAMロールを割り当てる仕組みです。
//       ServiceAccountにIAMロールを割り当て、ServiceAccountをPodに紐づけることで、PodにIAMロールを割り当てます。
// https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account
resource "kubernetes_service_account" "aws_loadbalancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_admin.iam_role_arn
    }
  }
}