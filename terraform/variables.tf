variable "aws_account_id" {
  description = "Approved AWS account containing existing Capstone 01 resources."
  type        = string
  default     = "591132357918"
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "aws_region" {
  description = "AWS region of the existing EKS cluster."
  type        = string
  default     = "eu-north-1"
}

variable "eks_cluster_name" {
  description = "Existing EKS cluster; Terraform does not provision this cluster."
  type        = string
  default     = "floral-mongoose-1792497995"
}

variable "eks_deployer_user_name" {
  description = "Name of the existing Jenkins EKS deployer IAM user."
  type        = string
  default     = "twn-capstone01-eks-deployer"
}

variable "eks_deployer_policy_name" {
  description = "Existing managed IAM policy name."
  type        = string
  default     = "TWNCapstone01EKSDeployer"
}

variable "eks_deployer_group" {
  description = "Kubernetes RBAC group configured in the EKS access entry."
  type        = string
  default     = "twn-capstone01-deployers"
}
