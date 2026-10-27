locals {
  cluster_arn         = "arn:aws:eks:${var.aws_region}:${var.aws_account_id}:cluster/${var.eks_cluster_name}"
  deployer_user_arn   = "arn:aws:iam::${var.aws_account_id}:user/${var.eks_deployer_user_name}"
  deployer_policy_arn = "arn:aws:iam::${var.aws_account_id}:policy/${var.eks_deployer_policy_name}"
}
