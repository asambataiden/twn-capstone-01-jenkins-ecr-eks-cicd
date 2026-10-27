# Capstone 01 — DevOps Bootcamp Submission: Questions and Answers

**Project:** Jenkins CI/CD Pipeline with Amazon ECR and Amazon EKS  
**Bootcamp:** TechWorld with Nana — AI-Enhanced DevOps Bootcamp  
**Status:** Implemented and verified on 27 October 2026

> This summary answers the common project submission questions. It is grounded in the implementation and verified evidence in this repository; it does not quote an external bootcamp form or claim that unprovided official wording has been checked.

## Question 1 — What did you build?

I built and verified an end-to-end **CI/CD workflow for a Java 17 Spring Boot application** using GitHub, Jenkins, Maven, Docker, Amazon ECR and Amazon EKS.

The Jenkins pipeline uses a reusable Shared Library to execute Maven tests, package the application, create a Docker image, and publish it to a private ECR repository using an immutable Git-commit-based tag. It then resolves the image's SHA-256 digest and, after an explicit approval, can deploy that exact image into an existing Kubernetes Deployment on Amazon EKS.

I implemented separate AWS identities for ECR publishing and EKS deployment, configured an EKS access entry and namespace-scoped Kubernetes RBAC for the deployer, and hardened the runtime container with non-root execution, a read-only root filesystem, bounded writable temporary storage and restricted Linux privileges.

I also brought **four previously existing IAM/EKS access resources under Terraform management** using import blocks and configured encrypted, versioned S3 remote state with native locking.

**Verified results:** two Maven/JUnit tests passed; the ECR image was published and deployed by digest; the EKS Deployment was healthy at 1/1; Terraform imported four resources with zero additions, modifications or deletions and later reported no differences; Kubernetes manifest diffs returned zero; Gitleaks scanned 58 Git commits with no reported leaks; and the implementation was merged into `main` through PR #1.

**Scope:** The existing EKS cluster, nodes, ECR registry and Jenkins infrastructure were prerequisites; this project did not provision the whole platform from scratch.

## Question 2 — What did you learn?

I learned how the complete software delivery chain connects **source code, automated testing, immutable build artifacts, container registries and Kubernetes workloads**. I can explain the differences between a Git commit SHA, an ECR image tag, a SHA-256 image digest and a Kubernetes Deployment revision, and why deploying an approved digest improves traceability and controlled recovery.

I gained practical experience with Jenkins declarative pipelines, reusable Shared Libraries, approval gates, Maven test and packaging stages, Docker containerization, Amazon ECR and deployment verification in EKS. I also learned that a successful Jenkins job does not necessarily mean every optional stage ran, so release validation must inspect stage execution and the actually deployed artifact.

On security, I learned the differences between **AWS IAM authentication/authorization, EKS access entries and Kubernetes RBAC**. I implemented separate publish/deploy identities and learned to preserve container-hardening controls while resolving Tomcat's need for a writable `/tmp` directory.

On infrastructure engineering, I learned how Terraform imports existing cloud resources safely, why plan review is essential, and why the state backend needs encryption, versioning, access controls and locking. A real issue with a legacy IAM tag reinforced the importance of preventing unintended changes during infrastructure adoption.

Finally, I practiced incident analysis, validating infrastructure against Git, investigating a Gitleaks false positive without disabling scanning, documenting runbooks and closing the work through a reviewed pull request.

**Most important takeaway:** reliable DevOps is not just automation; it is also security, reproducibility, least privilege, validation, documentation and operational judgment.

## Question 3 — What is your GitHub repository URL?

**Primary public project repository:**  
https://github.com/asambataiden/twn-capstone-01-jenkins-ecr-eks-cicd

**Supporting reusable Jenkins Shared Library:**  
https://github.com/asambataiden/twn-devops-bootcamp-jenkins-shared-library

The primary link should be submitted in the bootcamp form. The Shared Library is a supporting dependency. The personal learning/tutorial repository is private and is **not** the public submission link.

## Key project references

- [Project overview and evidence](../README.md)
- [Canonical Jenkins release pipeline](../Jenkinsfile.ecr)
- [Deployment-only pipeline](../Jenkinsfile.deploy)
- [Kubernetes workload manifest](../k8s/capstone01-app.yaml)
- [Kubernetes deployer RBAC](../k8s/jenkins-deployer-rbac.yaml)
- [Terraform adoption runbook](../terraform/README.md)
- [CI/CD release runbook](ci-cd-release-runbook.md)
- [Merged pull request #1](https://github.com/asambataiden/twn-capstone-01-jenkins-ecr-eks-cicd/pull/1)

## Short version for a submission form

**What did you build?** I implemented a Jenkins-based CI/CD workflow for a Java Spring Boot application: Maven tests, Docker image creation, immutable publication to Amazon ECR, and approved digest-based deployment into an existing EKS cluster. I secured deployment with separate AWS identities, IAM/EKS/RBAC permissions and hardened Kubernetes settings, and imported four existing access resources into Terraform with protected S3 remote state. All core release and infrastructure checks were verified.

**What did you learn?** I learned end-to-end CI/CD, Jenkins Shared Libraries, Maven, Docker, immutable image digests, Kubernetes rollout validation, IAM/EKS/RBAC least privilege, safe Terraform import and remote state management, container hardening, secret scanning and evidence-driven troubleshooting.

**Repository URL:** https://github.com/asambataiden/twn-capstone-01-jenkins-ecr-eks-cicd
