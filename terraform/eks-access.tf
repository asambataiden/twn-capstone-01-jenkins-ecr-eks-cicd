resource "aws_eks_access_entry" "eks_deployer" {
  cluster_name      = "floral-mongoose-1792497995"
  principal_arn     = aws_iam_user.eks_deployer.arn
  type              = "STANDARD"
  kubernetes_groups = ["twn-capstone01-deployers"]
  user_name         = aws_iam_user.eks_deployer.arn

  lifecycle {
    prevent_destroy = true
  }
}
