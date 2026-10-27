resource "aws_eks_access_entry" "eks_deployer" {
  cluster_name      = var.eks_cluster_name
  principal_arn     = aws_iam_user.eks_deployer.arn
  type              = "STANDARD"
  kubernetes_groups = [var.eks_deployer_group]
  user_name         = aws_iam_user.eks_deployer.arn

  lifecycle {
    prevent_destroy = true
  }
}
