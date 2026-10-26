# Implementation plan

## Phase A — Application
- Minimal maintainable Java web service with health endpoint and unit tests.
- Explicit JDK and Maven compiler compatibility; test evidence.
- Container packaging with non-root user, suitable base image and reproducible dependencies.

## Phase B — Deployment definitions
- Kubernetes Deployment and Service manifests with resource requests/limits and probes.
- Immutable image supplied by the approved delivery process.
- Namespace/RBAC and ECR pull authorization reviewed separately.

## Phase C — Jenkins integration
- Checkout a reviewed revision.
- Invoke `mavenVerify`, `mavenBuild`, `ecrBuild`, `ecrPush`, `ecrImageDigest`, `eksDeployVerified` from the Shared Library.
- Ensure package and Docker build run on the same workspace/agent.
- Enforce restricted branch, approval and scoped cloud identity before release.

## Phase D — Verification
- Maven tests locally and CI checks on Java baseline.
- Shell-mocked Jenkins Shared Library test suite (already maintained separately).
- Jenkins script/CPS validation in an isolated job.
- Controlled AWS sandbox ECR push and EKS rollout, readiness and rollback exercises.

**Current status:** only repository foundation committed; completion claims require recorded evidence.
