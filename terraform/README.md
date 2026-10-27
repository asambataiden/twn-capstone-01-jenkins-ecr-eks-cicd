# Terraform adoption runbook — Capstone 01 EKS deployer

## Scope

Adopt four **existing** AWS resources using Terraform import blocks:

1. IAM user `twn-capstone01-eks-deployer`
2. IAM managed policy `TWNCapstone01EKSDeployer`
3. IAM user-policy attachment
4. EKS STANDARD access entry for `floral-mongoose-1792497995`

The EKS cluster, workers, ECR repository, Jenkins and Kubernetes manifests are **out of scope**.

## Security and ownership

Use your approved AWS profile with access to **591132357918**. Terraform state can contain sensitive information; keep it out of Git and protect it with filesystem permissions. The initial plan uses local state as a training exercise. Before adopting live resources into **persistent** management, configure an access-controlled, encrypted, versioned remote state backend with locking, and agree on who owns the state. Do not run the same configuration concurrently from different machines.

Terraform source includes `prevent_destroy` for the user, policy and access entry; this is a guardrail but not a substitute for reviewing plans.

## Safe preparation (Mac terminal, repository root)

```bash
export AWS_PROFILE=asambataiden-dev
export AWS_REGION=eu-north-1
aws sts get-caller-identity
git pull --ff-only origin feat/jenkins-ecr-eks-pipeline

cd terraform
umask 077
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform plan -input=false -out=adoption.tfplan
terraform show adoption.tfplan
```

`terraform init -backend=false` prepares providers without configuring remote state. `terraform plan` reads AWS and creates a **local plan file**, but should not mutate cloud resources. Do **not** run `terraform apply` yet.

## Acceptance criteria

The plan must show **exactly four import operations** and **zero creates, updates, replacements or destroys**. Imported resource attributes and access-entry group must match the AWS inventory. Any proposed mutation is a stop-and-investigate event. Provider defaults or policy JSON normalization can surface differences; never blindly accept them.

The Terraform dependency lock file (`.terraform.lock.hcl`) should be committed after provider selection. Keep `.terraform/`, `*.tfstate*` and `*.tfplan` out of Git.

**Stop after `terraform show adoption.tfplan` and review the output.** A later approved import apply writes Terraform state and may invoke AWS APIs; manage state carefully and retain evidence. Prefer proper remote state before that step.

## Recovery and troubleshooting

- If an import suggests resource replacement, **stop**. Check provider fields and existing AWS resource metadata.
- If provider authentication fails, inspect `AWS_PROFILE` and AWS account identity, never paste secrets into tickets.
- If `terraform plan` suggests creating the EKS cluster, the scope is wrong; this configuration must not define one.
- Do not delete AWS resources to make imports succeed.
- To inspect current Kubernetes authorization independently: `kubectl auth can-i get deployment/capstone01-app -n capstone-01` with the intended EKS identity.
