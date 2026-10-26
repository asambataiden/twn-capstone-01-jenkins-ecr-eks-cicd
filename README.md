# Capstone 01 — Jenkins CI/CD to Amazon ECR and EKS

**TechWorld with Nana · DevOps Bootcamp · Capstone 01**

Build, verify, containerize and deploy a Java service through a reusable Jenkins Shared Library, using immutable Amazon ECR image digests and a verified EKS target.

> **Project status:** Repository foundation initialized. Source and pipeline are not yet executed or proven against Jenkins/AWS/EKS. No infrastructure is provisioned by this repository.

## Architecture

```text
GitHub (application)
  → Jenkins (trusted agent)
  → Shared Library
  → Maven verify/package
  → Docker image build
  → ECR immutable-tag publish
  → ECR manifest digest lookup
  → Manual release approval / authorized release
  → Verified EKS identity + digest-pinned rollout
  → Deployment and application health checks
```

## Repository organization

- `Jenkinsfile`: pipeline entry point (publish/deploy disabled by default)
- `pom.xml`, `src/`: application source and tests
- `Dockerfile`: container packaging
- `kubernetes/`: desired-state manifests; do not blindly apply from CI
- `docs/`: architecture, threat assumptions, runbooks and evidence

## Related work

- [Reusable Shared Library](https://github.com/asambataiden/twn-devops-bootcamp-jenkins-shared-library)
- [Historical bootcamp exercise](https://github.com/asambataiden/twn-devops-bootcamp-11-eks-java-maven-app-tree-jenkins-jobs)

This is an **independent** capstone repository. Historical exercises remain unchanged and are references only.

## Security and release constraints

- Use least-privilege, short-lived AWS credentials on isolated trusted Jenkins agents.
- Require an existing immutable ECR repository; never overwrite an existing tag.
- Pin the deployed image by registry SHA-256 digest.
- Verify AWS account and EKS cluster ARN; isolate temporary kubeconfig.
- Keep deployments manual/approved until CI, identity verification and runtime integration pass.
- Do not push credentials or overwrite application version files from the pipeline.
- Distinguish mocked/local tests from actual Jenkins/ECR/EKS deployment evidence.

## Status and next milestones

1. Import or rebuild the sample Java/Maven application with meaningful unit tests.
2. Add reproducible Docker packaging and reviewed Kubernetes manifests.
3. Create a Jenkinsfile that calls the tested Shared Library functions.
4. Run local Maven/container tests, then Jenkins dry run.
5. Validate in a disposable approved AWS sandbox and capture verifiable rollout evidence.
