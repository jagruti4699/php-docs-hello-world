pipeline {
  agent any

  environment {
    IMAGE_RG = 'rg-images-uat'
    VMSS_RG  = 'uat-uae-rg'
    VMSS_NAME = 'demo-2-php'

    GALLERY_NAME = 'uatsafegoldgallary'
    IMAGE_NAME   = 'uat-golden-image-partner'
  }

  stages {

    stage('Azure Login using Managed Identity') {
      steps {
        sh '''
        az login --identity
        az account show
        '''
      }
    }

    stage('Generate Image Version') {
      steps {
        script {
          env.IMAGE_VERSION = sh(
            script: "date +1.0.%Y%m%d%H%M%S",
            returnStdout: true
          ).trim()

          echo "Generated Image Version: ${env.IMAGE_VERSION}"
        }
      }
    }

    stage('Prepare App') {
      steps {
        sh '''
        zip -r app.zip . -x "*.git*"
        '''
      }
    }

    stage('Build Image with Packer') {
      steps {
        sh '''
        packer init packer/packer.pkr.hcl
        packer validate packer/packer.pkr.hcl

        packer build \
          -var "image_version=$IMAGE_VERSION" \
          packer/packer.pkr.hcl
        '''
      }
    }

    stage('Get Latest SIG Image Version') {
      steps {
        script {
          env.IMAGE_ID = sh(
            script: '''
              az sig image-version list \
                --resource-group $IMAGE_RG \
                --gallery-name $GALLERY_NAME \
                --gallery-image-definition $IMAGE_NAME \
                --query "sort_by(@,&name)[-1].id" \
                -o tsv
            ''',
            returnStdout: true
          ).trim()

          echo "Latest SIG Image ID: ${env.IMAGE_ID}"
        }
      }
    }

    stage('Update VMSS Model') {
      steps {
        sh '''
        az vmss update \
          --resource-group $VMSS_RG \
          --name $VMSS_NAME \
          --set virtualMachineProfile.storageProfile.imageReference.id=$IMAGE_ID
        '''
      }
    }

    stage('Sequential VMSS Instance Update') {
      steps {
        sh '''
        set -e

        IDS=$(az vmss list-instances \
          --resource-group $VMSS_RG \
          --name $VMSS_NAME \
          --query "[].instanceId" \
          -o tsv)

        for ID in $IDS
        do
          echo "Updating instance: $ID"

          az vmss update-instances \
            --resource-group $VMSS_RG \
            --name $VMSS_NAME \
            --instance-ids $ID

          sleep 20
        done
        '''
      }
    }
  }
}
