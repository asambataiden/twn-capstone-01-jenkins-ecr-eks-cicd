resource "aws_iam_user" "eks_deployer" {
  name = var.eks_deployer_user_name
  path = "/"

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "eks_deployer" {
  statement {
    sid       = "DescribeCapstoneEKSCluster"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [local.cluster_arn]
  }
}

resource "aws_iam_policy" "eks_deployer" {
  name   = var.eks_deployer_policy_name
  path   = "/"
  policy = data.aws_iam_policy_document.eks_deployer.json

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_user_policy_attachment" "eks_deployer" {
  user       = aws_iam_user.eks_deployer.name
  policy_arn = aws_iam_policy.eks_deployer.arn
}
