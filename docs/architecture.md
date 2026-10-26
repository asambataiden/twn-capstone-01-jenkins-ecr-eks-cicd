# Capstone 01 architecture

## Scope

An independently maintained Java application and delivery pipeline, backed by the reusable TWN Jenkins Shared Library. Infrastructure provisioning belongs in separately reviewed Infrastructure as Code; this repository will not create clusters or IAM identities from Jenkins.

## Trust boundaries

1. **Source**: branch protection, code review and dependency verification.
2. **Build**: trusted Jenkins worker, Maven tests, no secrets for untrusted PRs.
3. **Artifact**: ECR immutable tag, verified manifest digest (not Docker image ID).
4. **Release**: explicit approval and controlled AWS identity for publishing.
5. **Runtime**: exact EKS cluster identity verification, namespace-scoped RBAC, temporary kubeconfig, digest-pinned Deployment.
6. **Verification**: Kubernetes rollout status plus independent application health evidence.

## Pending design decisions

- Select the Java baseline and pin dependency/plugin/image versions.
- Confirm application port and endpoints.
- Define EKS account/region/namespace/repository from verified sandbox resources.
- Establish Jenkins agent labels, runtime compatibility and OIDC/role-based AWS access.
- Define meaningful rollback, availability SLO and security scanning policy.

## Evidence policy

Never present local Gradle Groovy mocks as proof of live EKS deployment. Record the actual Jenkins build URL, commit SHA, manifest digest, deployed Deployment/container, health checks and cleanup only after integration execution.
