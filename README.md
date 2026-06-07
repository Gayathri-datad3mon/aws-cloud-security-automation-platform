# AWS Cloud Security Automation Platform

## Project Overview

The AWS Cloud Security Automation Platform is a cloud security monitoring and DevSecOps project designed to demonstrate how security controls, infrastructure automation, continuous integration, continuous deployment, vulnerability management, and cloud-native monitoring can be integrated into a single AWS environment.

The project was built using Infrastructure as Code (IaC) with Terraform and deployed in AWS. Security monitoring is implemented through CloudTrail, EventBridge, Lambda, SNS, CloudWatch Logs, and SQS. Security validation is integrated into the development lifecycle using GitHub Actions, Checkov, and Trivy.

The primary goal of this project is to automate cloud security monitoring while demonstrating secure infrastructure deployment practices and DevSecOps workflows.

---

# Business Problem

Organizations often face several cloud security challenges:

* Lack of visibility into cloud activities.
* Delayed detection of suspicious changes.
* Manual infrastructure deployment.
* Configuration drift across environments.
* Limited security validation before deployment.
* Absence of automated vulnerability scanning.

Without automation, security teams spend significant time manually reviewing logs, validating infrastructure configurations, and responding to incidents.

This project addresses these challenges by automating security monitoring, infrastructure deployment, and security validation.

---

# Project Objectives

The primary objectives of this project were:

* Automate AWS infrastructure deployment.
* Monitor security-relevant AWS events.
* Generate automated security alerts.
* Implement Infrastructure as Code.
* Integrate security scanning into CI/CD.
* Maintain centralized infrastructure state.
* Demonstrate modern DevSecOps practices.

---

# Technologies Used

## Cloud Platform

* Amazon Web Services (AWS)

## Infrastructure as Code

* Terraform

## Security Monitoring

* AWS CloudTrail
* Amazon EventBridge
* AWS Lambda
* Amazon SNS
* Amazon CloudWatch Logs
* Amazon SQS

## DevSecOps

* GitHub Actions
* Checkov
* Trivy
* Docker

## State Management

* Amazon S3
* Amazon DynamoDB

---

# Architecture Overview

## CI/CD Pipeline

GitHub
↓
GitHub Actions
↓
Terraform Validation
↓
Checkov Security Scan
↓
Docker Build
↓
Trivy Vulnerability Scan
↓
Terraform Plan
↓
Terraform Apply
↓
AWS Infrastructure Updated

---

## Runtime Security Monitoring

CloudTrail
↓
EventBridge
↓
Lambda
↓
SNS
↓
Email Notification

---

## Terraform Backend

Terraform
↓
S3 Remote State
↓
DynamoDB State Locking

---

# File Structure

aws-cloud-security-automation-platform/

├── .github/

│ └── workflows/

│ └── terraform-ci.yml

├── terraform/

│ ├── main.tf

│ ├── backend.tf

│ └── terraform.tfvars

├── lambda/

│ └── security_alert.py

├── Dockerfile

├── .dockerignore

└── README.md

---

# Detailed File Explanation

## terraform/main.tf

This is the core infrastructure definition file.

Purpose:

* Creates AWS resources.
* Defines security controls.
* Configures monitoring services.
* Defines event processing logic.

Resources created:

* S3 Bucket
* CloudTrail
* CloudWatch Log Group
* SNS Topic
* Lambda Function
* EventBridge Rules
* IAM Roles
* SQS Dead Letter Queue

Without this file, no infrastructure would be deployed.

---

## terraform/backend.tf

Purpose:

Store Terraform state remotely. 
Terraform initially stored state locally, which prevented GitHub Actions from accurately tracking deployed infrastructure. I migrated the state to an S3 backend to provide centralized state management and implemented DynamoDB state locking to prevent concurrent Terraform operations from corrupting the state file. This enabled safe collaboration between local development and CI/CD deployments while maintaining a single source of truth for infrastructure.

Configuration:

* S3 Bucket Backend
* DynamoDB Locking

Benefits:

* Prevents state loss.
* Enables team collaboration.
* Prevents simultaneous deployments.

Without backend configuration:

* State remains local.
* GitHub Actions cannot track infrastructure.
* Multiple deployments may corrupt state.

---

## lambda/security_alert.py

Purpose:

Processes security events received from EventBridge.

Responsibilities:

* Receives event payload.
* Extracts event information.
* Formats security alert.
* Publishes notification to SNS.

This is the project's security automation engine.

---

## .github/workflows/terraform-ci.yml

Purpose:

Automates infrastructure validation and deployment.

Pipeline Stages:

1. Checkout Repository
2. Configure AWS Credentials
3. Terraform Init
4. Terraform Validate
5. Checkov Scan
6. Docker Build
7. Trivy Scan
8. Terraform Plan
9. Terraform Apply

This file implements CI/CD.

---

## Dockerfile

Purpose:

Containerizes the Lambda application.

Take Lambda Python code
    ↓
Package it into a container image
    ↓
Allow Trivy to scan it for vulnerabilities

Benefits:

* Reproducible environment.
* Vulnerability scanning.
* Future container deployment support.

---

## .dockerignore

Purpose:

Prevents unnecessary files from entering Docker images.

.dockerignore reduces Docker image size, speeds up builds, prevents sensitive files such as Terraform state from being included in container images, and minimizes the attack surface for security scanning.

Benefits:

