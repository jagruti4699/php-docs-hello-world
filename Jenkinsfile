pipeline {
  agent any

  environment {
    ARM_CLIENT_ID       = credentials('azure-client-id')
    ARM_CLIENT_SECRET   = credentials('azure-client-secret')
    ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
    ARM_TENANT_ID       = credentials('azure-tenant-id')
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://your-repo-url.git'
      }
    }

    stage('Build Image with Packer') {
      steps {
        sh '''
        packer init .
        packer build \
          -var "client_id=$ARM_CLIENT_ID" \
          -var "client_secret=$ARM_CLIENT_SECRET" \
          -var "subscription_id=$ARM_SUBSCRIPTION_ID" \
          -var "tenant_id=$ARM_TENANT_ID" \
          packer.json
        '''
      }
    }
  }
}
