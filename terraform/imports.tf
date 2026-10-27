# Existing-resource adoption only. Review the full plan before any apply.
import {
  to = aws_iam_user.eks_deployer
  id = var.eks_deployer_user_name
}

import {
  to = aws_iam_policy.eks_deployer
  id = local.deployer_policy_arn
}

import {
  to = aws_iam_user_policy_attachment.eks_deployer
  id = "${var.eks_deployer_user_name}/${local.deployer_policy_arn}"
}

import {
  to = aws_eks_access_entry.eks_deployer
  id = "${var.eks_cluster_name}:${local.deployer_user_arn}"
}
