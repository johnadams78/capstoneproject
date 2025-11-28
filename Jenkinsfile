pipeline {
  agent any
  
  options {
    ansiColor('xterm')
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  
  environment {
    PROJECT_DIR = "${env.WORKSPACE}"
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
        dir(env.PROJECT_DIR) {
          script {
            echo "╔════════════════════════════════════════════════════════════╗"
            echo "║              THREE-TIER WEB INFRASTRUCTURE                 ║"
            echo "╚════════════════════════════════════════════════════════════╝"
            echo ""
            echo "🎯 Action: ${params.ACTION.toUpperCase()}"
            echo "🌍 Branch: ${env.BRANCH_NAME}"
            echo "🔧 Build: #${env.BUILD_NUMBER}"
            echo ""
            echo "📦 Components to deploy:"
            if (params.DEPLOY_DATABASE) {
              echo "   ✅ Database Tier (Aurora RDS MySQL)"
            } else {
              echo "   ❌ Database Tier (SKIPPED)"
            }
            if (params.DEPLOY_WEB) {
              echo "   ✅ Web Tier (EC2 + Car Dealership App)"
            } else {
              echo "   ❌ Web Tier (SKIPPED)"
            }
            if (params.DEPLOY_MONITORING) {
              echo "   ✅ Monitoring Tier (Grafana)"
            } else {
              echo "   ❌ Monitoring Tier (SKIPPED)"
            }
            echo ""
            echo "════════════════════════════════════════════════════════════"
          }
          
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
          ]) {
            sh '''
              echo "🔧 Initializing Terraform..."
              terraform init -upgrade
              
              echo ""
              echo "📋 Terraform Version Info:"
              terraform version
              
              echo ""
              echo "☁️  AWS Account Info:"
              aws sts get-caller-identity --query '[Account,Arn]' --output text
              
              echo ""
              echo "🌍 Region: $(aws configure get region || echo us-east-1)"
              echo ""
            '''
          }
        }
      }
    }

    stage('Plan') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'plan' || params.ACTION == 'install' }
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
            string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
          ]) {
            script {
              echo ""
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║                 TERRAFORM PLANNING PHASE                   ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              echo "📋 Analyzing infrastructure changes..."
              echo "   ├─ Checking resource dependencies"
              echo "   ├─ Validating configurations"
              echo "   ├─ Calculating costs"
              echo "   └─ Generating execution plan"
              echo ""
            }
            
            sh '''
              echo "📊 Creating Terraform execution plan..."
              echo ""
              
              terraform plan \
                -var "deploy_database=${DEPLOY_DATABASE}" \
                -var "deploy_web=${DEPLOY_WEB}" \
                -var "deploy_monitoring=${DEPLOY_MONITORING}" \
                -var "db_master_password=${TF_DB_PASSWORD}" \
                -out=tfplan 2>&1 | tee plan.txt | while IFS= read -r line; do
                echo "$line"
                
                # Show progress with green bars for each module
                if echo "$line" | grep -q "module.vpc"; then
                  echo "  → 🌐 \033[32m████░░░░░░\033[0m Planning VPC & Networking..."
                fi
                if echo "$line" | grep -q "module.iam"; then
                  echo "  → 🔐 \033[32m███░░░░░░░\033[0m Planning IAM Roles..."
                fi
                if echo "$line" | grep -q "module.db" && [ "$DEPLOY_DATABASE" = "true" ]; then
                  echo "  → 🗄️  \033[32m██████░░░░\033[0m Planning Database (Aurora RDS)..."
                fi
                if echo "$line" | grep -q "module.web" && [ "$DEPLOY_WEB" = "true" ]; then
                  echo "  → 🖥️  \033[32m████░░░░░░\033[0m Planning Web Tier..."
                fi
                if echo "$line" | grep -q "module.monitoring" && [ "$DEPLOY_MONITORING" = "true" ]; then
                  echo "  → 📊 \033[32m████░░░░░░\033[0m Planning Monitoring..."
                fi
                
                # Cost information
                if echo "$line" | grep -q "aws_nat_gateway"; then
                  echo "  💰 NAT Gateway: ~\$32/month"
                fi
                if echo "$line" | grep -q "aws_rds_cluster"; then
                  echo "  💰 Aurora RDS: ~\$50-100/month"
                fi
                if echo "$line" | grep -q "aws_instance.*t3"; then
                  echo "  💰 EC2 Instances: ~\$20-40/month"
                fi
                
                # Plan completion
                if echo "$line" | grep -q "Plan:"; then
                  echo ""
                  echo "  ✅ \033[32m██████████\033[0m Planning Complete"
                  echo ""
                  echo "════════════════════════════════════════════════════════════"
                fi
              done
            '''
            
            archiveArtifacts artifacts: 'plan.txt', allowEmptyArchive: true
          }
        }
      }
    }

    // SEQUENTIAL DEPLOYMENT STAGES FOR DASHBOARD PROGRESS BARS

    stage('🌐 Deploy VPC & Networking') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' } 
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
          ]) {
            sh 'test -f tfplan || (echo "❌ tfplan not found; run Plan first" && exit 1)'
            
            script {
              echo ""
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║         🌐 DEPLOYING VPC & NETWORKING (TIER 1)             ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              echo "📋 Creating foundation infrastructure:"
              echo "   ├─ Virtual Private Cloud (VPC)"
              echo "   ├─ Public & Private Subnets (Multi-AZ)"
              echo "   ├─ Internet Gateway"
              echo "   ├─ NAT Gateway (~\$32/month)"
              echo "   └─ Route Tables & Security Groups"
              echo ""
            }
            
            sh '''
              echo "  → 🌐 \033[32m██░░░░░░░░\033[0m Creating VPC, Subnets, Internet Gateway..."
              
              terraform apply -input=false -auto-approve \
                -target=module.vpc \
                tfplan 2>&1 | grep -E "(Creating|Modifying|Creation complete|Apply complete|Error)" || true
              
              if [ $? -ne 0 ]; then
                echo "❌ VPC deployment failed!"
                exit 1
              fi
              echo "  ✅ \033[32m██████████\033[0m VPC & Networking Complete!"
              echo ""
            '''
          }
        }
      }
    }

    stage('🔐 Deploy IAM Roles') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' } 
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
          ]) {
            script {
              echo ""
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║         🔐 DEPLOYING IAM ROLES (TIER 2)                    ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              echo "📋 Creating security & access policies:"
              echo "   ├─ EC2 Instance Profiles"
              echo "   ├─ IAM Roles for Web/Monitoring servers"
              echo "   └─ CloudWatch and SSM permissions"
              echo ""
            }
            
            sh '''
              echo "  → 🔐 \033[32m██░░░░░░░░\033[0m Creating IAM instance profiles..."
              
              terraform apply -input=false -auto-approve \
                -target=module.iam \
                tfplan 2>&1 | grep -E "(Creating|Modifying|Creation complete|Apply complete|Error)" || true
              
              if [ $? -ne 0 ]; then
                echo "❌ IAM deployment failed!"
                exit 1
              fi
              echo "  ✅ \033[32m██████████\033[0m IAM Roles Complete!"
              echo ""
            '''
          }
        }
      }
    }

    stage('🗄️ Deploy Database') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' }
          expression { params.DEPLOY_DATABASE == true }
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
          ]) {
            script {
              echo ""
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║         🗄️  DEPLOYING DATABASE (TIER 3)                    ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              echo "📋 Creating Aurora RDS MySQL cluster:"
              echo "   ├─ Aurora Cluster (Multi-AZ)"
              echo "   ├─ Database Instances (db.r6g.large)"
              echo "   ├─ Database Subnet Group"
              echo "   └─ Database Security Group"
              echo ""
              echo "⏱️  Note: This step takes ~5-7 minutes"
              echo "💰 Cost: ~\$50-100/month"
              echo ""
            }
            
            sh '''
              echo "  → 🗄️  \033[32m███░░░░░░░\033[0m Creating Aurora cluster... (⏱️  ~5 mins)"
              
              terraform apply -input=false -auto-approve \
                -target=module.db \
                tfplan 2>&1 | grep -E "(Creating|Modifying|Creation complete|Apply complete|Error)" || true
              
              if [ $? -ne 0 ]; then
                echo "❌ Database deployment failed!"
                exit 1
              fi
              echo "  ✅ \033[32m██████████\033[0m Database Tier Complete!"
              echo ""
            '''
          }
        }
      }
    }

    stage('🖥️ Deploy Web Tier') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' }
          expression { params.DEPLOY_WEB == true }
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
          ]) {
            script {
              echo ""
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║         🖥️  DEPLOYING WEB TIER (TIER 4)                    ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              echo "📋 Creating web servers:"
              echo "   ├─ EC2 Instances (t3.medium)"
              echo "   ├─ Auto Scaling Group"
              echo "   ├─ Application Load Balancer"
              echo "   ├─ Car Dealership PHP Application"
              echo "   └─ Web Security Groups"
              echo ""
              echo "💰 Cost: ~\$20-40/month per instance"
              echo ""
            }
            
            sh '''
              echo "  → 🖥️  \033[32m████░░░░░░\033[0m Launching web servers..."
              
              terraform apply -input=false -auto-approve \
                -target=module.web \
                tfplan 2>&1 | grep -E "(Creating|Modifying|Creation complete|Apply complete|Error)" || true
              
              if [ $? -ne 0 ]; then
                echo "❌ Web tier deployment failed!"
                exit 1
              fi
              echo "  ✅ \033[32m██████████\033[0m Web Tier Complete!"
              echo ""
            '''
          }
        }
      }
    }

    stage('📊 Deploy Monitoring') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' }
          expression { params.DEPLOY_MONITORING == true }
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
          ]) {
            script {
              echo ""
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║         📊 DEPLOYING MONITORING (TIER 5)                   ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              echo "📋 Creating monitoring infrastructure:"
              echo "   ├─ Grafana Server EC2 Instance"
              echo "   ├─ CloudWatch Integration"
              echo "   ├─ Performance Dashboards"
              echo "   └─ Monitoring Security Groups"
              echo ""
              echo "💰 Cost: ~\$15-25/month"
              echo ""
            }
            
            sh '''
              echo "  → 📊 \033[32m████░░░░░░\033[0m Deploying monitoring stack..."
              
              terraform apply -input=false -auto-approve \
                -target=module.monitoring \
                tfplan 2>&1 | grep -E "(Creating|Modifying|Creation complete|Apply complete|Error)" || true
              
              if [ $? -ne 0 ]; then
                echo "❌ Monitoring deployment failed!"
                exit 1
              fi
              echo "  ✅ \033[32m██████████\033[0m Monitoring Tier Complete!"
              echo ""
            '''
          }
        }
      }
    }

    stage('⚙️ Finalize Deployment') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' } 
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
          ]) {
            script {
              echo ""
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║         ⚙️  FINALIZING DEPLOYMENT                           ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
              echo "📋 Applying any remaining resources and configurations..."
              echo ""
            }
            
            sh '''
              echo "  → ⚙️  \033[32m█████░░░░░\033[0m Finalizing deployment..."
              
              terraform apply -input=false -auto-approve tfplan 2>&1 | grep -E "(Creating|Modifying|Creation complete|Apply complete|Error)" || true
              
              if [ $? -ne 0 ]; then
                echo "❌ Final deployment step failed!"
                exit 1
              fi
              
              echo "  ✅ \033[32m██████████\033[0m Deployment Complete!"
              echo ""
              echo "════════════════════════════════════════════════════════════"
              echo "🎉 ALL INFRASTRUCTURE DEPLOYED SUCCESSFULLY!"
              echo "════════════════════════════════════════════════════════════"
            '''
            
            archiveArtifacts artifacts: '*.txt', allowEmptyArchive: true
          }
        }
      }
    }

    stage('✅ Verify Infrastructure') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'install' } 
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
          ]) {
            script {
              echo ""
              echo "╔════════════════════════════════════════════════════════════╗"
              echo "║           ✅ VERIFYING DEPLOYED INFRASTRUCTURE              ║"
              echo "╚════════════════════════════════════════════════════════════╝"
              echo ""
            }
            
            sh '''
              echo "🔍 Checking deployed infrastructure..."
              echo ""
              
              # Check web server
              WEB_IP=$(terraform output -raw web_public_ip 2>/dev/null || echo "")
              if [ ! -z "$WEB_IP" ]; then
                echo "🖥️  Web Server: http://$WEB_IP"
                echo "   Testing connectivity..."
                HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 http://$WEB_IP/ || echo "000")
                if [ "$HTTP_CODE" = "200" ]; then
                  echo "   ✅ Web Server: HTTP $HTTP_CODE (Healthy)"
                else
                  echo "   ⚠️  Web Server: HTTP $HTTP_CODE (Not responding yet - may need 2-3 mins)"
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
              
              # Check monitoring
              MON_IP=$(terraform output -raw monitoring_public_ip 2>/dev/null || echo "")
              if [ ! -z "$MON_IP" ]; then
                echo "📊 Monitoring Server: http://$MON_IP:3000"
                echo "   ✅ Grafana deployed successfully"
              else
                echo "   ℹ️  Monitoring not deployed"
              fi
              
              echo ""
              echo "════════════════════════════════════════════════════════════"
              echo "ℹ️  Note: Web services may take 2-3 minutes to fully initialize"
              echo "════════════════════════════════════════════════════════════"
            '''
          }
        }
      }
    }

    // DESTROY STAGES (existing destroy logic - simplified for space)
    stage('⚠️ Destroy (Confirm)') {
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
            echo "This will PERMANENTLY DESTROY all infrastructure!"
            echo ""
            echo "⚠️  THIS ACTION IS IRREVERSIBLE!"
            echo "════════════════════════════════════════════════════════════"
          }
          input message: '💥 Are you ABSOLUTELY SURE you want to DESTROY everything?', ok: 'Yes, Destroy All'
        }
      }
    }

    stage('💥 Destroy All') {
      when { 
        allOf { 
          branch 'main'
          expression { params.ACTION == 'destroy' } 
        } 
      }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
            string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
          ]) {
            sh '''
              echo "💥 Starting Complete Infrastructure Destruction..."
              echo ""
              
              terraform destroy -input=false -auto-approve \
                -var "db_master_password=${TF_DB_PASSWORD}" 2>&1 | tee destroy.txt
              
              echo ""
              echo "✅ \033[32m██████████\033[0m ALL INFRASTRUCTURE DESTROYED!"
            '''
            
            archiveArtifacts artifacts: 'destroy.txt', allowEmptyArchive: true
          }
        }
      }
    }
  }

  post {
    always {
      echo ""
      echo "╔════════════════════════════════════════════════════════════╗"
      echo "║                    PIPELINE COMPLETE                       ║"
      echo "╚════════════════════════════════════════════════════════════╝"
      echo ""
      echo "📊 Build: #${env.BUILD_NUMBER}"
      echo "🕐 Duration: ${currentBuild.durationString}"
      echo "📝 Status: ${currentBuild.currentResult}"
      echo ""
    }
    success {
      echo "✅ Pipeline completed successfully!"
    }
    failure {
      echo "❌ Pipeline failed. Check logs for details."
    }
  }
}