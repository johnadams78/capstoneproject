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
            echo "✅ VPC and Networking deployed successfully"
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
            echo "✅ IAM resources deployed successfully"
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
            echo "✅ Database deployed successfully"
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
            echo "✅ Web tier deployed successfully"
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
            echo "✅ Monitoring deployed successfully"
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
            echo "✅ Deployment finalized successfully"
          '''
        }
      }
    }
    
    stage('Verify Infrastructure') {
      when { expression { params.ACTION == 'install' } }
      steps {
        echo '✅ Verifying deployed infrastructure...'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            echo "Checking infrastructure status..."
            
            # Check VPC
            echo "VPC ID: $(terraform output -raw vpc_id 2>/dev/null || echo 'Not deployed')"
            
            # Check Web Server
            WEB_IP=$(terraform output -raw web_public_ip 2>/dev/null || echo "")
            if [ ! -z "$WEB_IP" ]; then
              echo "Web Server: http://$WEB_IP"
            else
              echo "Web Server: Not deployed"
            fi
            
            # Check Database
            DB_ENDPOINT=$(terraform output -raw aurora_cluster_endpoint 2>/dev/null || echo "")
            if [ ! -z "$DB_ENDPOINT" ]; then
              echo "Database Endpoint: $DB_ENDPOINT"
            else
              echo "Database: Not deployed"
            fi
            
            # Check Monitoring
            MON_IP=$(terraform output -raw monitoring_public_ip 2>/dev/null || echo "")
            if [ ! -z "$MON_IP" ]; then
              echo "Monitoring: http://$MON_IP:3000"
            else
              echo "Monitoring: Not deployed"
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