# Jenkins integration candidate

This Jenkinsfile is **not deployed or validated in Jenkins**. The branch `feat/jenkins-ecr-eks-pipeline` is for development; publishing is additionally disabled by default, restricted to `main`, and requires explicit approval.

## Library configuration

Configure the global Jenkins Pipeline Library name `twn-devops-bootcamp-jenkins-shared-library`, pointing to the actual [Shared Library repository](https://github.com/asambataiden/twn-devops-bootcamp-jenkins-shared-library). The feature-branch revision is for testing only; **pin to a reviewed immutable commit or tag** before approving any release. Jenkins runtime/CPS compatibility must be tested separately.

## Required Jenkins agent

Agent label `docker-aws-kubectl`, with compatible Java 17+, configured Maven tool named `maven-3.9`, Docker daemon, AWS CLI v2, kubectl, access to the source checkout and a trusted temporary environment. Use short-lived IAM role credentials rather than static keys in pipeline source.

## Existing AWS resources required

The default account `591132357918`, region `eu-north-1`, ECR repository `twn-devops-bootcamp/java-maven-app` are historical bootcamp values **not yet reverified**. Adjust only after confirming approved sandbox configuration. ECR repo must be immutable, the target EKS cluster and namespace must already exist and the Deployment/container must be named `capstone01-app`. AWS permissions and namespace-scoped Kubernetes RBAC must permit precisely those actions. Ensure EKS nodes can pull from ECR.

## Risk boundaries

- No cloud publish or deploy when `PUBLISH_AND_DEPLOY=false`.
- `ecrBuild` runs Docker build even in non-release builds.
- Avoid privileged Jenkins workers for untrusted PRs: pipeline branch gates alone do not prevent malicious Jenkinsfile code from accessing agent permissions.
- An immutable ECR tag cannot be pushed twice. Digest verification and release repeatability must be reviewed.
- The Kubernetes Deployment manifest uses an intentionally invalid placeholder image. Provision it through an **approved IaC/manual bootstrap process** with a real pinned image. Do not blindly apply it or substitute untrusted input.
- The checked-in manifests do not perform resource creation as part of CI; the Shared Library only updates a pre-existing Deployment's container.
- Successful Kubernetes rollout status must be followed by independent application health validation; automated acceptance proof remains pending.
- Real Jenkins, GitHub Actions, ECR and EKS integration is unverified.

## Local commands

```bash
mvn -B -ntp clean verify
docker build --pull -t capstone01-app:local .
docker run --rm --read-only -p 8080:8080 capstone01-app:local
```

From a second terminal, test `curl --fail http://localhost:8080/api/status` and `curl --fail http://localhost:8080/actuator/health`. Stop Docker with Ctrl+C.

For the first Jenkins test, use a **nonprivileged agent** and `PUBLISH_AND_DEPLOY=false`, and collect the actual Jenkins log and build URL.


## First Jenkins job: build-only validation (Phase 10.1)

Use `Jenkinsfile.ci` for the **first** execution, not the release-oriented `Jenkinsfile`. It has no calls to AWS, Amazon ECR, `kubectl`, or deployment functions. It still performs a local Docker image build.

1. Install/configure Jenkins Pipeline, Git, and the Pipeline: Groovy Libraries support (check versions against your Jenkins LTS and plugins).
2. In **Manage Jenkins → System → Global Pipeline Libraries**, configure library name `twn-devops-bootcamp-jenkins-shared-library` with Git source `https://github.com/asambataiden/twn-devops-bootcamp-jenkins-shared-library.git` (or SSH with scoped read credentials). Make sure the library can resolve branch `feat/library-foundation`. Disable implicit loading if not required.
3. Configure a Maven tool named `maven-3.9` in **Manage Jenkins → Tools**, or adjust that name in the Jenkinsfile to your actual installation.
4. Set up a reviewed, trusted and isolated build worker with a label `docker-aws-kubectl` and working Java 17+, Maven, Git, and Docker daemon access. Despite the label, **no AWS permissions are required for this job**. Avoid giving this initial worker AWS role credentials. Jenkins' Docker permissions are highly privileged; use an isolated worker.
5. Create **New Item → Pipeline** (e.g. `twn-capstone-01-build-only`).
6. Under **Pipeline → Definition**, select **Pipeline script from SCM**; SCM **Git**; repository URL `https://github.com/asambataiden/twn-capstone-01-jenkins-ecr-eks-cicd.git` or the configured SSH alias/credentials; branch specifier `*/feat/jenkins-ecr-eks-pipeline`; **Script Path** `Jenkinsfile.ci`.
7. Save and select **Build Now**. Check the Console Output and confirm the build executed `mavenVerify()`, `mavenBuild(skipTests: true)`, and the local-only Docker image build.
8. Save the Jenkins build URL, console outcome, source commit SHA and test reports as evidence. Do not claim success before execution.

Potential setup issues: missing worker label means Jenkins will queue indefinitely; unknown `maven-3.9` causes a tool error; missing Shared Library or library Git checkout blocks pipeline compilation; Maven test failures stop packaging; Docker daemon permissions may block the final stage.

Once the build-only run is green, assess Jenkins version/plugin compatibility, branch trust and short-lived AWS identity before testing the separate release pipeline.
