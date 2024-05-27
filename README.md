# デプロイ


```bash
STAGE=prd

# ECS Cluster構築
cd terraform/env/$STAGE/cluster
terraform init
terraform plan
terraform apply -auto-approve


# helm 導入
#   - AWS Load Balancer Controller 導入
cd terraform/env/$STAGE/helm
terraform init
terraform plan
terraform apply -auto-approve

# アプリケーション
cd terraform/env/$STAGE/app
terraform init
terraform plan
terraform apply -auto-approve

# IAMロールにEKSの権限を付与する (aws-auth ConfigMapに設定を追加)
eksctl create iamidentitymapping \
  --cluster eks-work-${STAGE} \
  --region ap-northeast-1 \
  --arn EKSの管理者に追加したいRoleのARN \
  --group system:masters \
  --username AwsConsole

# 指定したロールがsystem:mastersグループに属しているかを確認
kubectl describe -n kube-system configmap/aws-auth

```

# kubeconfigの更新

```bash
aws eks update-kubeconfig --name eks-work-prd
```