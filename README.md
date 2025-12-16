# Cloudzenia – Terraform Hands-on Assignment
## Section 1 - ECS with ALB, RDS and SecretsManager
## Overview
This project provisions AWS infrastructure using Terraform, including:
- VPC with public and private subnets
- ECS (Fargate) services
- Application Load Balancer
- RDS MySQL
- AWS Secrets Manager
- CI/CD using GitHub Actions

## Architecture
![Architecture](architecture-diagram.png)

## Infrastructure Components
- VPC with 2 public and 2 private subnets
- ALB in public subnets
- ECS services (WordPress + Microservice) in private subnets
- RDS MySQL in private subnet
- Secrets Manager for DB credentials
- IAM roles with least privilege

## CI/CD
GitHub Actions builds and pushes Docker images to ECR and triggers ECS redeployment.

## Endpoints
- WordPress: http://wordpress.example.com
- Microservice: http://microservice.example.com

## Security
- RDS credentials stored in AWS Secrets Manager
- ECS task role grants least-privilege access
- Private subnets for ECS and RDS

## HTTPS / SSL
HTTPS using ACM and Route53 was part of the design.
Due to domain ownership constraints during the assignment,
the ALB is configured with HTTP.
The architecture fully supports HTTPS by attaching a validated ACM certificate.

## Cleanup
All resources can be removed using:
terraform destroy

## Section 2 – EC2 with NGINX and Docker

This section demonstrates traditional server-based architecture.

- Two EC2 instances deployed in private subnets
- Docker runs a container responding “Namaste from Container”
- NGINX serves static content and proxies traffic to Docker
- Traffic routed through ALB using host-based routing

HTTPS, Let’s Encrypt, and advanced observability were designed but scoped
due to time constraints.
