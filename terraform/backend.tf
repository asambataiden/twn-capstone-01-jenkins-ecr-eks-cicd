# Rename this file to backend.tf only AFTER provisioning the state bucket.
# Terraform backend blocks cannot use var.* expressions.
terraform {
  backend "s3" {
    bucket              = "twn-capstone01-tfstate-591132357918-eu-north-1"
    key                 = "capstone01/eks-deployer/terraform.tfstate"
    region              = "eu-north-1"
    encrypt             = true
    use_lockfile        = true
    allowed_account_ids = ["591132357918"]
  }
}
