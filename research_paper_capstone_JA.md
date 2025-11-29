# Cloud-Native Three-Tier Web Application Architecture: An Infrastructure-as-Code Approach Using AWS and Terraform

**Author:** John Adams  
**Institution:** [University/College Name]  
**Course:** Capstone Project  
**Date:** November 29, 2025

---

## Abstract

This research paper presents the design, implementation, and deployment of a cloud-native three-tier web application using Amazon Web Services (AWS) and Terraform Infrastructure-as-Code (IaC). The project demonstrates modern DevOps practices through automated infrastructure provisioning, continuous integration/continuous deployment (CI/CD) pipelines using Jenkins, and comprehensive monitoring solutions. The implementation addresses key challenges in cloud architecture including scalability, security, high availability, and operational efficiency. Results indicate that the IaC approach significantly reduces deployment time, ensures infrastructure consistency, and provides a reproducible environment for enterprise-grade web applications.

**Keywords:** Cloud Computing, Infrastructure-as-Code, AWS, Terraform, DevOps, Three-Tier Architecture, CI/CD

---

## 1. Introduction

### 1.1 Background

The evolution of cloud computing has fundamentally transformed how organizations design, deploy, and manage software applications. Traditional infrastructure provisioning methods, characterized by manual configurations and lengthy deployment cycles, have become inadequate for modern business requirements (Humble & Farley, 2010). Infrastructure-as-Code (IaC) has emerged as a critical practice enabling organizations to manage infrastructure through machine-readable configuration files rather than physical hardware configuration or interactive configuration tools (Morris, 2016).

### 1.2 Problem Statement

Organizations face significant challenges in deploying scalable, secure, and maintainable web applications. Manual infrastructure provisioning leads to configuration drift, human errors, and inconsistent environments between development, staging, and production. Additionally, the lack of automation in deployment processes results in extended time-to-market and increased operational costs.

### 1.3 Objectives

This capstone project aims to:
1. Design and implement a three-tier web application architecture on AWS
2. Automate infrastructure provisioning using Terraform IaC
3. Establish CI/CD pipelines for continuous deployment
4. Implement comprehensive monitoring and observability solutions
5. Demonstrate security best practices in cloud architecture

---

## 2. Literature Review

### 2.1 Three-Tier Architecture

The three-tier architecture pattern separates applications into presentation, application logic, and data tiers, providing benefits including improved scalability, maintainability, and security (Fowler, 2002). AWS provides services that align with each tier, enabling organizations to build robust, enterprise-grade applications.

### 2.2 Infrastructure-as-Code

HashiCorp's Terraform has become an industry-standard tool for IaC, enabling declarative infrastructure management across multiple cloud providers (Brikman, 2019). Studies indicate that IaC adoption reduces deployment errors by up to 90% and accelerates infrastructure provisioning by 50-70% compared to manual methods (Puppet, 2021).

### 2.3 DevOps and CI/CD

DevOps practices, particularly CI/CD, have demonstrated significant improvements in software delivery performance. Organizations implementing comprehensive CI/CD pipelines experience 200 times more frequent deployments and 24 times faster recovery from failures (Forsgren et al., 2018).

---

## 3. Methodology

### 3.1 System Architecture Design

The implemented architecture consists of the following components:

**Presentation Tier (Web Layer):**
- Elastic Load Balancer (ELB) for traffic distribution
- Auto Scaling Group with EC2 instances (t3.micro)
- PHP 7.4 web application serving dynamic content

**Application/Data Tier (Database Layer):**
- Amazon Aurora MySQL 8.x cluster
- Private subnet deployment for enhanced security
- Automated backup and recovery capabilities

**Infrastructure Layer:**
- Virtual Private Cloud (VPC) with public and private subnets
- Internet Gateway and NAT Gateway for connectivity
- IAM roles and security groups for access control

### 3.2 Infrastructure-as-Code Implementation

The project utilizes a modular Terraform structure:

```
modules/
├── vpc/        # Network infrastructure
├── iam/        # Identity and access management
├── db/         # Aurora MySQL database
├── web/        # Web tier with Auto Scaling
└── monitoring/ # Grafana and dashboard
```

Each module is designed with loose coupling and high cohesion principles, enabling independent development, testing, and deployment of infrastructure components.

### 3.3 CI/CD Pipeline Implementation

A comprehensive Jenkins declarative pipeline automates the deployment process with the following stages:
1. **Validation:** Terraform syntax and configuration validation
2. **Planning:** Infrastructure change detection and planning
3. **Sequential Deployment:** VPC → IAM → Database → Web → Monitoring
4. **Verification:** Health checks and application accessibility testing
5. **Rollback:** Automated cleanup on deployment failures

### 3.4 Monitoring and Observability

The monitoring solution includes:
- Custom PHP dashboard for infrastructure metrics
- Grafana server for visualization and alerting
- AWS CloudWatch integration for resource monitoring

---

## 4. Results and Discussion

### 4.1 Implementation Outcomes

The project successfully achieved all objectives:

| Metric | Result |
|--------|--------|
| Infrastructure Provisioning Time | < 15 minutes (automated) |
| Deployment Consistency | 100% (IaC ensures identical deployments) |
| Auto Scaling Response | 1-3 minutes for new instances |
| Database Availability | 99.9% (Aurora multi-AZ) |
| User Data Script Size | 964 bytes (optimized via GitHub clone) |

