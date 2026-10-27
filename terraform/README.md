# Terraform adoption runbook — Capstone 01 EKS deployer

## Scope

Adopt four **existing** AWS resources using Terraform import blocks:

1. IAM user `twn-capstone01-eks-deployer`
2. IAM managed policy `TWNCapstone01EKSDeployer`
3. IAM user-policy attachment
4. EKS STANDARD access entry for `floral-mongoose-1792497995`

The EKS cluster, workers, ECR repository, Jenkins and Kubernetes manifests are **out of scope**.

## Security and ownership

Use your approved AWS profile with access to **591132357918**. Terraform state can contain sensitive information; keep it out of Git and protect it with filesystem permissions. The main Terraform root already uses an encrypted, versioned S3 remote backend with native lockfile locking; the separate S3 bucket bootstrap root retains local state. Only authorized operators should hold backend write permissions. Do not run the same configuration concurrently from different machines. Do not run the same configuration concurrently from different machines.

Terraform source includes `prevent_destroy` for the user, policy and access entry; this is a guardrail but not a substitute for reviewing plans.

## Current operating procedure — remote state configured

The adoption completed on 2026-10-27. This configuration now uses the committed `backend.tf` pointing to the encrypted, private, versioned S3 bucket; **do not use `terraform init -backend=false` for routine operations**.

From the repository root, with an authorized AWS profile:

```bash
export AWS_PROFILE=asambataiden-dev
export AWS_REGION=eu-north-1
cd terraform
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -detailed-exitcode
```

A plan exit code of 0 means no difference, 2 indicates a proposed change and 1 an error. Review any changes; do not automatically apply them.

The `imports.tf` blocks record how these existing resources were adopted. With imported resources already present in state, future plans should not repeat imports. If state is lost or ownership is transferred, recover through a reviewed state-management procedure rather than deleting AWS resources.

The separate `bootstrap-state/` Terraform root provisions the S3 state bucket and is currently backed by **local state**. Preserve its encrypted backup in a protected location; never commit state or saved plans. Use the separately committed provider lock files in both Terraform roots.

## Recovery and troubleshooting

- If an import suggests resource replacement, **stop**. Check provider fields and existing AWS resource metadata.
- If provider authentication fails, inspect `AWS_PROFILE` and AWS account identity, never paste secrets into tickets.
- If `terraform plan` suggests creating the EKS cluster, the scope is wrong; this configuration must not define one.
- Do not delete AWS resources to make imports succeed.
- To inspect current Kubernetes authorization independently: `kubectl auth can-i get deployment/capstone01-app -n capstone-01` with the intended EKS identity.


## Verified adoption — 2026-10-27

The approved S3 backend was provisioned using the isolated `bootstrap-state/` root and checked for bucket versioning, default SSE-S3 (AES256), full public-access blocking, bucket-owner-enforced ownership, and a TLS-only bucket policy.

With the main root initialized against `s3://twn-capstone01-tfstate-591132357918-eu-north-1/capstone01/eks-deployer/terraform.tfstate` and S3 native lock-file locking configured, the import-only plan was applied:

```text
Apply complete! Resources: 4 imported, 0 added, 0 changed, 0 destroyed.
No changes. Your infrastructure matches the configuration.
```

The imported **managed** resources are:

```text
aws_eks_access_entry.eks_deployer
aws_iam_policy.eks_deployer
aws_iam_user.eks_deployer
aws_iam_user_policy_attachment.eks_deployer
```

`data.aws_iam_policy_document.eks_deployer` also appears in `terraform state list`; it is a data source, not a fifth managed AWS resource.

S3 `head-object` confirmed the remote state object exists, uses AES256 encryption and has an S3 version ID. The EKS deployment `capstone01-app` subsequently passed rollout verification in namespace `capstone-01`, reporting 1/1 available deployment and pod Running with zero restarts.

### Reproducible day-2 validation

From `terraform/` with an authorized AWS profile:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -input=false -detailed-exitcode
```

Plan exit code `0` means no differences, `2` means planned differences and `1` means error. Never automatically apply a plan with exit code `2`. Terraform state objects and saved plans are sensitive and must not be committed.

### Follow-ups / known limitations

- The existing IAM user has a legacy tag named after an access-key-like identifier. `ignore_changes = [tags]` intentionally preserves it for import-only adoption. Replace it with meaningful metadata under a separately reviewed change and then remove this lifecycle exception.
- The bootstrap bucket is currently managed by **local bootstrap Terraform state**. Protect an encrypted backup outside a shared/synced workspace; don't commit local state, and record an authorized recovery procedure.
- S3 backend currently uses the interactive authorized AWS profile. Consider a dedicated least-privilege state-backend role with only required bucket/object/lock-file permissions.
- The IAM deployer uses static credentials through Jenkins. Prefer a federated or short-lived-credential model when appropriate; rotate and retire static credentials under a separately tested migration.
- Existing EKS Kubernetes Role and RoleBinding remain version-controlled Kubernetes manifests, **not** part of this Terraform state. No EKS cluster or workload resources are provisioned by this Terraform root.
- Never remove imported resources from Terraform configuration without considering state ownership and `prevent_destroy` implications; use reviewed, deliberate state operations when transferring ownership.
