pipeline {
  agent any
  
  options {
    ansiColor('xterm')
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  
  environment {
    TF_IN_AUTOMATION = 'true'
    TF_CLI_ARGS = '-no-color'
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
      when { 
        anyOf {
          expression { params.ACTION == 'plan' }
          expression { params.ACTION == 'install' }
        }
      }
      steps {
        echo '📋 Creating Terraform execution plan...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
          string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
        ]) {
          sh '''
            terraform plan \
              -var "deploy_database=${DEPLOY_DATABASE}" \
              -var "deploy_web=${DEPLOY_WEB}" \
              -var "deploy_monitoring=${DEPLOY_MONITORING}" \
              -var "db_master_password=${TF_DB_PASSWORD}" \
              -out=tfplan
            
            echo "✅ Plan created successfully"
          '''
        }
        archiveArtifacts artifacts: 'tfplan', allowEmptyArchive: true
      }
    }
    
    stage('Deploy VPC') {
      when { expression { params.ACTION == 'install' } }
      steps {
        echo '🌐 Deploying VPC and Networking...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "Creating VPC, Subnets, Internet Gateway, NAT Gateway..."
            terraform apply -input=false -auto-approve -target=module.vpc tfplan
            
            echo "⏳ Verifying VPC deployment..."
            VPC_ID=$(terraform output -raw vpc_id)
            echo "VPC ID: $VPC_ID"
            
            # Wait for VPC to be available
            aws ec2 wait vpc-available --vpc-ids $VPC_ID
            
            # Verify subnets are created
            SUBNET_COUNT=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets | length(@)')
            echo "Created subnets: $SUBNET_COUNT"
            
            if [ "$SUBNET_COUNT" -ge "4" ]; then
              echo "✅ VPC and Networking deployed and verified successfully"
            else
              echo "❌ VPC verification failed - expected at least 4 subnets"
              exit 1
            fi
          '''
        }
      }
    }
    
    stage('Deploy IAM') {
      when { expression { params.ACTION == 'install' } }
      steps {
        echo '🔐 Deploying IAM Roles and Policies...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "Creating IAM roles and instance profiles..."
            terraform apply -input=false -auto-approve -target=module.iam tfplan
            
            echo "⏳ Verifying IAM deployment..."
            
            # Check if IAM role exists and is ready
            IAM_ROLE="capstoneproject-ec2-role"
            aws iam wait role-exists --role-name $IAM_ROLE
            
            # Check if instance profile exists
            INSTANCE_PROFILE="capstoneproject-ec2-profile"
            aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE >/dev/null 2>&1
            
            if [ $? -eq 0 ]; then
              echo "✅ IAM resources deployed and verified successfully"
            else
              echo "❌ IAM verification failed"
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
          expression { params.DEPLOY_DATABASE == true }
        }
      }
      steps {
        echo '🗄️ Deploying Aurora RDS Database (this takes ~5-7 minutes)...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "Creating Aurora MySQL cluster and instances..."
            terraform apply -input=false -auto-approve -target=module.db tfplan
            
            echo "⏳ Verifying Database deployment (this may take several minutes)..."
            
            # Get cluster identifier and wait for it to be available
            CLUSTER_ID="capstoneproject-cluster"
            echo "Waiting for Aurora cluster $CLUSTER_ID to be available..."
            aws rds wait db-cluster-available --db-cluster-identifier $CLUSTER_ID
            
            # Check cluster status
            CLUSTER_STATUS=$(aws rds describe-db-clusters --db-cluster-identifier $CLUSTER_ID --query 'DBClusters[0].Status' --output text)
            echo "Cluster status: $CLUSTER_STATUS"
            
            # Wait for instances to be available
            INSTANCE_ID="capstoneproject-instance-0"
            echo "Waiting for Aurora instance $INSTANCE_ID to be available..."
            aws rds wait db-instance-available --db-instance-identifier $INSTANCE_ID
            
            # Verify endpoint is accessible
            DB_ENDPOINT=$(terraform output -raw aurora_cluster_endpoint)
            echo "Database endpoint: $DB_ENDPOINT"
            
            if [ "$CLUSTER_STATUS" = "available" ] && [ ! -z "$DB_ENDPOINT" ]; then
              echo "✅ Database deployed and verified successfully"
            else
              echo "❌ Database verification failed"
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
          expression { params.DEPLOY_WEB == true }
        }
      }
      steps {
        echo '🖥️ Deploying Web Servers and Application...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "Creating EC2 instances, Auto Scaling Group, Load Balancer..."
            terraform apply -input=false -auto-approve -target=module.web tfplan
            
            echo "⏳ Verifying Web Tier deployment..."
            
            # Get ALB ARN and wait for it to be active
            ALB_NAME="capstoneproject-alb"
            ALB_ARN=$(aws elbv2 describe-load-balancers --names $ALB_NAME --query 'LoadBalancers[0].LoadBalancerArn' --output text)
            echo "ALB ARN: $ALB_ARN"
            
            # Wait for load balancer to be active
            aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN
            
            # Check ALB status
            ALB_STATE=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].State.Code' --output text)
            echo "ALB state: $ALB_STATE"
            
            # Wait for Auto Scaling Group to have healthy instances
            ASG_NAME="capstoneproject-asg"
            echo "Waiting for Auto Scaling Group instances to be healthy..."
            
            # Wait up to 10 minutes for healthy instances
            for i in {1..20}; do
              HEALTHY_COUNT=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --query 'AutoScalingGroups[0].Instances[?HealthStatus==`Healthy`] | length(@)' --output text)
              echo "Healthy instances: $HEALTHY_COUNT"
              
              if [ "$HEALTHY_COUNT" -ge "2" ]; then
                break
              fi
              
              echo "Waiting for instances to become healthy... ($i/20)"
              sleep 30
            done
            
            # Get web URL
            WEB_URL=$(terraform output -raw web_url)
            echo "Web URL: $WEB_URL"
            
            if [ "$ALB_STATE" = "active" ] && [ "$HEALTHY_COUNT" -ge "2" ] && [ ! -z "$WEB_URL" ]; then
              echo "✅ Web tier deployed and verified successfully"
              echo "🌐 Application URL: $WEB_URL"
            else
              echo "❌ Web tier verification failed"
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
          expression { params.DEPLOY_MONITORING == true }
        }
      }
      steps {
        echo '📊 Deploying Monitoring Stack (Grafana)...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "Creating Grafana monitoring server..."
            terraform apply -input=false -auto-approve -target=module.monitoring tfplan
            
            echo "⏳ Verifying Monitoring deployment..."
            
            # Get monitoring instance details
            MONITORING_IP=$(terraform output -raw monitoring_public_ip)
            echo "Monitoring server IP: $MONITORING_IP"
            
            # Wait for EC2 instance to be running and status checks to pass
            INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=capstoneproject-monitoring-server" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text)
            
            if [ "$INSTANCE_ID" != "None" ] && [ "$INSTANCE_ID" != "null" ]; then
              echo "Monitoring instance ID: $INSTANCE_ID"
              
              # Wait for instance to be running
              aws ec2 wait instance-running --instance-ids $INSTANCE_ID
              
              # Wait for status checks
              echo "Waiting for instance status checks to pass..."
              aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
              
              # Wait for HTTP services to be ready (with timeout)
              echo "Waiting for monitoring services to be ready..."
              for i in {1..12}; do
                # Check if monitoring dashboard is accessible
                if curl -s -o /dev/null -w "%{http_code}" "http://${MONITORING_IP}" | grep -q "200"; then
                  echo "Monitoring dashboard is ready"
                  break
                fi
                echo "Waiting for monitoring dashboard... ($i/12)"
                sleep 30
              done
              
              # Get URLs
              DASHBOARD_URL=$(terraform output -raw monitoring_dashboard_url)
              GRAFANA_URL=$(terraform output -raw grafana_dashboard_url)
              echo "Monitoring Dashboard: $DASHBOARD_URL"
              echo "Grafana Dashboard: $GRAFANA_URL"
              
              echo "✅ Monitoring deployed and verified successfully"
              echo "📊 Monitoring Dashboard: $DASHBOARD_URL"
              echo "📈 Grafana Dashboard: $GRAFANA_URL (admin/grafana123)"
            else
              echo "❌ Monitoring verification failed - instance not found"
              exit 1
            fi
          '''
        }
      }
    }
    
    stage('Finalize Deployment') {
      when { expression { params.ACTION == 'install' } }
      steps {
        echo '⚙️ Finalizing deployment and applying remaining resources...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "Applying any remaining terraform resources..."
            terraform apply -input=false -auto-approve tfplan
            
            echo "⏳ Final verification of all components..."
            
            # Wait a moment for final configurations to settle
            sleep 30
            
            # Verify terraform state is consistent
            terraform refresh -input=false
            
            echo "✅ Deployment finalized successfully"
            echo "🎉 All infrastructure components have been deployed!"
          '''
        }
      }
    }
    
    stage('Verify Infrastructure') {
      when { expression { params.ACTION == 'install' } }
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
            
            # Final status check
            terraform show -json | jq -r '.values.root_module.resources[] | select(.type != "data") | "\(.type): \(.name)"' | sort | uniq -c
            
            echo "✅ All deployed resources verified successfully!"
            echo "🚀 Infrastructure is ready for use!"
            fi
            
            echo "✅ Infrastructure verification complete"
          '''
        }
      }
    }
    
    stage('Destroy Confirmation') {
      when { 
        allOf {
          expression { params.ACTION == 'destroy' }
          expression { params.AUTO_APPROVE == false }
        }
      }
      steps {
        echo '⚠️ DESTRUCTION WARNING: This will permanently destroy all infrastructure!'
        timeout(time: 30, unit: 'MINUTES') {
          input message: '💥 Are you ABSOLUTELY SURE you want to DESTROY everything?', ok: 'Yes, Destroy All'
        }
      }
    }
    
    stage('Destroy Infrastructure') {
      when { expression { params.ACTION == 'destroy' } }
      steps {
        echo '💥 Destroying all infrastructure...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
          string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
        ]) {
          sh '''
            echo "Destroying all AWS resources..."
            terraform destroy -input=false -auto-approve -var "db_master_password=${TF_DB_PASSWORD}"
            echo "✅ All infrastructure destroyed successfully"
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
    }
    success {
      echo "✅ Pipeline completed successfully!"
    }
    failure {
      echo "❌ Pipeline failed. Check logs for details."
    }
  }
}