pipeline {
  agent any

  environment {
    IMAGE_RG = 'rg-images-uat'
    VMSS_RG  = 'uat-uae-rg'
    VMSS_NAME = 'demo-2-php'
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
        packer build packer/packer.pkr.hcl
        '''
      }
    }

    stage('Get Latest Image') {
      steps {
        script {
          env.IMAGE_ID = sh(
            script: '''
              az image list \
                --resource-group $IMAGE_RG \
                --query "sort_by(@,&name)[-1].id" \
                -o tsv
            ''',
            returnStdout: true
          ).trim()

          echo "Latest Image ID: ${env.IMAGE_ID}"
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

    // UPDATED STAGE (Sequential rollout)
    stage('Sequential VMSS Instance Update') {
      steps {
        sh '''
        set -e

        echo "Fetching VMSS instance IDs..."

        IDS=$(az vmss list-instances \
          --resource-group $VMSS_RG \
          --name $VMSS_NAME \
          --query "[].instanceId" \
          -o tsv)

        echo "Instance IDs: $IDS"

        for ID in $IDS
        do
          echo "======================================"
          echo "Updating instance: $ID"
          echo "======================================"

          az vmss update-instances \
            --resource-group $VMSS_RG \
            --name $VMSS_NAME \
            --instance-ids $ID

          echo "Waiting for instance $ID to stabilize..."
          sleep 20
        done

        echo "All instances updated successfully"
        '''
      }
    }
  }
}
