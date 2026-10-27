#!/usr/bin/env bash
# Discover existing Capstone 01 deployer IAM and EKS access configuration.
# Read-only AWS calls. No credentials or Terraform state are created.
set -Eeuo pipefail
: "${AWS_PROFILE:?Set AWS_PROFILE to an authorized read-only or administrator profile}"
export AWS_PAGER=""
AWS_REGION="${AWS_REGION:-eu-north-1}"
ACCOUNT_ID="591132357918"
USER_NAME="twn-capstone01-eks-deployer"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/TWNCapstone01EKSDeployer"
CLUSTER="floral-mongoose-1792497995"

actual="$(aws sts get-caller-identity --query Account --output text)"
[[ "$actual" == "$ACCOUNT_ID" ]] || { echo "Unexpected AWS account: $actual" >&2; exit 1; }

echo "== Terraform / AWS CLI =="
terraform version | head -2
aws --version

echo "== IAM user =="
aws iam get-user --user-name "$USER_NAME" --query 'User.{Arn:Arn,Path:Path}' --output json

echo "== IAM managed policy metadata =="
aws iam get-policy --policy-arn "$POLICY_ARN" \
  --query 'Policy.{Arn:Arn,Path:Path,Description:Description,DefaultVersionId:DefaultVersionId}' \
  --output json

version="$(aws iam get-policy --policy-arn "$POLICY_ARN" --query 'Policy.DefaultVersionId' --output text)"
echo "== IAM policy document (default version $version) =="
aws iam get-policy-version --policy-arn "$POLICY_ARN" --version-id "$version" \
  --query 'PolicyVersion.Document' --output json

echo "== Attached policies =="
aws iam list-attached-user-policies --user-name "$USER_NAME" --output json

echo "== EKS access entry =="
aws eks describe-access-entry --region "$AWS_REGION" --cluster-name "$CLUSTER" \
  --principal-arn "arn:aws:iam::${ACCOUNT_ID}:user/$USER_NAME" \
  --query 'accessEntry.{Principal:principalArn,Type:type,Groups:kubernetesGroups,Username:username,Tags:tags}' \
  --output json

echo "Read-only inventory complete. Review policy document before generating exact Terraform definitions."
