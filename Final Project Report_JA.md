# Final Project Report

Cloud-Native Three-Tier Web Application on AWS using Terraform & Jenkins

Author: John Adams  
Institution: [University/College Name]  
Course: Capstone Project  
Date: November 29, 2025

---

## Executive Summary

This project report documents the end-to-end design, implementation, and operation of a secure, scalable, three-tier web application deployed on Amazon Web Services (AWS) using Terraform (Infrastructure-as-Code) and a Jenkins CI/CD pipeline. The solution includes VPC networking, IAM, a web tier with an Elastic Load Balancer and Auto Scaling Group (ASG), an Aurora MySQL database tier, and a monitoring tier leveraging Grafana and a custom dashboard. Security best practices, automated deployments, verification steps, and operational procedures are covered in depth.

---

## Table of Contents

- 1. Introduction
- 2. Objectives & Scope
- 3. Literature Review
- 4. Requirements
- 5. System Architecture
- 6. Infrastructure-as-Code (Terraform)
- 7. CI/CD with Jenkins
- 8. Security Architecture
- 9. Monitoring & Observability
- 10. Implementation Details
- 11. Testing & Verification
- 12. Performance & Scalability
- 13. Cost Estimation
- 14. Risk Assessment & Mitigation
- 15. Challenges & Resolutions
- 16. Operations & Maintenance
- 17. Backup & Disaster Recovery
- 18. Compliance & Governance
- 19. Future Enhancements
- 20. Conclusion
- References
- Appendices

---

## 1. Introduction

Cloud adoption has driven a paradigm shift from manual infrastructure provisioning to declarative Infrastructure-as-Code (IaC). This project embraces IaC using Terraform to provision AWS resources and Jenkins to orchestrate secure deployments. The application is a car dealership platform featuring vehicle inventory, filters, modals for details, and customer inquiry forms—all served by PHP on Amazon Linux.

---

## 2. Objectives & Scope

- Design a secure 3-tier architecture on AWS
- Automate provisioning using Terraform modules (VPC, IAM, DB, Web, Monitoring)
- Implement a robust Jenkins pipeline with staged deployments and rollbacks
- Adopt least-privilege security and secret management via Jenkins credentials
- Deliver UI enhancements and maintain app reliability (HTTP 200 from ELB)

---

## 3. Literature Review

Industry sources (Fowler, Brikman, Humble & Farley, Puppet, Forsgren et al.) highlight benefits of three-tier architectures, IaC, and DevOps, including deployment speed, reliability, and reproducibility.

---

## 4. Requirements

- Functional: Vehicle listing, details modal, inquiry forms
- Non-functional: Scalability, availability, security, observability
- Constraints: EC2 user data ≤ 16KB, AWS quotas, budget-conscious instance sizes
- Region: us-east-1
- Runtime: PHP 7.4, Aurora MySQL 8.x

---

## 5. System Architecture

Overview of VPC, subnets, IGW, NAT, ELB, ASG, EC2, Aurora, SGs, IAM, Monitoring.

| Tier | Key Components |
|------|----------------|
| Web | ELB, ASG (t3.micro), EC2 with Apache/PHP, instance SG |
| DB | Aurora MySQL Cluster (private subnets), DB SG |
| Monitoring | EC2 (t2.nano), Grafana, monitoring SG |
| IAM | EC2 role, instance profile (SSM access) |

---

## 6. Infrastructure-as-Code (Terraform)

Modular Terraform design with clear inputs/outputs and conditional deployment flags.

- Module: vpc – subnets, routes, IGW, NAT, AZ selection (excludes us-east-1e)
- Module: iam – EC2 role, SSM policy, instance profile
- Module: db – Aurora cluster & instance, subnet group, SG, outputs
- Module: web – ELB, SGs, Launch Template, ASG, user_data GitHub clone
- Module: monitoring – SG and EC2 for Grafana & dashboard

---

## 7. CI/CD with Jenkins

Declarative pipeline with stages: Initialize, Plan Infrastructure, Deploy VPC, Deploy IAM, Deploy DB, Deploy Web Tier, Deploy Monitoring, Finalize Deployment. Secure credential injection via withCredentials for aws-credentials and tf-db-password; no hardcoded secrets. Rollback on failure using terraform destroy targeted to the failed module.

---

## 8. Security Architecture

- Network segmentation (private DB subnets, public web subnets)
- Security Groups: ELB(80/443), Web(80 from ELB; 22 admin), DB(3306 from Web only), Monitoring(80/3000/22)
- IAM least privilege (SSM access on EC2 role)
- Secrets via Jenkins credential store (tf-db-password), masked in logs
- No plaintext passwords in variables.tf (must pass -var db_master_password)

---

## 9. Monitoring & Observability

