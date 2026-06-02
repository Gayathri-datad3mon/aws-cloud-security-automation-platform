# AWS Cloud Security Automation Platform

### Real-Time IAM Threat Detection and Security Alerting using Terraform, CloudTrail, EventBridge, Lambda, SNS, and S3

---

# Project Overview

This project demonstrates how to build a cloud-native security monitoring and automation platform on AWS using Infrastructure as Code (IaC) with Terraform.

The platform continuously monitors AWS account activity, detects critical IAM security events, automatically formats security alerts, and sends real-time notifications to security analysts.

The entire environment is deployed and managed using Terraform and operates within AWS Free Tier limits.

---

# Business Problem

In cloud environments, unauthorized IAM activities can lead to:

* Privilege escalation
* Unauthorized user creation
* Backdoor account creation
* Credential theft
* Persistence mechanisms

Security teams need a way to:

* Monitor IAM activities
* Detect suspicious actions
* Receive real-time alerts
* Maintain audit logs
* Automate incident notification

This project solves that problem.

---

# Project Architecture

```text
┌────────────────────┐
│ AWS IAM            │
│ CreateUser Event   │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ AWS CloudTrail     │
│ Audit Logging      │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ EventBridge        │
│ Event Detection    │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ AWS Lambda         │
│ Alert Formatter    │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ SNS Topic          │
│ Alert Distribution │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Email Notification │
└────────────────────┘
```

---

# Technologies Used

| Technology      | Purpose                |
| --------------- | ---------------------- |
| Terraform       | Infrastructure as Code |
| AWS S3          | Log Storage            |
| AWS CloudTrail  | Audit Logging          |
| AWS EventBridge | Event Detection        |
| AWS Lambda      | Serverless Processing  |
| AWS SNS         | Alert Notification     |
| IAM             | Identity Monitoring    |
| GitHub          | Version Control        |

---

# What is Terraform?

Terraform is an Infrastructure as Code (IaC) tool developed by HashiCorp.

Instead of manually creating cloud resources through the AWS Console, Terraform allows infrastructure to be defined using code.

Example:

```hcl
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "gayathri-cloud-security-platform-2026"
}
```

Benefits:

* Automation
* Repeatability
* Version Control
* Consistency
* Reduced Human Error

---

# Phase 1 – Secure S3 Storage

## Objective

Create a secure storage location for CloudTrail logs.

---

## Why S3?

Amazon S3 is an object storage service used to store:

* Audit logs
* Backups
* Security data
* CloudTrail records

---

## Bucket Creation

```hcl
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "gayathri-cloud-security-platform-2026"
}
```

Creates:

```text
S3 Bucket
```

---

## Versioning

```hcl
resource "aws_s3_bucket_versioning" "versioning"
```

Purpose:

```text
Protects against:
- Accidental deletion
- File overwrite
- Log tampering
```

---

## Encryption

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration"
```

Purpose:

```text
Encrypts logs at rest
AES-256 Encryption
```

---

## Public Access Block

```hcl
resource "aws_s3_bucket_public_access_block"
```

Purpose:

```text
Prevents:
- Public bucket exposure
- Anonymous access
- Data leakage
```

---

# Phase 2 – CloudTrail Logging

## What is CloudTrail?

AWS CloudTrail records API activity occurring within AWS.

Examples:

```text
CreateUser
DeleteUser
CreateAccessKey
AttachUserPolicy
StartInstances
StopInstances
```

---

## CloudTrail Configuration

```hcl
resource "aws_cloudtrail" "security_trail"
```

---

### Important Parameters

```hcl
include_global_service_events = true
```

Captures:

```text
IAM Events
```

IAM is a global service.

---

```hcl
is_multi_region_trail = true
```

Captures:

```text
All AWS Regions
```

---

## S3 Bucket Policy

CloudTrail needs permission to write logs.

```hcl
resource "aws_s3_bucket_policy"
```

Allows:

```text
CloudTrail
      ↓
S3 Bucket
```

---

## Lifecycle Policy

```hcl
resource "aws_s3_bucket_lifecycle_configuration"
```

Deletes logs after:

```text
7 days
```

Reason:

```text
Free Tier Cost Optimization
```

---

# Phase 3 – Event Detection

## What is EventBridge?

EventBridge is AWS's event routing service.

It acts like:

```text
IF event happens
THEN perform action
```

---

## Event Rule

```hcl
resource "aws_cloudwatch_event_rule"
```

Monitors:

```text
CreateUser
DeleteUser
CreateAccessKey
DeleteAccessKey
AttachUserPolicy
PutUserPolicy
CreateLoginProfile
```

These events are important because attackers frequently use them for persistence.

---

## Example Detection

```text
User Creates New IAM Account
      ↓
CloudTrail Logs Event
      ↓
