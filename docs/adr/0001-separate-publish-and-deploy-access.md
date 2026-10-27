# ADR 0001: Separate ECR publishing from EKS deployment authorization

- **Status:** Accepted for Capstone 01 sandbox
- **Date:** 2026-10-27

## Context

The Jenkins pipeline must publish a Java/Spring Boot container image to Amazon ECR and optionally deploy it to an existing EKS cluster. A single broadly privileged AWS credential would increase the blast radius of a compromised publisher or Jenkins job. A Git tag alone does not prove the exact bytes deployed.

## Decision

1. Use separate Jenkins AWS credentials: `aws-twn-capstone01-ecr-publisher` for the immutable ECR repository and `aws-twn-capstone01-eks-deployer` for EKS.
2. Give the deployer AWS permission to describe the specific EKS cluster; register that IAM principal with an EKS access entry using Kubernetes group `twn-capstone01-deployers`.
3. Bind that group to a namespace Role that can patch the named `capstone01-app` Deployment but cannot administer the cluster.
4. Build an immutable tag from the full Git SHA, resolve the published registry digest, and deploy `image@sha256:...` using `eksDeployVerified()`.
5. Require explicit approvals. Keep a separate deployment-only Jenkins job to redeploy an existing digest without republishing a protected tag.

## Consequences

- CI and CD can be verified independently and their AWS credentials remain separated.
- EKS deployment is limited to a pre-existing Deployment in `capstone-01`.
- The release is traceable to an exact registry digest and Jenkins execution.
- Deploying a previously published Git tag through the ECR publishing job is rejected by design.
- Jenkins currently uses long-lived access keys, which should be replaced with temporary credentials in a production design.
- A successfully verified Kubernetes rollout still needs independent HTTP smoke testing to assert application behavior.

## Validation

On 2026-10-27, Jenkins validated the named-resource RBAC permissions, denied broader access, published the Git-tagged image in ECR, and verified the EKS Deployment against digest `sha256:4b46edf007cb4ddc07d9c4004a8678d59c29c365be6f50d6aeb8ff433a516c78`.

## Alternatives considered

- **One shared administrator identity:** Rejected because it grants unnecessary AWS/Kubernetes access.
- **Mutable tags:** Rejected because tag contents can drift over time.
- **Automatic cluster creation within the release job:** Rejected; the capstone deploys into an existing approved cluster.
