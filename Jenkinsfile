pipeline {
  agent any

  stages {

    stage('Azure Login using Managed Identity') {
      steps {
        sh '''
        az login --identity
        az account show
        '''
      }
    }

    stage('Prepare App') {
      steps {
        sh '''
        zip -r app.zip .
        '''
      }
    }

    stage('Build Image with Packer') {
      steps {
        sh '''
        
        packer build packer.json
        '''
      }
    }
  }
}
