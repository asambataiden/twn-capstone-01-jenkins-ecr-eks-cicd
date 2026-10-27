resource "aws_iam_user" "eks_deployer" {
  name = "twn-capstone01-eks-deployer"
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
    resources = ["arn:aws:eks:eu-north-1:591132357918:cluster/floral-mongoose-1792497995"]
  }
}

resource "aws_iam_policy" "eks_deployer" {
  name   = "TWNCapstone01EKSDeployer"
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
