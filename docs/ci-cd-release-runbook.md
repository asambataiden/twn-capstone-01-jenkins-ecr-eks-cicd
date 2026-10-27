# Capstone 01 — CI/CD Release Runbook

## Objective
Automate the build, test, containerization, publication
and Kubernetes deployment of a Spring Boot application.

## CI/CD architecture
GitHub -> Jenkins -> Maven -> Docker -> Amazon ECR -> Amazon EKS

## CI process
1. Checkout the approved Git commit.
2. Execute Maven verification and JUnit tests.
3. Package the Spring Boot application.
4. Build the Docker image.
5. Publish the image to immutable Amazon ECR.
6. Resolve and archive its SHA-256 digest.

## CD process
1. Request explicit EKS deployment authorization.
2. Verify the AWS deployment identity.
3. Verify the EKS cluster identity.
4. Update the existing Kubernetes Deployment.
5. Wait for rollout completion.
6. Verify the deployed image digest.

## Security decisions
- Separate IAM credentials for ECR and EKS.
- Namespace-scoped Kubernetes RBAC.
- Immutable ECR image tags.
- Digest-pinned deployments.
- Explicit deployment approval.
- Temporary kubeconfig with cleanup.
- Non-root application container.
- Read-only root filesystem with writable /tmp.

## Troubleshooting lessons
- An immutable ECR tag cannot be overwritten.
- Jenkins parameters may appear after the first build.
- Named Kubernetes RBAC permissions must be tested
  against the named resource.
- Spring Boot requires a writable temporary directory.
- A successful pipeline may still have skipped stages.

## What I learned
CI proves and packages software; CD releases a verified
artifact into an environment.

AWS IAM and Kubernetes RBAC enforce separate security
boundaries.

An image digest identifies the exact artifact deployed.

Version-controlled configuration and documentation make
the system easier to maintain, rebuild and explain.
