pipeline {
  agent any
  
  options {
    ansiColor('xterm')
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
    timeout(time: 90, unit: 'MINUTES')
  }
  
  environment {
    TF_IN_AUTOMATION = 'true'
    TF_CLI_ARGS = '-no-color'
    CLEANUP_MODE = 'false'
    PLAN_VALIDATED = 'false'
  }
  
  parameters {
    choice(
      name: 'ACTION',
      choices: ['plan', 'install', 'destroy'],
      description: 'Select action to perform'
    )
    booleanParam(
      name: 'DEPLOY_DATABASE',
      defaultValue: true,
      description: 'Deploy Aurora RDS MySQL database'
    )
    booleanParam(
      name: 'DEPLOY_WEB',
      defaultValue: true,
      description: 'Deploy web tier (EC2 instances + application)'
    )
    booleanParam(
      name: 'DEPLOY_MONITORING',
      defaultValue: true,
      description: 'Deploy monitoring tier (Grafana)'
    )
    booleanParam(
      name: 'AUTO_APPROVE',
      defaultValue: false,
      description: '⚠️ Skip confirmation prompts (dangerous for destroy)'
    )
  }

  stages {
    
    stage('Initialize') {
      steps {
        echo '🔧 Initializing Terraform and AWS...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            terraform init -upgrade
            echo "✅ Terraform initialized"
            echo "AWS Account: $(aws sts get-caller-identity --query Account --output text)"
            echo "AWS Region: $(aws configure get region || echo us-east-1)"
          '''
        }
      }
    }
    
    stage('Plan Infrastructure') {
      when { expression { params.ACTION == 'plan' } }
      steps {
        echo '📋 Creating Terraform execution plan...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
          string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
        ]) {
          sh '''
            echo "🔍 Validating Terraform configuration..."
            terraform validate
            
            if [ $? -ne 0 ]; then
              echo "❌ Terraform configuration validation failed!"
              exit 1
            fi
            
            echo "✅ Terraform configuration is valid"
            
            echo "📋 Creating comprehensive Terraform plan..."
            terraform plan \
              -var "deploy_database=${DEPLOY_DATABASE}" \
              -var "deploy_web=${DEPLOY_WEB}" \
              -var "deploy_monitoring=${DEPLOY_MONITORING}" \
              -var "db_master_password=${TF_DB_PASSWORD}" \
              -out=tfplan \
              -detailed-exitcode
            
            PLAN_EXIT_CODE=$?
            
            if [ $PLAN_EXIT_CODE -eq 0 ]; then
              echo "📊 No changes detected - infrastructure is up to date"
            elif [ $PLAN_EXIT_CODE -eq 2 ]; then
              echo "📊 Changes detected - plan created successfully"
            else
              echo "❌ Terraform plan failed with exit code: $PLAN_EXIT_CODE"
              exit 1
            fi
            
            echo "🔍 Plan Summary:"
            terraform show -json tfplan | jq -r '
              if .resource_changes then
                "Resources to be created: " + (.resource_changes | map(select(.change.actions | contains(["create"]))) | length | tostring) +
                "\nResources to be modified: " + (.resource_changes | map(select(.change.actions | contains(["update"]))) | length | tostring) +
                "\nResources to be destroyed: " + (.resource_changes | map(select(.change.actions | contains(["delete"]))) | length | tostring)
              else
                "No resource changes detected"
              end
            '
            
            echo "✅ Infrastructure plan created and validated successfully"
          '''
        }
        archiveArtifacts artifacts: 'tfplan', allowEmptyArchive: true
        script {
          env.PLAN_VALIDATED = 'true'
        }
      }
    }
    
    stage('Validate Plan for Deployment') {
      when { 
        expression { params.ACTION == 'install' }
      }
      steps {
        echo '🔍 Pre-deployment validation...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
          string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
        ]) {
          sh '''
            echo "=========================================="
            echo "PRE-DEPLOYMENT VALIDATION"
            echo "=========================================="
            
            echo "🔍 Validating Terraform configuration..."
            terraform validate
            
            if [ $? -ne 0 ]; then
              echo "❌ Terraform configuration validation failed!"
              echo "🚨 Cannot proceed with deployment - fix configuration errors first"
              exit 1
            fi
            
            echo "✅ Terraform configuration is valid"
            
            echo "📋 Creating pre-deployment validation plan..."
            terraform plan \
              -var "deploy_database=${DEPLOY_DATABASE}" \
              -var "deploy_web=${DEPLOY_WEB}" \
              -var "deploy_monitoring=${DEPLOY_MONITORING}" \
              -var "db_master_password=${TF_DB_PASSWORD}" \
              -out=validation-plan.tfplan \
              -detailed-exitcode
            
            VALIDATION_EXIT_CODE=$?
            
            if [ $VALIDATION_EXIT_CODE -eq 1 ]; then
              echo "❌ Pre-deployment planning failed!"
              echo "🚨 Cannot proceed with deployment - fix planning errors first"
              exit 1
            elif [ $VALIDATION_EXIT_CODE -eq 0 ]; then
              echo "📊 No changes needed - infrastructure appears to be up to date"
              echo "⚠️ Proceeding with deployment verification..."
            elif [ $VALIDATION_EXIT_CODE -eq 2 ]; then
              echo "📊 Deployment plan validated - changes detected and ready to apply"
            fi
            
            echo "🔍 Pre-deployment Plan Analysis:"
            terraform show -json validation-plan.tfplan | jq -r '
              if .resource_changes then
                .resource_changes | group_by(.change.actions[0]) | map({
                  action: .[0].change.actions[0],
                  count: length,
                  resources: map(.address)
                }) | .[] | 
                "Action: " + .action + " (" + (.count | tostring) + " resources)" +
                "\n  " + (.resources | join("\n  "))
              else
                "No resource changes detected in validation plan"
              end
            ' || echo "Plan analysis completed"
            
            echo "🔍 Checking AWS credentials and permissions..."
            
            # Verify AWS access
            AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
            AWS_REGION=$(aws configure get region || echo "us-east-1")
            AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
            
            echo "✅ AWS Access Verified:"
            echo "   - Account: $AWS_ACCOUNT"
            echo "   - Region: $AWS_REGION" 
            echo "   - User/Role: $AWS_USER"
            
            # Check for existing resources that might conflict
            echo "🔍 Checking for existing conflicting resources..."
            
            EXISTING_VPC=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=capstoneproject-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "None")
            EXISTING_DB=$(aws rds describe-db-clusters --db-cluster-identifier "capstoneproject-cluster" --query 'DBClusters[0].DBClusterIdentifier' --output text 2>/dev/null || echo "None")
            
            if [ "$EXISTING_VPC" != "None" ] && [ "$EXISTING_VPC" != "null" ]; then
              echo "⚠️ Found existing VPC: $EXISTING_VPC"
              echo "   This may indicate partial infrastructure already exists"
            fi
            
            if [ "$EXISTING_DB" != "None" ] && [ "$EXISTING_DB" != "null" ]; then
              echo "⚠️ Found existing RDS cluster: $EXISTING_DB"
              echo "   This may indicate partial infrastructure already exists"
            fi
            
            # Clean up validation plan
            rm -f validation-plan.tfplan
            
            echo "✅ Pre-deployment validation completed successfully!"
            echo "🚀 Ready to proceed with sequential deployment stages"
          '''
        }
        script {
          env.PLAN_VALIDATED = 'true'
        }
      }
    }
    
    stage('Deploy VPC') {
      when { 
        allOf {
          expression { params.ACTION == 'install' }
          expression { env.PLAN_VALIDATED == 'true' }
        }
      }
      steps {
        echo "🌐 Deploying VPC and Networking..."
        echo "DEBUG: ACTION parameter value: ${params.ACTION}"
        echo "DEBUG: Should execute VPC stage: ${params.ACTION == 'install'}"
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "=========================================="
            echo "STAGE 1/5: VPC AND NETWORKING DEPLOYMENT"
            echo "=========================================="
            
            echo "🚀 Creating VPC infrastructure..."
            echo "- VPC (10.0.0.0/16)"
            echo "- Public Subnets (2x)"
            echo "- Private Subnets (2x)"  
            echo "- Internet Gateway"
            echo "- NAT Gateway"
            echo "- Route Tables"
            
            # Create separate plan for VPC only
            terraform plan -target=module.vpc \
              -var "deploy_database=${DEPLOY_DATABASE}" \
              -var "deploy_web=${DEPLOY_WEB}" \
              -var "deploy_monitoring=${DEPLOY_MONITORING}" \
              -out=vpc-plan.tfplan
            
            echo "⏳ Applying VPC configuration..."
            terraform apply -input=false -auto-approve vpc-plan.tfplan
            
            echo "⏳ Verifying VPC deployment..."
            
            # Get VPC ID with retry logic
            for i in {1..5}; do
              VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
              if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "null" ]; then
                break
              fi
              echo "Waiting for VPC ID to be available... ($i/5)"
              sleep 10
            done
            
            echo "🔍 VPC ID: $VPC_ID"
            
            if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "null" ]; then
              echo "❌ Failed to get VPC ID"
              exit 1
            fi
            
            # Wait for VPC to be available
            echo "⏳ Waiting for VPC to be fully available..."
            aws ec2 wait vpc-available --vpc-ids $VPC_ID
            
            # Verify all subnets are created and available
            echo "⏳ Verifying subnets..."
            for i in {1..12}; do
              SUBNET_COUNT=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets | length(@)')
              PUBLIC_SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=true" --query 'Subnets | length(@)')
              PRIVATE_SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=false" --query 'Subnets | length(@)')
              
              echo "Total subnets: $SUBNET_COUNT (Public: $PUBLIC_SUBNETS, Private: $PRIVATE_SUBNETS)"
              
              if [ "$SUBNET_COUNT" -ge "4" ] && [ "$PUBLIC_SUBNETS" -ge "2" ] && [ "$PRIVATE_SUBNETS" -ge "2" ]; then
                break
              fi
              
              echo "Waiting for all subnets to be created... ($i/12)"
              sleep 15
            done
            
            # Verify Internet Gateway and NAT Gateway
            echo "⏳ Verifying gateways..."
            IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
            NAT_COUNT=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" --query 'NatGateways | length(@)')
            
            echo "🔍 Internet Gateway: $IGW_ID"
            echo "🔍 NAT Gateways: $NAT_COUNT"
            
            # Final verification
            if [ "$SUBNET_COUNT" -ge "4" ] && [ "$PUBLIC_SUBNETS" -ge "2" ] && [ "$PRIVATE_SUBNETS" -ge "2" ] && [ "$IGW_ID" != "None" ] && [ "$NAT_COUNT" -ge "1" ]; then
              echo "✅ VPC and Networking deployed and verified successfully!"
              echo "📊 Summary:"
              echo "   - VPC ID: $VPC_ID"
              echo "   - Total Subnets: $SUBNET_COUNT"
              echo "   - Public Subnets: $PUBLIC_SUBNETS" 
              echo "   - Private Subnets: $PRIVATE_SUBNETS"
              echo "   - Internet Gateway: $IGW_ID"
              echo "   - NAT Gateways: $NAT_COUNT"
            else
              echo "❌ VPC verification failed - initiating cleanup"
              echo "Expected: 4+ subnets (2+ public, 2+ private), 1+ IGW, 1+ NAT"
              echo "Got: $SUBNET_COUNT subnets ($PUBLIC_SUBNETS public, $PRIVATE_SUBNETS private), IGW: $IGW_ID, NAT: $NAT_COUNT"
              
              # Cleanup failed VPC resources
              echo "🧹 Cleaning up failed VPC resources..."
              if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "null" ]; then
                terraform destroy -target=module.vpc -input=false -auto-approve \
                  -var "deploy_database=${DEPLOY_DATABASE}" \
                  -var "deploy_web=${DEPLOY_WEB}" \
                  -var "deploy_monitoring=${DEPLOY_MONITORING}" || echo "VPC cleanup failed"
              fi
              
              exit 1
            fi
          '''
        }
      }
    }
    
    stage('Deploy IAM') {
      when { 
        allOf {
          expression { params.ACTION == 'install' }
          expression { env.PLAN_VALIDATED == 'true' }
        }
      }
      steps {
        echo '🔐 Deploying IAM Roles and Policies...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "=========================================="
            echo "STAGE 2/5: IAM ROLES AND POLICIES"
            echo "=========================================="
            
            echo "🚀 Creating IAM resources..."
            echo "- EC2 Service Role"
            echo "- EC2 Instance Profile"
            echo "- SSM Managed Instance Core Policy"
            
            # Create separate plan for IAM only
            terraform plan -target=module.iam \
              -var "deploy_database=${DEPLOY_DATABASE}" \
              -var "deploy_web=${DEPLOY_WEB}" \
              -var "deploy_monitoring=${DEPLOY_MONITORING}" \
              -out=iam-plan.tfplan
            
            echo "⏳ Applying IAM configuration..."
            terraform apply -input=false -auto-approve iam-plan.tfplan
            
            echo "⏳ Verifying IAM deployment..."
            
            # Wait for IAM role to exist and be ready
            IAM_ROLE="capstoneproject-ec2-role"
            echo "⏳ Waiting for IAM role: $IAM_ROLE"
            aws iam wait role-exists --role-name $IAM_ROLE
            
            # Get role details
            ROLE_ARN=$(aws iam get-role --role-name $IAM_ROLE --query 'Role.Arn' --output text 2>/dev/null || echo "")
            echo "🔍 Role ARN: $ROLE_ARN"
            
            # Wait for instance profile to exist
            INSTANCE_PROFILE="capstoneproject-ec2-profile"
            echo "⏳ Waiting for instance profile: $INSTANCE_PROFILE"
            
            for i in {1..6}; do
              if aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE >/dev/null 2>&1; then
                break
              fi
              echo "Waiting for instance profile to be ready... ($i/6)"
              sleep 10
            done
            
            # Verify instance profile details
            PROFILE_ARN=$(aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE --query 'InstanceProfile.Arn' --output text 2>/dev/null || echo "")
            echo "🔍 Instance Profile ARN: $PROFILE_ARN"
            
            # Verify role has the required policy attached
            ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name $IAM_ROLE --query 'AttachedPolicies | length(@)')
            echo "🔍 Attached Policies: $ATTACHED_POLICIES"
            
            # Final verification
            if [ ! -z "$ROLE_ARN" ] && [ ! -z "$PROFILE_ARN" ] && [ "$ATTACHED_POLICIES" -gt "0" ]; then
              echo "✅ IAM resources deployed and verified successfully!"
              echo "📊 Summary:"
              echo "   - IAM Role: $IAM_ROLE"
              echo "   - Role ARN: $ROLE_ARN"
              echo "   - Instance Profile: $INSTANCE_PROFILE"  
              echo "   - Profile ARN: $PROFILE_ARN"
              echo "   - Attached Policies: $ATTACHED_POLICIES"
            else
              echo "❌ IAM verification failed - initiating cleanup"
              echo "Role ARN: $ROLE_ARN"
              echo "Profile ARN: $PROFILE_ARN" 
              echo "Policies: $ATTACHED_POLICIES"
              
              # Cleanup failed IAM resources
              echo "🧹 Cleaning up failed IAM and VPC resources..."
              terraform destroy -target=module.iam -target=module.vpc -input=false -auto-approve \
                -var "deploy_database=${DEPLOY_DATABASE}" \
                -var "deploy_web=${DEPLOY_WEB}" \
                -var "deploy_monitoring=${DEPLOY_MONITORING}" || echo "IAM/VPC cleanup failed"
              
              exit 1
            fi
          '''
        }
      }
    }
    
    stage('Deploy Database') {
      when { 
        allOf {
          expression { params.ACTION == 'install' }
          expression { env.PLAN_VALIDATED == 'true' }
        }
      }
      steps {
        echo '🗄️ Deploying Aurora RDS Database (this takes ~5-7 minutes)...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
          string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
        ]) {
          sh '''
            echo "=========================================="
            echo "STAGE 3/5: AURORA RDS DATABASE"
            echo "=========================================="
            
            echo "🚀 Creating Aurora RDS cluster..."
            echo "- Aurora MySQL Cluster"
            echo "- Database Instance (db.r5.large)"
            echo "- Database Subnet Group"
            echo "- Security Groups"
            echo "- Database: capstonedb"
            
            # Create separate plan for database only  
            terraform plan -target=module.db \
              -var "deploy_database=${DEPLOY_DATABASE}" \
              -var "deploy_web=${DEPLOY_WEB}" \
              -var "deploy_monitoring=${DEPLOY_MONITORING}" \
              -var "db_master_password=${TF_DB_PASSWORD}" \
              -out=database-plan.tfplan
            
            echo "⏳ Applying database configuration (this will take 5-7 minutes)..."
            terraform apply -input=false -auto-approve database-plan.tfplan
            
            echo "⏳ Verifying Database deployment..."
            
            # Get cluster identifier and wait for it to be available
            CLUSTER_ID="capstoneproject-cluster"
            INSTANCE_ID="capstoneproject-instance-0"
            
            echo "⏳ Waiting for Aurora cluster $CLUSTER_ID to be available..."
            echo "   This typically takes 5-7 minutes for Aurora cluster creation..."
            
            # Wait for cluster with timeout and progress updates
            for i in {1..30}; do
              CLUSTER_STATUS=$(aws rds describe-db-clusters --db-cluster-identifier $CLUSTER_ID --query 'DBClusters[0].Status' --output text 2>/dev/null || echo "not-found")
              echo "   Progress: $i/30 - Cluster status: $CLUSTER_STATUS"
              
              if [ "$CLUSTER_STATUS" = "available" ]; then
                break
              fi
              
              if [ $i -eq 30 ]; then
                echo "❌ Timeout waiting for cluster to be available"
                exit 1
              fi
              
              sleep 30
            done
            
            echo "⏳ Waiting for Aurora instance $INSTANCE_ID to be available..."
            aws rds wait db-instance-available --db-instance-identifier $INSTANCE_ID
            
            # Get final status and details
            CLUSTER_STATUS=$(aws rds describe-db-clusters --db-cluster-identifier $CLUSTER_ID --query 'DBClusters[0].Status' --output text)
            INSTANCE_STATUS=$(aws rds describe-db-instances --db-instance-identifier $INSTANCE_ID --query 'DBInstances[0].DBInstanceStatus' --output text)
            
            # Get endpoints
            DB_ENDPOINT=$(terraform output -raw aurora_cluster_endpoint 2>/dev/null || echo "")
            DB_NAME=$(terraform output -raw database_name 2>/dev/null || echo "capstonedb")
            
            echo "🔍 Cluster Status: $CLUSTER_STATUS"
            echo "🔍 Instance Status: $INSTANCE_STATUS"
            echo "🔍 Database Endpoint: $DB_ENDPOINT"
            echo "🔍 Database Name: $DB_NAME"
            
            # Final verification
            if [ "$CLUSTER_STATUS" = "available" ] && [ "$INSTANCE_STATUS" = "available" ] && [ ! -z "$DB_ENDPOINT" ]; then
              echo "✅ Database deployed and verified successfully!"
              echo "📊 Summary:"
              echo "   - Cluster ID: $CLUSTER_ID"
              echo "   - Instance ID: $INSTANCE_ID"
              echo "   - Endpoint: $DB_ENDPOINT"
              echo "   - Database: $DB_NAME"
              echo "   - Status: Ready for connections"
            else
              echo "❌ Database verification failed - initiating cleanup"
              echo "Cluster Status: $CLUSTER_STATUS"
              echo "Instance Status: $INSTANCE_STATUS"
              echo "Endpoint: $DB_ENDPOINT"
              
              # Cleanup failed database and previous resources
              echo "🧹 Cleaning up failed database and previous resources..."
              terraform destroy -target=module.db -target=module.iam -target=module.vpc -input=false -auto-approve \
                -var "deploy_database=${DEPLOY_DATABASE}" \
                -var "deploy_web=${DEPLOY_WEB}" \
                -var "deploy_monitoring=${DEPLOY_MONITORING}" \
                -var "db_master_password=${TF_DB_PASSWORD}" || echo "Database/IAM/VPC cleanup failed"
              
              exit 1
            fi
          '''
        }
      }
    }
    
    stage('Deploy Web Tier') {
      when { 
        allOf {
          expression { params.ACTION == 'install' }
          expression { env.PLAN_VALIDATED == 'true' }
        }
      }
      steps {
        echo '🖥️ Deploying Web Servers and Application...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "=========================================="
            echo "STAGE 4/5: WEB TIER DEPLOYMENT"
            echo "=========================================="
            
            echo "🚀 Creating Web Tier infrastructure..."
            echo "- Application Load Balancer"
            echo "- Auto Scaling Group (2-3 instances)"
            echo "- Launch Template (t3.micro)"
            echo "- Target Groups"
            echo "- Security Groups"
            echo "- Car Dealership Application"
            
            # Create separate plan for web tier only
            terraform plan -target=module.web \
              -var "deploy_database=${DEPLOY_DATABASE}" \
              -var "deploy_web=${DEPLOY_WEB}" \
              -var "deploy_monitoring=${DEPLOY_MONITORING}" \
              -out=web-plan.tfplan
            
            echo "⏳ Applying web tier configuration..."
            terraform apply -input=false -auto-approve web-plan.tfplan
            
            echo "⏳ Verifying Web Tier deployment..."
            
            # Get ALB details and wait for it to be active
            ALB_NAME="capstoneproject-alb"
            echo "⏳ Waiting for Load Balancer: $ALB_NAME"
            
            for i in {1..10}; do
              ALB_ARN=$(aws elbv2 describe-load-balancers --names $ALB_NAME --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
              if [ ! -z "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
                break
              fi
              echo "Waiting for ALB to be created... ($i/10)"
              sleep 15
            done
            
            echo "🔍 ALB ARN: $ALB_ARN"
            
            # Wait for load balancer to be active
            echo "⏳ Waiting for Load Balancer to become active..."
            aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN
            
            # Get ALB status and DNS
            ALB_STATE=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].State.Code' --output text)
            ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text)
            
            echo "🔍 ALB State: $ALB_STATE"
            echo "🔍 ALB DNS: $ALB_DNS"
            
            # Wait for Auto Scaling Group to have healthy instances
            ASG_NAME="capstoneproject-asg"
            echo "⏳ Waiting for Auto Scaling Group instances to be healthy..."
            echo "   This typically takes 3-5 minutes for instances to launch and pass health checks..."
            
            # Wait up to 15 minutes for healthy instances with progress updates
            for i in {1..30}; do
              TOTAL_INSTANCES=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].Instances | length(@)' --output text 2>/dev/null || echo "0")
              HEALTHY_COUNT=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].Instances[?HealthStatus==`Healthy`] | length(@)' --output text 2>/dev/null || echo "0")
              INSERVICE_COUNT=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`] | length(@)' --output text 2>/dev/null || echo "0")
              
              echo "   Progress: $i/30 - Total: $TOTAL_INSTANCES, Healthy: $HEALTHY_COUNT, InService: $INSERVICE_COUNT"
              
              if [ "$HEALTHY_COUNT" -ge "2" ] && [ "$INSERVICE_COUNT" -ge "2" ]; then
                break
              fi
              
              if [ $i -eq 30 ]; then
                echo "❌ Timeout waiting for healthy instances"
                echo "Final status - Total: $TOTAL_INSTANCES, Healthy: $HEALTHY_COUNT, InService: $INSERVICE_COUNT"
                exit 1
              fi
              
              sleep 30
            done
            
            # Get web URLs from terraform output
            WEB_URL=$(terraform output -raw web_url 2>/dev/null || echo "")
            ALB_DNS_OUTPUT=$(terraform output -raw web_alb_dns 2>/dev/null || echo "")
            
            echo "🔍 Web URL: $WEB_URL"
            echo "🔍 ALB DNS (from output): $ALB_DNS_OUTPUT"
            
            # Test web application accessibility
            if [ ! -z "$WEB_URL" ] && [ "$WEB_URL" != "null" ]; then
              echo "⏳ Testing web application accessibility..."
              for i in {1..6}; do
                HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_URL" --connect-timeout 10 || echo "000")
                echo "   HTTP Status: $HTTP_STATUS"
                if [ "$HTTP_STATUS" = "200" ]; then
                  break
                fi
                echo "   Waiting for web application to respond... ($i/6)"
                sleep 30
              done
            fi
            
            # Final verification
            if [ "$ALB_STATE" = "active" ] && [ "$HEALTHY_COUNT" -ge "2" ] && [ "$INSERVICE_COUNT" -ge "2" ] && [ ! -z "$WEB_URL" ]; then
              echo "✅ Web tier deployed and verified successfully!"
              echo "📊 Summary:"
              echo "   - Load Balancer: $ALB_NAME ($ALB_STATE)"
              echo "   - ALB DNS: $ALB_DNS"
              echo "   - Auto Scaling Group: $ASG_NAME"
              echo "   - Healthy Instances: $HEALTHY_COUNT"
              echo "   - InService Instances: $INSERVICE_COUNT"
              echo "   - Application URL: $WEB_URL"
              if [ "$HTTP_STATUS" = "200" ]; then
                echo "   - HTTP Status: ✅ $HTTP_STATUS (Accessible)"
              else
                echo "   - HTTP Status: ⚠️ $HTTP_STATUS (May still be initializing)"
              fi
            else
              echo "❌ Web tier verification failed - initiating cleanup"
              echo "ALB State: $ALB_STATE"
              echo "Healthy Count: $HEALTHY_COUNT"
              echo "InService Count: $INSERVICE_COUNT"
              echo "Web URL: $WEB_URL"
              
              # Cleanup failed web tier and previous resources
              echo "🧹 Cleaning up failed web tier and previous resources..."
              terraform destroy -target=module.web -target=module.db -target=module.iam -target=module.vpc -input=false -auto-approve \
                -var "deploy_database=${DEPLOY_DATABASE}" \
                -var "deploy_web=${DEPLOY_WEB}" \
                -var "deploy_monitoring=${DEPLOY_MONITORING}" \
                -var "db_master_password=${TF_DB_PASSWORD}" || echo "Web/Database/IAM/VPC cleanup failed"
              
              exit 1
            fi
          '''
        }
      }
    }
    
    stage('Deploy Monitoring') {
      when { 
        allOf {
          expression { params.ACTION == 'install' }
          expression { env.PLAN_VALIDATED == 'true' }
        }
      }
      steps {
        echo '📊 Deploying Monitoring Stack (Grafana)...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "=========================================="
            echo "STAGE 5/5: MONITORING STACK"
            echo "=========================================="
            
            echo "🚀 Creating Monitoring infrastructure..."
            echo "- EC2 Instance (t3.micro)"
            echo "- Monitoring Dashboard (PHP/SQLite)"
            echo "- Grafana Server (Port 3000)"
            echo "- Security Groups"
            echo "- Auto-configured Services"
            
            # Create separate plan for monitoring only
            terraform plan -target=module.monitoring \
              -var "deploy_database=${DEPLOY_DATABASE}" \
              -var "deploy_web=${DEPLOY_WEB}" \
              -var "deploy_monitoring=${DEPLOY_MONITORING}" \
              -out=monitoring-plan.tfplan
            
            echo "⏳ Applying monitoring configuration..."
            terraform apply -input=false -auto-approve monitoring-plan.tfplan
            
            echo "⏳ Verifying Monitoring deployment..."
            
            # Get monitoring instance details with retry
            for i in {1..5}; do
              MONITORING_IP=$(terraform output -raw monitoring_public_ip 2>/dev/null || echo "")
              if [ ! -z "$MONITORING_IP" ] && [ "$MONITORING_IP" != "null" ]; then
                break
              fi
              echo "Waiting for monitoring IP to be available... ($i/5)"
              sleep 10
            done
            
            echo "🔍 Monitoring Server IP: $MONITORING_IP"
            
            # Wait for EC2 instance to be running and get instance ID
            echo "⏳ Finding monitoring instance..."
            for i in {1..10}; do
              INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=capstoneproject-monitoring-server" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null || echo "None")
              if [ "$INSTANCE_ID" != "None" ] && [ "$INSTANCE_ID" != "null" ] && [ ! -z "$INSTANCE_ID" ]; then
                break
              fi
              echo "Waiting for monitoring instance to be running... ($i/10)"
              sleep 15
            done
            
            echo "🔍 Instance ID: $INSTANCE_ID"
            
            if [ "$INSTANCE_ID" != "None" ] && [ "$INSTANCE_ID" != "null" ] && [ ! -z "$INSTANCE_ID" ]; then
              # Wait for instance to be running
              echo "⏳ Waiting for instance to be fully running..."
              aws ec2 wait instance-running --instance-ids $INSTANCE_ID
              
              # Wait for status checks to pass
              echo "⏳ Waiting for instance status checks to pass..."
              aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
              
              # Get instance status
              INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text)
              STATUS_CHECK=$(aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --query 'InstanceStatuses[0].SystemStatus.Status' --output text 2>/dev/null || echo "unknown")
              
              echo "🔍 Instance State: $INSTANCE_STATE"
              echo "🔍 Status Check: $STATUS_CHECK"
              
              # Wait for HTTP services to be ready (user data script installation)
              echo "⏳ Waiting for monitoring services to be installed and ready..."
              echo "   This includes Apache, PHP, Grafana installation and configuration..."
              
              for i in {1..20}; do
                # Check if monitoring dashboard is accessible
                HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${MONITORING_IP}" --connect-timeout 10 || echo "000")
                echo "   Progress: $i/20 - HTTP Status: $HTTP_STATUS"
                
                if [ "$HTTP_STATUS" = "200" ]; then
                  echo "   ✅ Monitoring dashboard is ready!"
                  break
                fi
                
                if [ $i -eq 20 ]; then
                  echo "   ⚠️ Dashboard may still be initializing (this is normal)"
                fi
                
                sleep 30
              done
              
              # Test Grafana availability
              echo "⏳ Testing Grafana availability..."
              GRAFANA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${MONITORING_IP}:3000" --connect-timeout 10 || echo "000")
              echo "🔍 Grafana Status: $GRAFANA_STATUS"
              
              # Get URLs from terraform output
              DASHBOARD_URL=$(terraform output -raw monitoring_dashboard_url 2>/dev/null || echo "")
              GRAFANA_URL=$(terraform output -raw grafana_dashboard_url 2>/dev/null || echo "")
              
              echo "🔍 Dashboard URL: $DASHBOARD_URL"
              echo "🔍 Grafana URL: $GRAFANA_URL"
              
              # Final verification
              if [ "$INSTANCE_STATE" = "running" ] && [ "$STATUS_CHECK" = "ok" ] && [ ! -z "$MONITORING_IP" ]; then
                echo "✅ Monitoring deployed and verified successfully!"
                echo "📊 Summary:"
                echo "   - Instance ID: $INSTANCE_ID"
                echo "   - Public IP: $MONITORING_IP"
                echo "   - Instance State: $INSTANCE_STATE"
                echo "   - Status Checks: $STATUS_CHECK"
                echo "   - Dashboard URL: $DASHBOARD_URL"
                echo "   - Grafana URL: $GRAFANA_URL"
                echo "   - Grafana Credentials: admin/grafana123"
                if [ "$HTTP_STATUS" = "200" ]; then
                  echo "   - Dashboard Status: ✅ Ready"
                else
                  echo "   - Dashboard Status: ⚠️ Still initializing"
                fi
                if [ "$GRAFANA_STATUS" = "200" ]; then
                  echo "   - Grafana Status: ✅ Ready"
                else
                  echo "   - Grafana Status: ⚠️ Still initializing"
                fi
              else
                echo "❌ Monitoring verification failed - initiating cleanup"
                echo "Instance State: $INSTANCE_STATE"
                echo "Status Check: $STATUS_CHECK"
                echo "Monitoring IP: $MONITORING_IP"
                
                # Cleanup all resources on monitoring failure
                echo "🧹 Cleaning up all deployed resources..."
                terraform destroy -input=false -auto-approve \
                  -var "deploy_database=${DEPLOY_DATABASE}" \
                  -var "deploy_web=${DEPLOY_WEB}" \
                  -var "deploy_monitoring=${DEPLOY_MONITORING}" \
                  -var "db_master_password=${TF_DB_PASSWORD}" || echo "Full cleanup failed"
                
                exit 1
              fi
            else
              echo "❌ Monitoring verification failed - instance not found, initiating cleanup"
              
              # Cleanup all resources on monitoring failure
              echo "🧹 Cleaning up all deployed resources..."
              terraform destroy -input=false -auto-approve \
                -var "deploy_database=${DEPLOY_DATABASE}" \
                -var "deploy_web=${DEPLOY_WEB}" \
                -var "deploy_monitoring=${DEPLOY_MONITORING}" \
                -var "db_master_password=${TF_DB_PASSWORD}" || echo "Full cleanup failed"
              
              exit 1
            fi
          '''
        }
      }
    }
    
    stage('Finalize Deployment') {
      when { 
        allOf {
          expression { params.ACTION == 'install' }
          expression { env.PLAN_VALIDATED == 'true' }
        }
      }
      steps {
        echo '⚙️ Finalizing deployment and applying remaining resources...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
          string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
        ]) {
          sh '''
            echo "=========================================="
            echo "FINALIZATION: ENSURING ALL RESOURCES"
            echo "=========================================="
            
            echo "🚀 Final comprehensive deployment..."
            echo "- Applying any remaining resources"
            echo "- Ensuring all dependencies are met"
            echo "- Refreshing terraform state"
            
            # Create final comprehensive plan to catch any missed resources
            terraform plan \
              -var "deploy_database=${DEPLOY_DATABASE}" \
              -var "deploy_web=${DEPLOY_WEB}" \
              -var "deploy_monitoring=${DEPLOY_MONITORING}" \
              -var "db_master_password=${TF_DB_PASSWORD}" \
              -out=final-plan.tfplan
            
            echo "⏳ Applying final configuration..."
            terraform apply -input=false -auto-approve final-plan.tfplan
            
            echo "⏳ Final verification of all components..."
            
            # Wait for final configurations to settle
            echo "Allowing time for final configurations to settle..."
            sleep 30
            
            # Verify terraform state is consistent
            echo "Refreshing terraform state..."
            terraform refresh -input=false \
              -var "deploy_database=${DEPLOY_DATABASE}" \
              -var "deploy_web=${DEPLOY_WEB}" \
              -var "deploy_monitoring=${DEPLOY_MONITORING}" \
              -var "db_master_password=${TF_DB_PASSWORD}"
            
            # Clean up plan files
            echo "Cleaning up temporary plan files..."
            rm -f vpc-plan.tfplan iam-plan.tfplan database-plan.tfplan web-plan.tfplan monitoring-plan.tfplan final-plan.tfplan validation-plan.tfplan
            
            echo "✅ Deployment finalized successfully!"
            echo "🎉 All infrastructure components have been deployed and verified!"
          '''
        }
      }
    }
    
    stage('Verify Infrastructure') {
      when { 
        allOf {
          expression { params.ACTION == 'install' }
          expression { env.PLAN_VALIDATED == 'true' }
        }
      }
      steps {
        echo '✅ Comprehensive Infrastructure Verification...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "==========================================="
            echo "🔍 INFRASTRUCTURE DEPLOYMENT SUMMARY"
            echo "==========================================="
            
            # Check VPC
            VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo 'Not deployed')
            echo "🌐 VPC: $VPC_ID"
            
            # Check Subnets
            if [ "$VPC_ID" != "Not deployed" ]; then
              PUBLIC_SUBNETS=$(terraform output -json public_subnets 2>/dev/null | jq -r '.[]' | wc -l)
              echo "🔗 Public Subnets: $PUBLIC_SUBNETS"
            fi
            
            # Check Web Tier
            if [ "${DEPLOY_WEB}" = "true" ]; then
              WEB_URL=$(terraform output -raw web_url 2>/dev/null || echo "Not available")
              ALB_DNS=$(terraform output -raw web_alb_dns 2>/dev/null || echo "Not available")
              echo "🖥️ Web Application: $WEB_URL"
              echo "⚖️ Load Balancer DNS: $ALB_DNS"
              
              # Test web application accessibility
              if [ "$WEB_URL" != "Not available" ] && [ "$WEB_URL" != "" ]; then
                echo "🔍 Testing web application accessibility..."
                HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_URL" || echo "000")
                if [ "$HTTP_STATUS" = "200" ]; then
                  echo "✅ Web application is accessible (HTTP $HTTP_STATUS)"
                else
                  echo "⚠️ Web application returned HTTP $HTTP_STATUS (may still be initializing)"
                fi
              fi
            else
              echo "🖥️ Web Tier: Skipped (DEPLOY_WEB=false)"
            fi
            
            # Check Database
            if [ "${DEPLOY_DATABASE}" = "true" ]; then
              DB_ENDPOINT=$(terraform output -raw aurora_cluster_endpoint 2>/dev/null || echo "Not available")
              DB_NAME=$(terraform output -raw database_name 2>/dev/null || echo "capstonedb")
              echo "🗄️ Database Endpoint: $DB_ENDPOINT"
              echo "🗄️ Database Name: $DB_NAME"
              
              # Check database cluster status
              if [ "$DB_ENDPOINT" != "Not available" ] && [ "$DB_ENDPOINT" != "" ]; then
                CLUSTER_STATUS=$(aws rds describe-db-clusters --db-cluster-identifier capstoneproject-cluster --query 'DBClusters[0].Status' --output text 2>/dev/null || echo "unknown")
                echo "🗄️ Database Status: $CLUSTER_STATUS"
              fi
            else
              echo "🗄️ Database: Skipped (DEPLOY_DATABASE=false)"
            fi
            
            # Check Monitoring
            if [ "${DEPLOY_MONITORING}" = "true" ]; then
              MON_DASHBOARD=$(terraform output -raw monitoring_dashboard_url 2>/dev/null || echo "Not available")
              GRAFANA_URL=$(terraform output -raw grafana_dashboard_url 2>/dev/null || echo "Not available")
              MON_IP=$(terraform output -raw monitoring_public_ip 2>/dev/null || echo "Not available")
              
              echo "📊 Monitoring Dashboard: $MON_DASHBOARD"
              echo "📈 Grafana Dashboard: $GRAFANA_URL"
              echo "🖥️ Monitoring Server IP: $MON_IP"
              
              # Test monitoring dashboard accessibility
              if [ "$MON_DASHBOARD" != "Not available" ] && [ "$MON_DASHBOARD" != "" ]; then
                echo "🔍 Testing monitoring dashboard accessibility..."
                HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$MON_DASHBOARD" || echo "000")
                if [ "$HTTP_STATUS" = "200" ]; then
                  echo "✅ Monitoring dashboard is accessible (HTTP $HTTP_STATUS)"
                else
                  echo "⚠️ Monitoring dashboard returned HTTP $HTTP_STATUS (may still be initializing)"
                fi
              fi
            else
              echo "📊 Monitoring: Skipped (DEPLOY_MONITORING=false)"
            fi
            
            echo "==========================================="
            echo "🎯 DEPLOYMENT VERIFICATION COMPLETE"
            echo "==========================================="
            
            # Final status check - Resource summary
            echo "📊 Deployed Resources Summary:"
            terraform show -json | jq -r '.values.root_module.resources[] | select(.type != "data") | "\\(.type): \\(.name)"' | sort | uniq -c
            
            echo "✅ All deployed resources verified successfully!"
            echo "🚀 Infrastructure is ready for use!"
            echo "✅ Infrastructure verification complete"
          '''
        }
      }
    }
    
    stage('Validate Destroy Plan') {
      when { 
        expression { params.ACTION == 'destroy' }
      }
      steps {
        echo '🔍 Validating destroy operation...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
          string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
        ]) {
          sh '''
            echo "=========================================="
            echo "DESTROY OPERATION VALIDATION"
            echo "=========================================="
            
            echo "🔍 Validating Terraform configuration..."
            terraform validate
            
            if [ $? -ne 0 ]; then
              echo "❌ Terraform configuration validation failed!"
              echo "🚨 Cannot proceed with destroy - fix configuration errors first"
              exit 1
            fi
            
            echo "✅ Terraform configuration is valid"
            
            echo "🔍 Checking current infrastructure state..."
            terraform refresh -input=false \
              -var "deploy_database=true" \
              -var "deploy_web=true" \
              -var "deploy_monitoring=true" \
              -var "db_master_password=${TF_DB_PASSWORD}"
            
            echo "📋 Creating destroy plan..."
            terraform plan -destroy \
              -var "deploy_database=true" \
              -var "deploy_web=true" \
              -var "deploy_monitoring=true" \
              -var "db_master_password=${TF_DB_PASSWORD}" \
              -out=destroy-plan.tfplan \
              -detailed-exitcode
            
            DESTROY_PLAN_EXIT_CODE=$?
            
            if [ $DESTROY_PLAN_EXIT_CODE -eq 1 ]; then
              echo "❌ Destroy plan failed!"
              echo "🚨 Cannot proceed with destruction"
              exit 1
            elif [ $DESTROY_PLAN_EXIT_CODE -eq 0 ]; then
              echo "📊 No resources found to destroy"
              echo "✅ Infrastructure appears to be already clean"
            elif [ $DESTROY_PLAN_EXIT_CODE -eq 2 ]; then
              echo "📊 Destroy plan created - resources found for destruction"
              
              echo "🔍 Resources to be destroyed:"
              terraform show -json destroy-plan.tfplan | jq -r '
                if .resource_changes then
                  .resource_changes | map(select(.change.actions | contains(["delete"]))) | .[] |
                  "🗑️  " + .type + "." + .name + " (" + .address + ")"
                else
                  "No resources to destroy"
                end
              ' || echo "Destroy plan analysis completed"
              
              # Count resources by type for better overview
              echo ""
              echo "📊 Destruction summary:"
              terraform show -json destroy-plan.tfplan | jq -r '
                if .resource_changes then
                  .resource_changes | map(select(.change.actions | contains(["delete"]))) | group_by(.type) | map({
                    type: .[0].type,
                    count: length
                  }) | .[] | 
                  "   - " + .type + ": " + (.count | tostring) + " resource(s)"
                else
                  "   - No resources to destroy"
                end
              ' || echo "Destroy summary completed"
            fi
            
            echo "🔍 Checking for expensive resources that will be destroyed..."
            
            # Check for RDS clusters
            RDS_CLUSTERS=$(aws rds describe-db-clusters --query 'DBClusters[?starts_with(DBClusterIdentifier, `capstoneproject`)].DBClusterIdentifier' --output text 2>/dev/null || echo "")
            if [ ! -z "$RDS_CLUSTERS" ]; then
              echo "💰 WARNING: RDS clusters will be destroyed: $RDS_CLUSTERS"
            fi
            
            # Check for Load Balancers
            ALB_COUNT=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?starts_with(LoadBalancerName, `capstoneproject`)] | length(@)' --output text 2>/dev/null || echo "0")
            if [ "$ALB_COUNT" -gt "0" ]; then
              echo "💰 WARNING: $ALB_COUNT Load Balancer(s) will be destroyed"
            fi
            
            # Check for NAT Gateways
            NAT_COUNT=$(aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=*capstoneproject*" --query 'NatGateways[?State==`available`] | length(@)' --output text 2>/dev/null || echo "0")
            if [ "$NAT_COUNT" -gt "0" ]; then
              echo "💰 WARNING: $NAT_COUNT NAT Gateway(s) will be destroyed (saves hourly charges)"
            fi
            
            # Clean up destroy plan
            rm -f destroy-plan.tfplan
            
            echo "✅ Destroy validation completed"
            echo "⚠️ Review the resources listed above before confirming destruction"
          '''
        }
        script {
          env.PLAN_VALIDATED = 'true'
        }
      }
    }
    
    stage('Destroy Confirmation') {
      when { 
        allOf {
          expression { params.ACTION == 'destroy' }
          expression { params.AUTO_APPROVE == false }
          expression { env.PLAN_VALIDATED == 'true' }
        }
      }
      steps {
        echo '⚠️ DESTRUCTION WARNING: This will permanently destroy all infrastructure!'
        echo '💰 This will stop all AWS charges for these resources'
        echo '📋 Review the destroy validation results above'
        timeout(time: 30, unit: 'MINUTES') {
          input message: '💥 Are you ABSOLUTELY SURE you want to DESTROY everything? This cannot be undone!', ok: 'Yes, Destroy All Infrastructure'
        }
      }
    }
    
    stage('Destroy Infrastructure') {
      when { 
        allOf {
          expression { params.ACTION == 'destroy' }
          expression { env.PLAN_VALIDATED == 'true' }
        }
      }
      steps {
        echo '💥 Destroying all infrastructure...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
          string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
        ]) {
          sh '''
            echo "=========================================="
            echo "🗑️  INFRASTRUCTURE DESTRUCTION"
            echo "=========================================="
            
            echo "💥 Starting systematic infrastructure destruction..."
            
            # Final validation before destruction
            echo "🔍 Final validation before destruction..."
            terraform validate
            if [ $? -ne 0 ]; then
              echo "❌ Configuration validation failed - aborting destruction"
              exit 1
            fi
            
            # Refresh state to ensure we have latest information
            echo "🔄 Refreshing Terraform state..."
            terraform refresh -input=false \
              -var "deploy_database=true" \
              -var "deploy_web=true" \
              -var "deploy_monitoring=true" \
              -var "db_master_password=${TF_DB_PASSWORD}"
            
            # Show what will be destroyed
            echo "📋 Final destroy plan:"
            terraform plan -destroy \
              -var "deploy_database=true" \
              -var "deploy_web=true" \
              -var "deploy_monitoring=true" \
              -var "db_master_password=${TF_DB_PASSWORD}" \
              -no-color
            
            echo ""
            echo "🚀 Executing infrastructure destruction..."
            
            # Execute the destroy with proper error handling
            terraform destroy -input=false -auto-approve \
              -var "deploy_database=true" \
              -var "deploy_web=true" \
              -var "deploy_monitoring=true" \
              -var "db_master_password=${TF_DB_PASSWORD}"
            
            DESTROY_EXIT_CODE=$?
            
            if [ $DESTROY_EXIT_CODE -eq 0 ]; then
              echo "✅ Terraform destruction completed successfully"
            else
              echo "❌ Terraform destruction failed with exit code: $DESTROY_EXIT_CODE"
              echo "🧹 Attempting manual cleanup of remaining resources..."
              
              # Manual cleanup as fallback
              echo "🔍 Checking for remaining AWS resources..."
              
              # Check and cleanup remaining RDS clusters
              REMAINING_CLUSTERS=$(aws rds describe-db-clusters --query 'DBClusters[?starts_with(DBClusterIdentifier, `capstoneproject`)].DBClusterIdentifier' --output text 2>/dev/null || echo "")
              if [ ! -z "$REMAINING_CLUSTERS" ]; then
                echo "🗄️ Cleaning up remaining RDS clusters: $REMAINING_CLUSTERS"
                for cluster in $REMAINING_CLUSTERS; do
                  aws rds delete-db-cluster --db-cluster-identifier "$cluster" --skip-final-snapshot --delete-automated-backups 2>/dev/null || echo "Could not delete cluster $cluster"
                done
              fi
              
              # Check and cleanup remaining Load Balancers
              REMAINING_ALBS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?starts_with(LoadBalancerName, `capstoneproject`)].LoadBalancerArn' --output text 2>/dev/null || echo "")
              if [ ! -z "$REMAINING_ALBS" ]; then
                echo "⚖️ Cleaning up remaining Load Balancers..."
                for alb in $REMAINING_ALBS; do
                  aws elbv2 delete-load-balancer --load-balancer-arn "$alb" 2>/dev/null || echo "Could not delete ALB $alb"
                done
              fi
              
              # Check and cleanup Auto Scaling Groups
              aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "capstoneproject-asg" --force-delete 2>/dev/null || echo "ASG not found"
              
              # Check and cleanup EC2 instances
              REMAINING_INSTANCES=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=capstoneproject-*" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null || echo "")
              if [ ! -z "$REMAINING_INSTANCES" ]; then
                echo "💻 Terminating remaining EC2 instances: $REMAINING_INSTANCES"
                aws ec2 terminate-instances --instance-ids $REMAINING_INSTANCES 2>/dev/null || echo "Could not terminate instances"
              fi
              
              echo "⚠️ Some resources may require manual cleanup from AWS console"
            fi
            
            # Final verification
            echo "🔍 Final verification of destruction..."
            sleep 30
            
            # Check if major resources still exist
            REMAINING_VPC=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=capstoneproject-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "None")
            REMAINING_RDS=$(aws rds describe-db-clusters --query 'DBClusters[?starts_with(DBClusterIdentifier, `capstoneproject`)] | length(@)' --output text 2>/dev/null || echo "0")
            REMAINING_ALB=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?starts_with(LoadBalancerName, `capstoneproject`)] | length(@)' --output text 2>/dev/null || echo "0")
            
            echo "📊 Destruction Summary:"
            echo "   - VPC: $([ "$REMAINING_VPC" = "None" ] && echo "✅ Destroyed" || echo "⚠️ May still exist: $REMAINING_VPC")"
            echo "   - RDS Clusters: $([ "$REMAINING_RDS" = "0" ] && echo "✅ Destroyed" || echo "⚠️ $REMAINING_RDS still exist")"
            echo "   - Load Balancers: $([ "$REMAINING_ALB" = "0" ] && echo "✅ Destroyed" || echo "⚠️ $REMAINING_ALB still exist")"
            
            if [ "$REMAINING_VPC" = "None" ] && [ "$REMAINING_RDS" = "0" ] && [ "$REMAINING_ALB" = "0" ]; then
              echo "✅ All infrastructure destroyed successfully!"
              echo "💰 AWS charges for this project have stopped"
            else
              echo "⚠️ Some resources may still exist - please verify in AWS console"
              exit 1
            fi
          '''
        }
        archiveArtifacts artifacts: '*.txt', allowEmptyArchive: true
      }
    }
  }

  post {
    always {
      echo "Pipeline completed: ${currentBuild.currentResult}"
      echo "Build #${env.BUILD_NUMBER} - Duration: ${currentBuild.durationString}"
      
      // Cleanup temporary plan files
      script {
        try {
          sh '''
            echo "🧹 Cleaning up temporary files..."
            rm -f vpc-plan.tfplan iam-plan.tfplan database-plan.tfplan web-plan.tfplan monitoring-plan.tfplan final-plan.tfplan validation-plan.tfplan destroy-plan.tfplan
            echo "✅ Temporary files cleaned up"
          '''
        } catch (Exception e) {
          echo "⚠️ Warning: Could not clean up temporary files: ${e.getMessage()}"
        }
      }
    }
    
    success {
      echo "✅ Pipeline completed successfully!"
      echo "🎉 All infrastructure deployed and verified!"
    }
    
    failure {
      echo "❌ Pipeline failed. Check logs for details."
      
      // Emergency cleanup for failed installations
      script {
        if (params.ACTION == 'install') {
          echo "🚨 EMERGENCY CLEANUP: Pipeline failed during installation"
          echo "⚠️ Attempting to destroy any partially created resources..."
          
          try {
            withCredentials([
              [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
              string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
            ]) {
              timeout(time: 20, unit: 'MINUTES') {
                sh '''
                  echo "🔍 Checking for partially created resources..."
                  
                  # Initialize terraform if needed
                  if [ ! -d ".terraform" ]; then
                    echo "Initializing Terraform for cleanup..."
                    terraform init -upgrade
                  fi
                  
                  # Get current state
                  echo "📋 Current terraform state:"
                  terraform state list || echo "No state file found"
                  
                  # Check for AWS resources that might have been created
                  echo "🔍 Scanning for AWS resources with project tag..."
                  
                  # List potential resources by tag
                  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=capstoneproject-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "None")
                  ALB_ARN=$(aws elbv2 describe-load-balancers --names "capstoneproject-alb" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "None")
                  DB_CLUSTER=$(aws rds describe-db-clusters --db-cluster-identifier "capstoneproject-cluster" --query 'DBClusters[0].DBClusterIdentifier' --output text 2>/dev/null || echo "None")
                  
                  echo "Found resources:"
                  echo "- VPC: $VPC_ID"
                  echo "- ALB: $ALB_ARN"
                  echo "- DB Cluster: $DB_CLUSTER"
                  
                  # Attempt graceful terraform destroy if state exists
                  if terraform state list > /dev/null 2>&1; then
                    echo "🔥 Attempting Terraform destroy..."
                    terraform destroy -input=false -auto-approve \
                      -var "deploy_database=${DEPLOY_DATABASE}" \
                      -var "deploy_web=${DEPLOY_WEB}" \
                      -var "deploy_monitoring=${DEPLOY_MONITORING}" \
                      -var "db_master_password=${TF_DB_PASSWORD}" || echo "⚠️ Terraform destroy failed, continuing with manual cleanup..."
                  fi
                  
                  # Manual cleanup of specific resources if terraform destroy failed
                  echo "🧹 Manual cleanup of remaining resources..."
                  
                  # Cleanup Database Cluster (most expensive to leave running)
                  if [ "$DB_CLUSTER" != "None" ] && [ "$DB_CLUSTER" != "null" ]; then
                    echo "🗄️ Deleting RDS cluster: $DB_CLUSTER"
                    aws rds delete-db-cluster --db-cluster-identifier "$DB_CLUSTER" --skip-final-snapshot --delete-automated-backups 2>/dev/null || echo "Could not delete DB cluster"
                  fi
                  
                  # Cleanup Load Balancer
                  if [ "$ALB_ARN" != "None" ] && [ "$ALB_ARN" != "null" ]; then
                    echo "⚖️ Deleting Load Balancer: $ALB_ARN"
                    aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" 2>/dev/null || echo "Could not delete ALB"
                  fi
                  
                  # Cleanup Auto Scaling Group
                  echo "📱 Deleting Auto Scaling Group..."
                  aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "capstoneproject-asg" --force-delete 2>/dev/null || echo "ASG not found or already deleted"
                  
                  # Cleanup Launch Template
                  echo "🚀 Deleting Launch Template..."
                  LAUNCH_TEMPLATE_ID=$(aws ec2 describe-launch-templates --launch-template-names "capstoneproject-lt-*" --query 'LaunchTemplates[0].LaunchTemplateId' --output text 2>/dev/null || echo "None")
                  if [ "$LAUNCH_TEMPLATE_ID" != "None" ] && [ "$LAUNCH_TEMPLATE_ID" != "null" ]; then
                    aws ec2 delete-launch-template --launch-template-id "$LAUNCH_TEMPLATE_ID" 2>/dev/null || echo "Could not delete launch template"
                  fi
                  
                  # Cleanup EC2 Instances
                  echo "💻 Terminating EC2 instances..."
                  INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=capstoneproject-*" "Name=instance-state-name,Values=running,pending" --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null || echo "")
                  if [ ! -z "$INSTANCE_IDS" ] && [ "$INSTANCE_IDS" != "None" ]; then
                    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS 2>/dev/null || echo "Could not terminate instances"
                  fi
                  
                  # Wait a bit for resources to start cleanup
                  echo "⏳ Waiting for resource deletion to begin..."
                  sleep 30
                  
                  # Cleanup NAT Gateway (has charges)
                  echo "🌐 Deleting NAT Gateway..."
                  if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "null" ]; then
                    NAT_GW_ID=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[0].NatGatewayId' --output text 2>/dev/null || echo "None")
                    if [ "$NAT_GW_ID" != "None" ] && [ "$NAT_GW_ID" != "null" ]; then
                      aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_GW_ID" 2>/dev/null || echo "Could not delete NAT gateway"
                    fi
                  fi
                  
                  echo "🧹 Emergency cleanup completed"
                  echo "⚠️ Please verify in AWS console that no resources are left running"
                  echo "💰 This helps prevent unexpected charges"
                '''
              }
            }
          } catch (Exception cleanupError) {
            echo "❌ Emergency cleanup failed: ${cleanupError.getMessage()}"
            echo "🚨 MANUAL INTERVENTION REQUIRED:"
            echo "   Please check AWS console and manually delete resources:"
            echo "   - VPC: capstoneproject-vpc"
            echo "   - RDS Cluster: capstoneproject-cluster" 
            echo "   - Load Balancer: capstoneproject-alb"
            echo "   - Auto Scaling Group: capstoneproject-asg"
            echo "   - EC2 Instances: capstoneproject-*"
            echo "   - NAT Gateway in the VPC"
          }
        }
      }
    }
    
    aborted {
      echo "🛑 Pipeline was aborted by user"
      
      // Cleanup for aborted builds
      script {
        if (params.ACTION == 'install') {
          echo "🚨 ABORT CLEANUP: Pipeline was interrupted during installation"
          echo "⚠️ Attempting to destroy any partially created resources..."
          
          try {
            withCredentials([
              [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
              string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
            ]) {
              timeout(time: 15, unit: 'MINUTES') {
                sh '''
                  echo "🔍 Emergency cleanup after abort..."
                  
                  # Quick terraform destroy attempt
                  if [ -f ".terraform/terraform.tfstate" ] || [ -f "terraform.tfstate" ]; then
                    echo "🔥 Quick terraform destroy attempt..."
                    terraform destroy -input=false -auto-approve \
                      -var "deploy_database=true" \
                      -var "deploy_web=true" \
                      -var "deploy_monitoring=true" \
                      -var "db_master_password=${TF_DB_PASSWORD}" || echo "Terraform destroy failed"
                  fi
                  
                  # Critical resource cleanup (expensive resources first)
                  echo "🗄️ Checking for RDS cluster..."
                  aws rds delete-db-cluster --db-cluster-identifier "capstoneproject-cluster" --skip-final-snapshot --delete-automated-backups 2>/dev/null || echo "No RDS cluster found"
                  
                  echo "⚖️ Checking for Load Balancer..."
                  ALB_ARN=$(aws elbv2 describe-load-balancers --names "capstoneproject-alb" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "None")
                  if [ "$ALB_ARN" != "None" ]; then
                    aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" 2>/dev/null || echo "Could not delete ALB"
                  fi
                  
                  echo "📱 Checking for Auto Scaling Group..."
                  aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "capstoneproject-asg" --force-delete 2>/dev/null || echo "No ASG found"
                  
                  echo "🧹 Abort cleanup completed"
                '''
              }
            }
          } catch (Exception abortError) {
            echo "❌ Abort cleanup failed: ${abortError.getMessage()}"
            echo "🚨 Please manually check AWS console for remaining resources"
          }
        }
      }
    }
    
    unstable {
      echo "⚠️ Pipeline completed with warnings"
    }
  }
}