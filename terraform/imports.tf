# Adoption only: imports existing AWS resources into Terraform state.
# Review the plan carefully; do not apply changes other than the four expected imports.
import {
  to = aws_iam_user.eks_deployer
  id = "twn-capstone01-eks-deployer"
}

import {
  to = aws_iam_policy.eks_deployer
  id = "arn:aws:iam::591132357918:policy/TWNCapstone01EKSDeployer"
}

import {
  to = aws_iam_user_policy_attachment.eks_deployer
  id = "twn-capstone01-eks-deployer/arn:aws:iam::591132357918:policy/TWNCapstone01EKSDeployer"
}

import {
  to = aws_eks_access_entry.eks_deployer
  id = "floral-mongoose-1792497995:arn:aws:iam::591132357918:user/twn-capstone01-eks-deployer"
}