Grafana and a PHP monitoring dashboard provide visibility. Jenkins pipeline includes health checks for ELB, Auto Scaling instances, and HTTP 200 validation from application endpoints. CloudWatch metrics available for EC2, ELB, RDS.

---

## 10. Implementation Details

- User data minimized to 964 bytes by cloning application from GitHub
- ASG configured min=1, max=3; ELB health checks target HTTP:80/
- Aurora RDS: cluster endpoint provided to web via Terraform outputs and variables
- Jenkins: fixed stages to include db_master_password via tf-db-password credential
- Terraform conditional counts for deploy flags (deploy_web, deploy_database, deploy_monitoring)

---

## 11. Testing & Verification

- Terraform validate and plan before apply
- ELB DNS resolution and instance health verification loop
- Auto Scaling instance status (InService, Healthy) checks
- HTTP status polling to confirm application readiness
- Module-specific cleanup on failures to allow re-run

---

## 12. Performance & Scalability

`t3.micro` instances provide burstable CPU for web tier; ASG scales horizontally. ELB cross-zone load balancing improves distribution. Aurora MySQL delivers read scalability via replica and high availability.

---

## 13. Cost Estimation

| Service | Monthly Estimate (USD) |
|---------|-------------------------|
| EC2 (t3.micro x1-3) | ~$8–$24 |
| ELB (Classic) | ~$18–$25 |
| Aurora MySQL (cluster + instance) | ~$200–$400 |
| NAT Gateway + EIP | ~$35–$60 |
| Monitoring (t2.nano) | ~$4–$5 |
| Total (typical low usage) | ~$300–$500 |

---

## 14. Risk Assessment & Mitigation

- Security misconfiguration → Mitigation: SG whitelisting, IAM least privilege
- Credential leakage → Mitigation: Jenkins secrets, masked logs
- Quota limits → Mitigation: vCPU monitoring, ASG min size=1
- User data size constraints → Mitigation: GitHub clone approach
- Cost overruns → Mitigation: small instance types, deploy flags to control tiers

---

## 15. Challenges & Resolutions

- HTTP 503 via ELB due to DB SG/credentials → fixed security rules and DB password consistency
- EC2 user data >16KB limit → minimized by remote code pull
- Private repo clone failure → repo made public
- Jenkins variable propagation missing → added db_master_password across stages
- Emergency cleanup restored state after partial failures

---

## 16. Operations & Maintenance

- Routine pipeline runs for install/destroy
- CloudWatch alarms (future work) for CPU, ELB latency, RDS availability
- Patch management via SSM (enabled by IAM role)

---

## 17. Backup & Disaster Recovery

- Enable Aurora automated backups and snapshots
- Document RTO/RPO goals; test failover scenarios
- Consider cross-region read replica for resilience

---

## 18. Compliance & Governance

- Tagging resources with Name and project identifiers
- Follow AWS Well-Architected guidance
- Access logging for ELB and CloudTrail (future work)

---

## 19. Future Enhancements

- Secrets Manager for DB credentials and rotation
- AWS WAF in front of ELB
- Blue/green or canary deployments
- Containerization (ECS/EKS) and IaC for services
- Autoscaling policies based on target tracking

---

## 20. Conclusion

The project delivers a production-grade, reproducible cloud environment for a web application. Terraform modules, secure Jenkins CI/CD, and structured verification produce reliable deployments while maintaining strong security posture and operational efficiency.

---

## References

- Amazon Web Services. (2024). AWS well-architected framework. https://aws.amazon.com/architecture/well-architected/
- Brikman, Y. (2019). Terraform: Up & running (2nd ed.). O'Reilly Media.
- Forsgren, N., Humble, J., & Kim, G. (2018). Accelerate: The science of lean software and DevOps. IT Revolution Press.
- Fowler, M. (2002). Patterns of enterprise application architecture. Addison-Wesley Professional.
- HashiCorp. (2024). Terraform documentation. https://www.terraform.io/docs
- Humble, J., & Farley, D. (2010). Continuous delivery. Addison-Wesley Professional.
- Morris, K. (2016). Infrastructure as code. O'Reilly Media.
- Puppet. (2021). State of DevOps report 2021. Puppet, Inc.

---

## Appendices

### Appendix A: Architecture Components

| Component | Description |
|-----------|-------------|
| ELB SG | Port 80/443 from 0.0.0.0/0 |
| Web SG | Port 80 from ELB SG; 22 from Admin CIDR |
| DB SG | Port 3306 from Web SG only |
| Monitoring SG | Port 80, 3000, 22 from 0.0.0.0/0 |

### Appendix B: Jenkins Credentials

| Credential ID | Purpose |
|---------------|---------|
| aws-credentials | AWS Access for Terraform CLI |
| tf-db-password | DB master password (Secret Text) |
| jenkins-github-ssh | GitHub SSH key for repository access |
