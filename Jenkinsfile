pipeline {
  agent any

  options {
    ansiColor('xterm')
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action to perform')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    AWS_DEFAULT_REGION = "${env.AWS_DEFAULT_REGION ?: 'us-east-1'}"
    PROJECT_DIR = '.'
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
        sh 'terraform -version || (echo "Terraform not found on agent" && exit 1)'
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
          sh 'terraform fmt -check -diff || true'
          sh 'terraform validate'
        }
      }
    }

    stage('Plan') {
      when { anyOf { expression { params.ACTION == 'plan' }; expression { params.ACTION == 'apply' } } }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-terraform'],
            string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
          ]) {
            sh 'terraform plan -input=false -out=tfplan -var "db_master_password=${TF_DB_PASSWORD}" | tee plan.txt'
            archiveArtifacts artifacts: 'plan.txt', onlyIfSuccessful: true
          }
        }
      }
    }

    stage('Approve Apply') {
      when { allOf { branch 'main'; expression { params.ACTION == 'apply' } } }
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: 'Apply Terraform changes to AWS?', ok: 'Apply'
        }
      }
    }

    stage('Apply') {
      when { allOf { branch 'main'; expression { params.ACTION == 'apply' } } }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-terraform']
          ]) {
            sh 'test -f tfplan || (echo "tfplan not found; run Plan first" && exit 1)'
            sh 'terraform apply -input=false -auto-approve tfplan'
          }
        }
      }
    }

    stage('Destroy (Confirm)') {
      when { allOf { branch 'main'; expression { params.ACTION == 'destroy' } } }
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: 'Destroy ALL infrastructure? This is irreversible.', ok: 'Destroy'
        }
      }
    }

    stage('Destroy') {
      when { allOf { branch 'main'; expression { params.ACTION == 'destroy' } } }
      steps {
        dir(env.PROJECT_DIR) {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-terraform'],
            string(credentialsId: 'tf-db-password', variable: 'TF_DB_PASSWORD')
          ]) {
            sh 'terraform destroy -input=false -auto-approve -var "db_master_password=${TF_DB_PASSWORD}"'
          }
        }
      }
    }
  }

  post {
    always {
      dir(env.PROJECT_DIR) {
        archiveArtifacts artifacts: '.terraform.lock.hcl, **/*.tf', onlyIfSuccessful: false, allowEmptyArchive: true
      }
    }
  }
}