EventBridge Detects Event
```

---

# Phase 4 – SNS Alerting

## What is SNS?

SNS = Simple Notification Service

Purpose:

```text
Send alerts
Send emails
Send SMS
Notify applications
```

---

## Topic Creation

```hcl
resource "aws_sns_topic"
```

Creates:

```text
security-alerts
```

---

## Email Subscription

```hcl
resource "aws_sns_topic_subscription"
```

Subscribes:

```text
gayathrinaidu1999@gmail.com
```

---

# Initial Problem

Originally:

```text
CloudTrail
      ↓
EventBridge
      ↓
SNS
```

Generated emails like:

```json
{
 "eventName":"CreateUser",
 "eventSource":"iam.amazonaws.com"
}
```

Very difficult for analysts to read.

---

# Phase 5 – Lambda Automation

## What is Lambda?

AWS Lambda is a serverless compute service.

Benefits:

```text
No Servers
No Patching
Pay-per-use
Automatic Scaling
```

---

## Lambda Function

File:

```text
security_alert.py
```

Purpose:

```text
Parse CloudTrail Event
Extract Important Information
Generate Human Readable Alert
```

---

## Code Logic

Receives:

```json
{
 "eventName":"CreateUser"
}
```

Extracts:

```text
Actor
Target User
Source IP
Region
```

Creates:

```text
SECURITY ALERT

Event: CreateUser
Actor: security-admin
Target User: test-alert-013
Source IP: 35.144.68.201
Region: us-east-1
```

---

## SNS Publishing

Lambda sends:

```python
sns.publish()
```

to:

```text
security-alerts Topic
```

---

# Final Architecture

```text
IAM Event
      ↓
CloudTrail
      ↓
EventBridge
      ↓
Lambda
      ↓
SNS
      ↓
Email Alert
```

---

# Problems Encountered and Resolutions

## Problem 1 – CloudTrail Events Missing

Issue:

```text
CreateUser events not visible
```

Cause:

```text
Resources deployed in us-east-2
IAM events viewed in us-east-1
```

Solution:

```text
Moved entire deployment to us-east-1
Enabled Multi-Region Trail
```

---

## Problem 2 – EventBridge Not Triggering

Issue:

```text
No alerts generated
```

Cause:

```text
Event pattern too restrictive
```

Solution:

```text
Verified CloudTrail logs
Validated EventBridge rule
Updated pattern
```

---

## Problem 3 – Raw JSON Emails

Issue:

```text
Unreadable security alerts
```

Solution:

```text
Added Lambda Formatter
```

---

## Problem 4 – SNS Permissions

Issue:

```text
Lambda unable to publish alerts
```

Solution:

```hcl
aws_iam_role_policy
```

Added:

```text
sns:Publish
```

Permission.

---

## Problem 5 – Region Mismatch

Issue:

```text
CloudTrail
EventBridge
SNS
Different Regions
```

Solution:

```text
Standardized everything in us-east-1
```

---

# Commands Used

## Terraform Initialization

```powershell
terraform init
```

Downloads AWS provider plugins.

---

## View Deployment Plan

```powershell
terraform plan
```

Shows resources to be created.

---

## Deploy Infrastructure

```powershell
terraform apply
```

Creates resources.

---

## View State

```powershell
terraform state list
```

Displays managed resources.

---

## Destroy Resources

```powershell
terraform destroy
```

Deletes infrastructure.

---

# Git Commands Used

## Add Files

```powershell
git add .
```

---

## Commit Changes

```powershell
git commit -m "Completed AWS Cloud Security Automation Platform"
```

---

## Push to GitHub

```powershell
git push origin main
```

---

# Security Use Cases

Detect:

```text
Unauthorized IAM User Creation
Credential Creation
Policy Attachments
Privilege Escalation Attempts
Backdoor User Accounts
```

---

# Skills Demonstrated

### Cloud Security

```text
AWS IAM
CloudTrail
SNS
EventBridge
Lambda
```

### Infrastructure as Code

```text
Terraform
```

### Security Operations

```text
Threat Detection
Monitoring
Alerting
Automation
```

### Detection Engineering

```text
Event Correlation
Alert Generation
Security Monitoring
```

---

# Key Learning Outcomes

* Infrastructure as Code using Terraform
* AWS Security Service Integration
* Audit Logging with CloudTrail
* Event-Driven Security Monitoring
* Serverless Security Automation
* Real-Time Alerting
* IAM Threat Detection
* Cloud Security Architecture Design

---

# Final Result

Successfully built a **fully automated AWS Cloud Security Monitoring and Alerting Platform** that:

✅ Detects IAM security events
✅ Stores audit logs securely
✅ Automates event processing
✅ Generates human-readable security alerts
✅ Sends real-time notifications
✅ Uses Infrastructure as Code
✅ Operates within AWS Free Tier limits

This project demonstrates practical cloud security engineering, security automation, detection engineering, and infrastructure-as-code skills applicable to Security Engineer, Cloud Security Engineer, SOC Engineer, and Detection Engineer roles.
