# Capstone 01 — Jenkins CI/CD with Amazon ECR and EKS

**TechWorld with Nana · AI-Enhanced DevOps Bootcamp · Capstone 01**

A hands-on CI/CD implementation for a Java/Spring Boot service: test with Maven, build a non-root Docker image, publish to private Amazon ECR with immutable Git-based tags, then deploy an exact SHA-256 image digest to a pre-existing Amazon EKS cluster with Jenkins and a reusable Shared Library.

**Status: End-to-end build → ECR publish → EKS rollout verified on 27 October 2026.** This is a learning sandbox, not a production-hardened service. The EKS cluster and worker nodes are pre-existing; this repository does not create them.

## Architecture

```text
GitHub (source + Jenkinsfile.ecr)
   |
   v
Jenkins controller (DigitalOcean) -> trusted SSH agent twn-ecr-agent-01
   |                              |
   |                              +-- Maven verify (JUnit) -> package JAR
   |                              +-- Docker image build (non-root UID 10001)
   |                              +-- ECR publisher AWS identity -> immutable ECR tag
   |                              +-- Resolve and archive image@sha256:<digest>
   |                              +-- operator approval
   |                              +-- EKS deployer AWS identity -> EKS access entry
   |                                         -> namespace RBAC
   |                                         -> update existing Deployment
   |                                         -> rollout + observed digest verification
   v
Existing EKS cluster -> namespace capstone-01 -> Deployment/Service capstone01-app
```