* Smaller image size.
* Faster builds.
* Reduced attack surface.

---

# Security Controls Implemented

## CloudTrail

Purpose:

Record all AWS API activity.

Benefits:

* Auditability.
* Incident investigations.
* Compliance support.

---

## CloudWatch Logs

Purpose:

Centralized log collection.

Benefits:

* Log retention.
* Monitoring.
* Event correlation.

---

## EventBridge

Purpose:

Detect specific security events.

Examples:

* IAM User Creation
* Role Changes
* Policy Modifications

---

## Lambda

Purpose:

Automate response actions.

Benefits:

* Real-time processing.
* Serverless architecture.
* Reduced operational overhead.

---

## SNS

Purpose:

Deliver notifications.

Benefits:

* Email alerts.
* Event distribution.
* Rapid awareness.

---

## SQS Dead Letter Queue

Purpose:

Store failed Lambda events.

Benefits:

* Prevent data loss.
* Improve reliability.
* Support troubleshooting.

---

# Infrastructure Security Validation

## Checkov

Purpose:

Scan Terraform code for security misconfigurations.

Checks performed:

* Encryption
* Logging
* IAM Security
* Public Access
* CloudTrail Configuration

Benefits:

* Prevent insecure deployments.
* Shift security left.

---

## Trivy

Purpose:

Scan Docker images for vulnerabilities.

Detects:

* Critical vulnerabilities
* High vulnerabilities
* Known CVEs

Benefits:

* Secure container deployments.
* Vulnerability visibility.

---

# Remote State Management

## Why Remote State Was Needed

Initially Terraform state was stored locally.

Problems:

* GitHub Actions could not see infrastructure.
* Duplicate resource creation attempts occurred.
* Infrastructure tracking became unreliable.

Solution:

* S3 Remote State
* DynamoDB Locking

Benefits:

* Centralized state.
* Team collaboration.
* Safe deployments.

---

# Major Challenges Encountered

## Challenge 1: Git Push Rejections

Issue:

Remote repository contained changes not available locally.

Error:

Non-fast-forward update rejection.

Solution:

* Git Pull Rebase
* Conflict Resolution
* Rebase Completion

Outcome:

Repository synchronization restored.

---

## Challenge 2: Terraform State Management

Issue:

GitHub Actions attempted to recreate existing resources.

Examples:

* S3 Buckets
* IAM Roles
* CloudWatch Log Groups

Root Cause:

State stored locally.

Solution:

* S3 Backend
* DynamoDB Lock Table

Outcome:

Consistent infrastructure tracking.

---

## Challenge 3: CloudWatch and KMS Integration

Issue:

CloudWatch Log Group KMS association failed.

Cause:

Improper KMS configuration.

Solution:

* KMS key validation.
* Correct resource references.

Outcome:

Successful log group encryption.

---

## Challenge 4: CloudTrail SNS Policy Errors

Issue:

CloudTrail could not publish notifications.

Error:

InsufficientSnsTopicPolicyException

Solution:

* Updated SNS topic policies.
* Added required permissions.

Outcome:

Successful CloudTrail integration.

---

## Challenge 5: Excessive Email Notifications

Issue:

Hundreds of email alerts generated.

Cause:

S3 ObjectCreated notifications triggered for every CloudTrail log file.

Solution:

* Removed S3 notification configuration.
* Relied on EventBridge-based security alerts.

Outcome:

Meaningful alerting without notification flooding.

---

## Challenge 6: Docker Build Failures

Issue:

GitHub Actions could not locate Dockerfile.

Cause:

Workflow executed from terraform directory.

Solution:

* Adjusted Docker build path.
* Referenced repository root.

Outcome:

Successful container builds.

---

# End-to-End Workflow

## Infrastructure Deployment Flow

Developer Updates Code
↓
GitHub Commit
↓
GitHub Actions Triggered
↓
Terraform Validation
↓
Checkov Security Scan
↓
Docker Build
↓
Trivy Vulnerability Scan
↓
Terraform Plan
↓
Terraform Apply
↓
AWS Infrastructure Updated

---

## Security Monitoring Flow

AWS Activity Occurs
↓
CloudTrail Records Activity
↓
EventBridge Detects Event
↓
Lambda Processes Event
↓
SNS Publishes Alert
↓
Email Notification Sent

---

## State Management Flow

Terraform
↓
S3 Remote State
↓
DynamoDB Locking
↓
Safe Infrastructure Updates

---

# Key Learning Outcomes

This project provided hands-on experience with:

* Infrastructure as Code
* AWS Security Monitoring
* Cloud Security Architecture
* DevSecOps Practices
* CI/CD Pipelines
* Security Automation
* Cloud Logging
* Vulnerability Management
* Remote State Management
* Event-Driven Security Monitoring

---

# Future Enhancements

Potential future improvements include:

* Kubernetes Security Monitoring
* Falco Runtime Detection
* Security Hub Integration
* GuardDuty Integration
* Automated Incident Response
* Slack Alerting
* Security Dashboard Development
* Multi-Account Monitoring

---

# Conclusion

This project demonstrates the implementation of a secure, automated, cloud-native security monitoring platform using AWS, Terraform, GitHub Actions, Checkov, Trivy, and serverless technologies. The solution combines infrastructure automation, continuous security validation, event-driven monitoring, and DevSecOps practices to provide an end-to-end security monitoring framework suitable for modern cloud environments.
