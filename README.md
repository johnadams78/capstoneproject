# capstone-project: Life Science 3-tier AWS Terraform

This repository provides a modular Terraform scaffold to deploy a secure 3-tier web application on AWS:

- VPC with public and private subnets, Internet Gateway and NAT Gateway
- Web layer: ALB (public) + Auto Scaling Group (min 2, max 3) running small EC2 instances (default t3.micro). Instances receive public IPs as requested.
- DB layer: Aurora cluster with private subnets (placeholder Aurora configuration)
- IAM role / instance profile for web EC2 (SSM access)
- Security groups and minimal hardening

Notes & assumptions
- Aurora Serverless/autoscaling for DB can be configured further; the current scaffold creates an RDS cluster placeholder; you should enable serverless v2 scaling depending on your provider/version and requirements.
- Replace the default DB password in `terraform.tfvars` or better: put it into Secrets Manager and reference it.
- The web instances automatically install NGINX and serve a themed "Life Science & Space Explorer" landing page at `/`.
- This scaffold aims for minimal compute (t3.micro) for web tier as requested.

Quick start

1. Install Terraform >= 1.0
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and customize.
3. Run:

```bash
terraform init
terraform plan
terraform apply
```

Next steps
- Integrate Secrets Manager for DB credentials
- Add monitoring (CloudWatch alarms), backups and automatic snapshots for DB
- Harden security groups (limit ALB access to required CIDRs)

CI/CD with Jenkins

This repo includes a Jenkins declarative pipeline (`Jenkinsfile`) to validate/plan/apply/destroy Terraform.

Prereqs on Jenkins agent
- Terraform CLI installed and on PATH
- AWS credentials in Jenkins (Credentials > Kind: Amazon Web Services) with ID: `aws-terraform`
- Secret Text credential for DB password with ID: `tf-db-password`

Run the pipeline
- Create a Pipeline job pointing at this repo and script path `Jenkinsfile`, or use Jenkins Job Builder with `jenkins/job.yaml`.
- Parameters:
	- `ACTION`: `plan`, `apply`, or `destroy`
- Behavior:
	- `plan`: runs `terraform init/validate/plan`, archives `plan.txt`
	- `apply`: requires manual approval on main branch, applies previously generated `tfplan`
	- `destroy`: requires manual approval on main branch, destroys the stack

Jenkins Job Builder (optional)
- File: `jenkins/job.yaml`
- Assumes a Jenkins SSH credential ID `jenkins-github-ssh` to pull from `git@github.com:johnadams78/capstoneproject.git`.