The Shared Library implements `mavenVerify`, `mavenBuild`, `ecrBuild`, `ecrPush`, `ecrImageDigest` and `eksDeployVerified`: [Shared Library](https://github.com/asambataiden/twn-devops-bootcamp-jenkins-shared-library).

## Verified evidence

- **Date:** 2026-10-27.
- **Git commit used in completed integrated release:** `9d98c9b118fe076495489bb7dfa2aabddee96722`.
- **Build:** Maven `verify`, 2 JUnit tests passed, no test failures; Spring Boot 3.5.5 application packaged successfully.
- **ECR:** `591132357918.dkr.ecr.eu-north-1.amazonaws.com/twn-capstone-01/capstone01-app`, immutable Git tag based on the build commit.
- **Published / verified image digest:** `sha256:4b46edf007cb4ddc07d9c4004a8678d59c29c365be6f50d6aeb8ff433a516c78`.
- **EKS:** `floral-mongoose-1792497995` (`eu-north-1`), namespace `capstone-01`, Deployment and container `capstone01-app/app`.
- **Release verification:** Jenkins stage `Deploy published digest and verify rollout` reported rollout success and confirmed the deployed digest matches the ECR artifact.
- **Important qualification:** This release reused the same built image digest as an earlier run; it validates pipeline integration, not a change in application behavior. The Jenkins rollout checks do not replace post-release HTTP smoke tests.

## Repository guide

| File | Purpose |
| --- | --- |
| `Jenkinsfile.ecr` | Approved build, test, ECR publish, optional EKS rollout |
| `Jenkinsfile.deploy` | Independently deploy an existing immutable ECR digest |
| `k8s/capstone01-app.yaml` | Existing Deployment and internal ClusterIP Service |
| `k8s/jenkins-deployer-rbac.yaml` | Namespace-specific Jenkins Role and RoleBinding |
| `scripts/audit-capstone01.sh` | Read-only AWS/EKS configuration and workload audit |
| `docs/ci-cd-release-runbook.md` | Release procedure, validation and learning notes |
| `pom.xml`, `src/` | Java application and tests |
| `Dockerfile` | Container image with non-root process |

## CI/CD jobs and approvals

`twn-capstone-01-ecr-publish` reads `Jenkinsfile.ecr` from the feature branch. Set `ALLOW_ECR_PUBLISH=true` and supply the approved account, region and ECR repository. Set `ALLOW_EKS_DEPLOY=true` only when the deployment is intended. Review the separate ECR and EKS approval gates.

`twn-capstone-01-eks-deploy` reads `Jenkinsfile.deploy` and accepts an existing `sha256:...` digest. Use this to redeploy a previously published artifact without rebuilding it.

```text
AWS_ACCOUNT_ID = 591132357918
AWS_REGION     = eu-north-1
ECR_REPOSITORY = twn-capstone-01/capstone01-app
```

Images are tagged with `git-<full-commit-sha>`. ECR tag immutability is deliberately enforced; rerunning publication of the same commit may be rejected. Use the standalone deployment job instead of bypassing immutability.

## Local verification

Prerequisites: AWS CLI v2, `kubectl` compatible with EKS Kubernetes v1.34, permission to read this EKS cluster, and a **dedicated** local kubeconfig. Run from repository root:

```bash
export AWS_PROFILE=asambataiden-dev
export AWS_REGION=eu-north-1
export EKS_CLUSTER=floral-mongoose-1792497995
export KUBECONFIG="$HOME/.kube/twn-capstone01-eks.yaml"

bash scripts/audit-capstone01.sh

kubectl -n capstone-01 rollout status deployment/capstone01-app
kubectl -n capstone-01 get deployment,pods,services
kubectl -n capstone-01 get deployment capstone01-app \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="app")].image}{"\\n"}'
```

### Reproducing the runtime configuration

The cluster and ECR repository must exist before running the pipelines. Operators with appropriate access can review version-controlled Kubernetes definitions:

```bash
kubectl diff -f k8s/capstone01-app.yaml
kubectl diff -f k8s/jenkins-deployer-rbac.yaml
```

Do not automatically apply these files to a shared cluster without reviewing the diff. **IAM identities, policies and EKS access entries were configured outside this repository and are not yet managed by Terraform.** Rebuilding the *whole infrastructure* from this repository alone is therefore not yet supported. Terraform adoption/import is tracked as a follow-up, not presented as finished.

## Security design and trade-offs

- **Identity isolation:** Jenkins credentials `aws-twn-capstone01-ecr-publisher` and `aws-twn-capstone01-eks-deployer` are distinct; the latter can describe the cluster and is mapped to Kubernetes group `twn-capstone01-deployers`.
- **Least privilege:** `k8s/jenkins-deployer-rbac.yaml` restricts writes to the named `capstone01-app` Deployment in namespace `capstone-01`. Read permissions support rollout inspection.
- **Artifact integrity:** ECR tag immutability, explicit SHA-256 digest deployment, AWS account/cluster ARN verification and Jenkins approval gates.
- **Runtime:** non-root UID/GID 10001, dropped Linux capabilities, no privilege escalation, `RuntimeDefault` seccomp, read-only root filesystem with writable `emptyDir` at `/tmp`, resource requests/limits and readiness/liveness probes.
- **Lab limitations:** Jenkins uses long-lived IAM access keys stored in its credentials store, and the Jenkins controller is currently exposed over HTTP. In production use HTTPS, restricted Jenkins access, trusted isolated build agents and temporary workload credentials. Docker socket/group access on the agent is effectively root-equivalent.

## Troubleshooting and lessons learned

**Read-only filesystem failure:** Spring Boot/Tomcat needed `/tmp`; mounting bounded `emptyDir` at `/tmp` preserved an otherwise read-only root filesystem.

**Unexpected Kubernetes context:** `kubectl` initially targeted an inactive local cluster. Setting explicit `KUBECONFIG` avoided accidental context drift.

**RBAC validation failure:** `kubectl auth can-i get deployments` asks for broad permissions; the named-resource restriction requires `kubectl auth can-i get deployment/capstone01-app -n capstone-01`.

**Jenkins first build:** SCM-sourced Declarative Pipeline parameters may appear only after the first build has registered them. Authorization defaults remain disabled.

**EKS stages skipped:** Overall `SUCCESS` can mean the optional EKS stages did not run; inspect stage-specific logs.

**Immutable ECR tags:** A previously published `git-<SHA>` tag cannot be republished; use deployment-only for the existing image.

### What I learned

1. CI validates source and packages immutable artifacts; CD promotes a precise artifact into an environment.
2. AWS IAM controls AWS API permissions, EKS access entries map identities into Kubernetes, and Kubernetes RBAC grants namespace/resource-specific operations.
3. Narrowly scoped publish and deploy identities reduce blast radius compared with one administrator credential.
4. Deployment status, observed container digest and application health each provide different verification signals.
5. Manual discovery is useful, but working commands, access definitions and troubleshooting decisions should become version-controlled automation and runbooks.

## Related repositories

- [Jenkins Shared Library](https://github.com/asambataiden/twn-devops-bootcamp-jenkins-shared-library)
- [Earlier EKS/Maven/Jenkins bootcamp exercise](https://github.com/asambataiden/twn-devops-bootcamp-11-eks-java-maven-app-tree-jenkins-jobs)

## Next improvements

- Adopt existing IAM/EKS access resources through reviewed Terraform imports and state management; **never recreate the live cluster casually**.
- Add automated post-deployment HTTP smoke testing, release evidence collection and tested rollback procedures.
- Replace long-lived IAM keys with short-lived credentials and secure Jenkins with HTTPS.
- Pin and scan container base images and modernize the Docker BuildKit/buildx invocation.
