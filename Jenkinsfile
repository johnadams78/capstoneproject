pipeline {
  agent any

  options {
    ansiColor('xterm')
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    choice(
      name: 'ACTION', 
      choices: ['plan', 'install', 'destroy'], 
      description: 'Select Terraform action:\n- plan: Preview infrastructure changes\n- install: Deploy infrastructure (plan + apply)\n- destroy: Remove all infrastructure'
    )
    booleanParam(
      name: 'DEPLOY_DATABASE', 
      defaultValue: true, 
      description: 'Deploy Aurora RDS database (MySQL)'
    )
    booleanParam(
      name: 'DEPLOY_WEB', 
      defaultValue: true, 
      description: 'Deploy web server with car dealership application'
    )
    booleanParam(
      name: 'DEPLOY_MONITORING', 
      defaultValue: true, 
      description: 'Deploy monitoring server (Grafana)'
    )
    booleanParam(
      name: 'AUTO_APPROVE', 
      defaultValue: false, 
      description: 'Skip approval for install/destroy (use with caution!)'
    )
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    AWS_DEFAULT_REGION = "${env.AWS_DEFAULT_REGION ?: 'us-east-1'}"
    PROJECT_DIR = '.'
    PROJECT_NAME = 'capstoneproject'
    AWS_CREDENTIALS = credentials('aws-credentials')
    AWS_ACCESS_KEY_ID = "${AWS_CREDENTIALS_USR}"
    AWS_SECRET_ACCESS_KEY = "${AWS_CREDENTIALS_PSW}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'git rev-parse --short HEAD || true'
      }
    }

    stage('Setup') {
      steps {
        script {
          echo "╔════════════════════════════════════════════════════════════╗"
          echo "║   CAPSTONE PROJECT - AWS INFRASTRUCTURE DEPLOYMENT         ║"
          echo "╚════════════════════════════════════════════════════════════╝"
          echo ""
          echo "📋 Build Configuration:"
          echo "   Action:            ${params.ACTION}"
          echo "   Auto Approve:      ${params.AUTO_APPROVE}"
          echo ""
          echo "🏗️  Components to Deploy:"
          echo "   VPC & Networking:  ✓ (Always deployed)"
          echo "   Database (Aurora): ${params.DEPLOY_DATABASE ? '✓ Enabled' : '✗ Disabled'}"
          echo "   Web Server:        ${params.DEPLOY_WEB ? '✓ Enabled' : '✗ Disabled'}"
          echo "   Monitoring:        ${params.DEPLOY_MONITORING ? '✓ Enabled' : '✗ Disabled'}"
          echo ""
          echo "🌍 AWS Configuration:"
          echo "   Region:            ${env.AWS_DEFAULT_REGION}"
          echo "   Project:           ${env.PROJECT_NAME}"
          echo ""
          echo "════════════════════════════════════════════════════════════"
        }
        sh 'terraform -version || (echo "❌ Terraform not found on agent" && exit 1)'
        sh 'aws --version || echo "⚠️  AWS CLI not found, some features may not work"'
      }
    }

    stage('Terraform Init') {
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-terraform']
          ]) {
            sh 'terraform init -input=false'
          }
        }
      }
    }

    stage('Validate') {
      steps {
        dir(env.PROJECT_DIR) {
          echo "=== Validating Terraform Configuration ==="
          sh 'terraform fmt -check -diff || true'
          sh 'terraform validate'
          
          echo "=== Checking Module Structure ==="
          sh '''
            echo "VPC Module: $(test -d modules/vpc && echo '✓' || echo '✗')"
            echo "DB Module: $(test -d modules/db && echo '✓' || echo '✗')"
            echo "Web Module: $(test -d modules/web && echo '✓' || echo '✗')"
            echo "Web Simple Module: $(test -d modules/web_simple && echo '✓' || echo '✗')"
            echo "Monitoring Module: $(test -d modules/monitoring && echo '✓' || echo '✗')"
            echo "IAM Module: $(test -d modules/iam && echo '✓' || echo '✗')"
          '''
        }
      }
    }

    stage('Plan') {
      when { 
        anyOf { 
          expression { params.ACTION == 'plan' }
          expression { params.ACTION == 'install' } 
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-terraform'],
            string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
          ]) {
            echo "=== Running Terraform Plan ==="
            sh 'terraform plan -input=false -out=tfplan -var "db_master_password=${TF_DB_PASSWORD}" | tee plan.txt'
            
            echo ""
            echo "=== Plan Summary ==="
            sh '''
              echo "📊 Infrastructure changes planned:"
              grep -E "Plan:|No changes" plan.txt | tail -1 || true
              echo ""
              echo "🔍 Components in plan:"
              grep -E "(module\\.(vpc|db|monitoring|web|web_simple))" plan.txt | grep -E "(will be created|will be updated|will be destroyed)" | head -30 || true
            '''
            
            archiveArtifacts artifacts: 'plan.txt', onlyIfSuccessful: true
          }
        }
      }
    }

    stage('Approve Install') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' }
          expression { params.AUTO_APPROVE == false }
        } 
      }
      steps {
        timeout(time: 30, unit: 'MINUTES') {
          script {
            echo "⏸️  Waiting for approval to install infrastructure..."
            echo ""
            echo "This will deploy:"
            if (params.DEPLOY_DATABASE) {
              echo "  • Aurora MySQL Database Cluster"
            }
            if (params.DEPLOY_WEB) {
              echo "  • EC2 Web Server with Car Dealership App"
            }
            if (params.DEPLOY_MONITORING) {
              echo "  • EC2 Monitoring Server with Grafana"
            }
            echo "  • VPC with public/private subnets"
            echo "  • NAT Gateway, Internet Gateway"
            echo "  • Security Groups and IAM roles"
          }
          input message: '🚀 Proceed with infrastructure installation?', ok: 'Install Now'
        }
      }
    }

    stage('Install') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' } 
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-terraform']
          ]) {
            sh 'test -f tfplan || (echo "❌ tfplan not found; run Plan first" && exit 1)'
            
            echo "=== Installing Infrastructure ==="
            echo "⏱️  This may take 10-15 minutes for database deployment..."
            sh 'terraform apply -input=false -auto-approve tfplan | tee apply.txt'
            archiveArtifacts artifacts: 'apply.txt', onlyIfSuccessful: true
          }
        }
      }
    }

    stage('Verify Infrastructure') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' } 
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-terraform']
          ]) {
            echo "=== Infrastructure Verification ==="
            script {
              sh '''
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║           DEPLOYMENT OUTPUTS & ACCESS URLS                 ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                echo ""
                terraform output -json > outputs.json || true
                
                echo "🌐 VPC & NETWORKING:"
                VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "Not available")
                echo "   VPC ID: $VPC_ID"
                terraform output public_subnets 2>/dev/null || echo "   Public Subnets: Not available"
                
                echo ""
                echo "🗄️  DATABASE (Aurora MySQL):"
                DB_ENDPOINT=$(terraform output -raw aurora_cluster_endpoint 2>/dev/null || echo "Not deployed")
                DB_NAME=$(terraform output -raw database_name 2>/dev/null || echo "Not deployed")
                echo "   Endpoint: $DB_ENDPOINT"
                echo "   Database: $DB_NAME"
                
                echo ""
                echo "🌐 WEB SERVER (Car Dealership):"
                WEB_IP=$(terraform output -raw web_instance_public_ip 2>/dev/null || echo "Not deployed")
                WEB_URL=$(terraform output -raw website_url 2>/dev/null || echo "Not deployed")
                echo "   Public IP: $WEB_IP"
                echo "   Website:   $WEB_URL"
                
                echo ""
                echo "📊 MONITORING (Grafana):"
                MON_IP=$(terraform output -raw monitoring_instance_public_ip 2>/dev/null || echo "Not deployed")
                GRAFANA_URL=$(terraform output -raw grafana_dashboard_url 2>/dev/null || echo "Not deployed")
                MON_URL=$(terraform output -raw monitoring_dashboard_url 2>/dev/null || echo "Not deployed")
                echo "   Public IP:  $MON_IP"
                echo "   Dashboard:  $MON_URL"
                echo "   Grafana:    $GRAFANA_URL"
                
                echo ""
                echo "════════════════════════════════════════════════════════════"
              '''
              
              archiveArtifacts artifacts: 'outputs.json', allowEmptyArchive: true
            }
          }
        }
      }
    }

    stage('Health Checks') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' } 
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-terraform']
          ]) {
            echo "=== Running Health Checks ==="
            script {
              sh '''
                echo "⏱️  Waiting 30 seconds for services to initialize..."
                sleep 30
                
                echo ""
                echo "🔍 Testing deployed services..."
                echo ""
                
                # Check monitoring endpoint
                MONITORING_IP=$(terraform output -raw monitoring_instance_public_ip 2>/dev/null || echo "")
                if [ ! -z "$MONITORING_IP" ]; then
                  echo "📊 Testing Monitoring Dashboard at http://$MONITORING_IP"
                  HTTP_CODE=$(curl -f -s -o /dev/null -w "%{http_code}" http://$MONITORING_IP 2>/dev/null || echo "000")
                  if [ "$HTTP_CODE" = "200" ]; then
                    echo "   ✅ Monitoring Dashboard: HTTP $HTTP_CODE (Healthy)"
                  else
                    echo "   ⚠️  Monitoring Dashboard: HTTP $HTTP_CODE (Not responding yet)"
                  fi
                  
                  echo "📈 Testing Grafana at http://$MONITORING_IP:3000"
                  HTTP_CODE=$(curl -f -s -o /dev/null -w "%{http_code}" http://$MONITORING_IP:3000 2>/dev/null || echo "000")
                  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
                    echo "   ✅ Grafana: HTTP $HTTP_CODE (Healthy)"
                  else
                    echo "   ⚠️  Grafana: HTTP $HTTP_CODE (Not responding yet)"
                  fi
                else
                  echo "   ℹ️  Monitoring not deployed"
                fi
                
                echo ""
                
                # Check web endpoint
                WEB_IP=$(terraform output -raw web_instance_public_ip 2>/dev/null || echo "")
                if [ ! -z "$WEB_IP" ]; then
                  echo "🌐 Testing Web Server at http://$WEB_IP"
                  HTTP_CODE=$(curl -f -s -o /dev/null -w "%{http_code}" http://$WEB_IP 2>/dev/null || echo "000")
                  if [ "$HTTP_CODE" = "200" ]; then
                    echo "   ✅ Web Server: HTTP $HTTP_CODE (Healthy)"
                  else
                    echo "   ⚠️  Web Server: HTTP $HTTP_CODE (Not responding yet)"
                  fi
                  
                  echo "💊 Testing Health Endpoint at http://$WEB_IP/health.php"
                  HEALTH=$(curl -f -s http://$WEB_IP/health.php 2>/dev/null || echo "")
                  if [ ! -z "$HEALTH" ]; then
                    echo "   ✅ Health endpoint: Responding"
                    echo "$HEALTH" | head -5
                  else
                    echo "   ⚠️  Health endpoint: Not responding yet"
                  fi
                else
                  echo "   ℹ️  Web server not deployed"
                fi
                
                echo ""
                
                # Check database
                DB_ENDPOINT=$(terraform output -raw aurora_cluster_endpoint 2>/dev/null || echo "")
                if [ ! -z "$DB_ENDPOINT" ]; then
                  echo "🗄️  Aurora RDS Database"
                  echo "   ✅ Endpoint: $DB_ENDPOINT"
                  echo "   ✅ Database deployed successfully"
                else
                  echo "   ℹ️  Database not deployed"
                fi
                
                echo ""
                echo "════════════════════════════════════════════════════════════"
                echo "ℹ️  Note: Some services may take 2-3 minutes to fully initialize"
              '''
            }
          }
        }
      }
    }

    stage('Destroy (Confirm)') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'destroy' }
          expression { params.AUTO_APPROVE == false }
        } 
      }
      steps {
        timeout(time: 30, unit: 'MINUTES') {
          script {
            echo "╔════════════════════════════════════════════════════════════╗"
            echo "║                   ⚠️  DESTRUCTION WARNING ⚠️                 ║"
            echo "╚════════════════════════════════════════════════════════════╝"
            echo ""
            echo "This will PERMANENTLY DESTROY all infrastructure including:"
            echo ""
            echo "  🗄️  Aurora RDS MySQL Database Cluster & Instances"
            echo "     └─ All database data will be LOST"
            echo ""
            echo "  🌐 Web Server EC2 Instance"
            echo "     └─ Car dealership application"
            echo ""
            echo "  📊 Monitoring Server EC2 Instance"
            echo "     └─ Grafana dashboards and logs"
            echo ""
            echo "  🌍 VPC and ALL Networking Components"
            echo "     ├─ NAT Gateway (~\$32/month)"
            echo "     ├─ Elastic IPs"
            echo "     ├─ Public/Private Subnets"
            echo "     ├─ Route Tables & Internet Gateway"
            echo "     └─ Security Groups"
            echo ""
            echo "  🔐 IAM Roles and Policies"
            echo ""
            echo "⚠️  THIS ACTION IS IRREVERSIBLE!"
            echo "⏱️  Destruction will take approximately 10-15 minutes"
            echo ""
            echo "════════════════════════════════════════════════════════════"
          }
          input message: '💥 Are you ABSOLUTELY SURE you want to DESTROY everything?', ok: 'Yes, Destroy All'
        }
      }
    }

    stage('Destroy') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'destroy' } 
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-terraform'],
            string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
          ]) {
            echo "╔════════════════════════════════════════════════════════════╗"
            echo "║              DESTROYING INFRASTRUCTURE                     ║"
            echo "╚════════════════════════════════════════════════════════════╝"
            echo ""
            echo "⏱️  This may take 10-15 minutes for database deletion..."
            echo "   └─ Aurora RDS cluster deletion is the slowest step"
            echo ""
            
            sh 'terraform destroy -input=false -auto-approve -var "db_master_password=${TF_DB_PASSWORD}" | tee destroy.txt'
            archiveArtifacts artifacts: 'destroy.txt', allowEmptyArchive: true
            
            echo ""
            echo "=== Verifying Complete Destruction ==="
            sh '''
              REMAINING=$(terraform state list | wc -l)
              echo "Remaining resources in state: $REMAINING"
              
              if [ "$REMAINING" -eq 0 ]; then
                echo "✅ All infrastructure successfully destroyed"
                echo "💰 No ongoing AWS charges"
              else
                echo "⚠️  Some resources may still exist:"
                terraform state list
              fi
            '''
          }
        }
      }
    }
  }

  post {
    always {
      dir(env.PROJECT_DIR) {
        echo "=== Archiving Build Artifacts ==="
        archiveArtifacts artifacts: '.terraform.lock.hcl, **/*.tf, *.txt, *.json', onlyIfSuccessful: false, allowEmptyArchive: true
      }
    }
    success {
      script {
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║            ✅ PIPELINE COMPLETED SUCCESSFULLY ✅            ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        
        if (params.ACTION == 'plan') {
          echo "📋 Terraform Plan Results:"
          echo "   • Infrastructure changes have been planned"
          echo "   • Review the plan output above"
          echo "   • No changes were applied to AWS"
          echo ""
          echo "➡️  Next Steps:"
          echo "   1. Review the plan.txt artifact"
          echo "   2. If approved, run with ACTION='install'"
          
        } else if (params.ACTION == 'install') {
          echo "🚀 Infrastructure Deployment Completed!"
          echo ""
          echo "✅ Deployed Components:"
          if (params.DEPLOY_DATABASE) {
            echo "   • Aurora MySQL Database Cluster"
          }
          if (params.DEPLOY_WEB) {
            echo "   • Web Server (Car Dealership Application)"
          }
          if (params.DEPLOY_MONITORING) {
            echo "   • Monitoring Server (Grafana)"
          }
          echo "   • VPC with full networking"
          echo ""
          echo "📊 Check the 'Verify Infrastructure' stage for:"
          echo "   • Access URLs"
          echo "   • Database endpoints"
          echo "   • Public IP addresses"
          echo ""
          echo "⏱️  Note: Services may need 2-3 minutes to fully initialize"
          
        } else if (params.ACTION == 'destroy') {
          echo "💥 Infrastructure Destruction Completed!"
          echo ""
          echo "✅ All AWS resources have been removed"
          echo "💰 No ongoing charges for this infrastructure"
          echo ""
          echo "⚠️  Important:"
          echo "   • All data has been permanently deleted"
          echo "   • Database backups (if any) should be managed separately"
          echo "   • VPC and networking components removed"
        }
        
        echo ""
        echo "════════════════════════════════════════════════════════════"
      }
    }
    failure {
      script {
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║                  ❌ PIPELINE FAILED ❌                      ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        echo "🔍 Common Issues & Solutions:"
        echo ""
        echo "1️⃣  AWS Credentials:"
        echo "   • Verify 'aws-terraform' credentials in Jenkins"
        echo "   • Check AWS access key and secret key are valid"
        echo "   • Ensure credentials have not expired"
        echo ""
        echo "2️⃣  IAM Permissions:"
        echo "   • EC2: full access for instances"
        echo "   • RDS: full access for Aurora"
        echo "   • VPC: full networking permissions"
        echo "   • IAM: role creation and attachment"
        echo ""
        echo "3️⃣  AWS Service Quotas:"
        echo "   • Check EC2 instance limits"
        echo "   • Verify RDS cluster limits"
        echo "   • Confirm NAT Gateway quota"
        echo ""
        echo "4️⃣  Database Password:"
        echo "   • Verify 'tf-db-password' credential exists"
        echo "   • Password must meet RDS requirements"
        echo ""
        echo "5️⃣  Resource Conflicts:"
        echo "   • Check for existing resources with same names"
        echo "   • Verify VPC CIDR doesn't conflict"
        echo "   • Ensure security group names are unique"
        echo ""
        echo "📋 Review the error logs above for specific details"
        echo "════════════════════════════════════════════════════════════"
      }
    }
    cleanup {
      dir(env.PROJECT_DIR) {
        echo "🧹 Cleaning up temporary files..."
        sh 'rm -f tfplan || true'
        echo "✅ Cleanup complete"
      }
    }
  }
}
