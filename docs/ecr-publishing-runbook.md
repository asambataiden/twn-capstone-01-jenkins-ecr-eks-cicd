# Phase 10.2 — ECR publication integration

## Separate Jenkins job

Keep the successful build-only job (`Jenkinsfile.ci`) intact. Create a **separate trusted, manually triggered Pipeline job** with script path `Jenkinsfile.ecr`, checking out branch `feat/jenkins-ecr-eks-pipeline`.

This new job is intentionally **not** approved for unattended production releases. Do not permit untrusted contributors or pull-request builds to execute its Jenkinsfile.

## Safety prerequisites

- Confirm the actual AWS account, region and repository. The historical bootcamp settings are not automatically trusted.
- Configure a dedicated Jenkins agent labeled `docker-ecr-publisher` with Git, Java 17+, Maven named `maven-3.9`, Docker daemon, AWS CLI v2, and **short-lived approved IAM credentials**. Do not assign this label to unrelated agents.
- The ECR repository must already exist, have `IMMUTABLE` image tags, and have appropriate IAM permissions. The Shared Library verifies the caller's AWS account and rejects existing tags.
- Configure the Global Pipeline Library with name `twn-devops-bootcamp-jenkins-shared-library`. During this development phase `Jenkinsfile.ecr` references `feat/library-foundation`. Pin the library to a reviewed immutable revision for a controlled release.
- AWS credentials should be provided by a trusted role/federated identity, not as plaintext Jenkinsfile values. See the Shared Library ECR runbook.
- Give publishing jobs isolated agents; Docker access is privileged. Never grant an AWS publishing role to an untrusted Jenkinsfile or PR job.

## First test

1. Set `ALLOW_ECR_PUBLISH=false` and run the job to confirm the fail-closed preflight. No AWS call, Docker build or ECR push should occur.
2. Independently verify the AWS caller account and repository immutability, then confirm IAM authorization.
3. Review the exact source revision and Jenkinsfile. Enable `ALLOW_ECR_PUBLISH=true`, fill in the approved `AWS_ACCOUNT_ID`, `AWS_REGION`, `ECR_REPOSITORY`, and approve the interactive prompt.
4. After the authorized run, inspect archived `ecr-image-reference.txt` and check the tag and digest directly with `aws ecr describe-images`.
5. Capture Jenkins job URL, source commit, registry digest, ECR repository settings and test reports.

## Operational constraints

- This job contains **no EKS deployment**.
- A full-commit SHA-derived immutable ECR tag means publishing the same source revision twice will fail by design.
- A successful Docker push does not prove deployability or container runtime health.
- `Jenkinsfile.ecr` is untested in Jenkins; the only confirmed Jenkins success so far is the build-only pipeline.
- For improved repeatability, the next security gates are base-image digest pinning, artifact provenance, dependency scanning and Jenkins library version pinning.