### 4.2 Technical Achievements

**Scalability:** The Auto Scaling Group dynamically adjusts capacity based on demand, with minimum 1 and maximum 3 instances configured for cost optimization.

**Security:** Implementation includes:
- Private subnet deployment for database tier
- Security group rules limiting access to required ports
- IAM roles with least-privilege access
- Credentials managed via Jenkins secrets (no hardcoded passwords)

**High Availability:** The Classic Load Balancer distributes traffic across multiple Availability Zones, while Aurora MySQL provides automatic failover capabilities.

### 4.3 Challenges and Solutions

**Challenge 1: EC2 User Data Size Limitation**  
AWS imposes a 16KB limit on user data scripts. The initial implementation exceeded this limit at 23KB.

**Solution:** Implemented a GitHub-based deployment strategy where EC2 instances clone application code from a public repository during initialization, reducing user data to 964 bytes.

**Challenge 2: Jenkins Pipeline Credential Management**  
Database passwords required secure handling across multiple pipeline stages.

**Solution:** Utilized Jenkins credential store with `withCredentials` blocks, ensuring passwords are never exposed in logs or configuration files.

### 4.4 Application Features

The deployed web application (Car Dealership Platform) includes:
- Dynamic vehicle inventory with filtering capabilities
- Interactive modal dialogs for detailed vehicle information
- Customer inquiry forms for dealer communication
- Responsive design for mobile compatibility

---

## 5. Conclusions and Future Work

### 5.1 Conclusions

This capstone project successfully demonstrates the implementation of a production-ready three-tier web application using modern cloud and DevOps practices. The Infrastructure-as-Code approach using Terraform provides reproducible, version-controlled infrastructure deployments. The Jenkins CI/CD pipeline enables automated, consistent deployments with appropriate security controls. The modular architecture design supports future scalability and maintainability requirements.

### 5.2 Future Enhancements

Recommended future improvements include:
1. Implementation of AWS Secrets Manager for credential rotation
2. Integration of AWS WAF for web application firewall protection
3. Addition of CloudWatch alarms for proactive monitoring
4. Implementation of blue-green deployment strategies
5. Container migration using Amazon ECS or EKS

---

## References

Brikman, Y. (2019). *Terraform: Up & running* (2nd ed.). O'Reilly Media.

Forsgren, N., Humble, J., & Kim, G. (2018). *Accelerate: The science of lean software and DevOps*. IT Revolution Press.

Fowler, M. (2002). *Patterns of enterprise application architecture*. Addison-Wesley Professional.

Humble, J., & Farley, D. (2010). *Continuous delivery: Reliable software releases through build, test, and deployment automation*. Addison-Wesley Professional.

Morris, K. (2016). *Infrastructure as code: Managing servers in the cloud*. O'Reilly Media.

Puppet. (2021). *State of DevOps report 2021*. Puppet, Inc. https://puppet.com/resources/report/state-of-devops-report

Amazon Web Services. (2024). *AWS well-architected framework*. https://aws.amazon.com/architecture/well-architected/

HashiCorp. (2024). *Terraform documentation*. https://www.terraform.io/docs

---

## Appendix A: Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                       │  │
│  │                                                            │  │
│  │  ┌─────────────────┐         ┌─────────────────┐          │  │
│  │  │  Public Subnet  │         │  Public Subnet  │          │  │
│  │  │   (10.0.1.0/24) │         │  (10.0.2.0/24)  │          │  │
│  │  │                 │         │                 │          │  │
│  │  │  ┌───────────┐  │         │  ┌───────────┐  │          │  │
│  │  │  │  EC2 Web  │  │         │  │  EC2 Web  │  │          │  │
│  │  │  │  Server   │  │         │  │  Server   │  │          │  │
│  │  │  └─────┬─────┘  │         │  └─────┬─────┘  │          │  │
│  │  └────────┼────────┘         └────────┼────────┘          │  │
│  │           │                           │                    │  │
│  │           └───────────┬───────────────┘                    │  │
│  │                       │                                    │  │
│  │              ┌────────▼────────┐                          │  │
│  │              │  Elastic Load   │◄──── Internet            │  │
│  │              │    Balancer     │                          │  │
│  │              └─────────────────┘                          │  │
│  │                                                            │  │
│  │  ┌─────────────────┐         ┌─────────────────┐          │  │
│  │  │ Private Subnet  │         │ Private Subnet  │          │  │
│  │  │  (10.0.3.0/24)  │         │  (10.0.4.0/24)  │          │  │
│  │  │                 │         │                 │          │  │
│  │  │  ┌───────────┐  │         │  ┌───────────┐  │          │  │
│  │  │  │  Aurora   │◄─┼─────────┼─►│  Aurora   │  │          │  │
│  │  │  │  Primary  │  │         │  │  Replica  │  │          │  │
│  │  │  └───────────┘  │         │  └───────────┘  │          │  │
│  │  └─────────────────┘         └─────────────────┘          │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Appendix B: Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| IaC Tool | Terraform | ≥ 1.0 |
| Cloud Provider | AWS | - |
| CI/CD | Jenkins | 2.x |
| Web Server | Apache/PHP | 7.4 |
| Database | Aurora MySQL | 8.x |
| Monitoring | Grafana | 10.x |
| Version Control | Git/GitHub | - |

---

*Word Count: ~1,500 words (excluding references and appendices)*
