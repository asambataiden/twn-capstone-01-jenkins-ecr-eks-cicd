#!/usr/bin/env bash
# Read-only validation of the Capstone 01 deployment and Jenkins EKS access prerequisites.
set -Eeuo pipefail

: "${AWS_PROFILE:?Set AWS_PROFILE to an authorized AWS profile}"
: "${KUBECONFIG:?Set KUBECONFIG to the verified EKS kubeconfig}"

AWS_REGION="${AWS_REGION:-eu-north-1}"
CLUSTER="${EKS_CLUSTER:-floral-mongoose-1792497995}"
ACCOUNT="591132357918"
NAMESPACE="capstone-01"
DEPLOYMENT="capstone01-app"
DEPLOYER="twn-capstone01-eks-deployer"
ARN="arn:aws:iam::${ACCOUNT}:user/${DEPLOYER}"

for tool in aws kubectl; do command -v "$tool" >/dev/null || { echo "Missing command: $tool" >&2; exit 1; }; done

echo '== AWS identity =='
actual_account="$(aws sts get-caller-identity --query Account --output text)"
[[ "$actual_account" == "$ACCOUNT" ]] || { echo 'Unexpected AWS account' >&2; exit 1; }
echo "AWS account verified: $actual_account"

echo '== Cluster =='
aws eks describe-cluster --name "$CLUSTER" --region "$AWS_REGION" --query 'cluster.{Status:status,Version:version,AuthenticationMode:accessConfig.authenticationMode}' --output table

echo '== Jenkins IAM principal =='
if aws iam get-user --user-name "$DEPLOYER" --query 'User.Arn' --output text; then
  aws iam list-attached-user-policies --user-name "$DEPLOYER" --query 'AttachedPolicies[*].[PolicyName,PolicyArn]' --output table
else
  echo 'NOT CONFIGURED: IAM deployer user'
fi

echo '== EKS access entry =='
if aws eks describe-access-entry --cluster-name "$CLUSTER" --region "$AWS_REGION" --principal-arn "$ARN" --query 'accessEntry.{Principal:principalArn,Groups:kubernetesGroups}' --output json; then
  :
else
  echo 'NOT CONFIGURED: EKS deployer access entry'
fi

echo '== Namespace RBAC =='
kubectl --namespace "$NAMESPACE" get role,rolebinding capstone01-deployer

echo '== Workload status =='
kubectl --namespace "$NAMESPACE" rollout status "deployment/$DEPLOYMENT" --timeout=30s
kubectl --namespace "$NAMESPACE" get deployment "$DEPLOYMENT" -o jsonpath='{.spec.template.spec.containers[0].image}{"\\n"}'
kubectl --namespace "$NAMESPACE" get pods -l app.kubernetes.io/name="$DEPLOYMENT"

echo 'Checks finished. The IAM and EKS access entries above are observations, not creation operations.'
