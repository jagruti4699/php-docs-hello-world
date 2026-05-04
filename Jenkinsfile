pipeline {
    agent any

    environment {
        IMAGE_RG     = 'rg-images-uat'
        VMSS_RG      = 'uat-uae-rg'
        VMSS_NAME    = 'demo-2-php'
        GALLERY_NAME = 'uatsafegoldgallary'
        IMAGE_NAME   = 'uat-golden-image-partner'
    }

    stages {
        stage('Azure Login') {
            steps {
                // Ensure Managed Identity has 'Contributor' on the RG and 'User Access Administrator' or 'Owner' if needed
                sh '''
                az login --identity
                az account set --subscription a9cafd12-1202-4c01-9841-5cf127a697fa
                '''
            }
        }

        stage('Generate Image Version') {
            steps {
                script {
                    // Using Build Number ensures we never exceed Azure's Version Integer Limit
                    env.IMAGE_VERSION = "1.0.${BUILD_NUMBER}"
                    echo "Generated Image Version: ${env.IMAGE_VERSION}"
                }
            }
        }

        stage('Prepare App') {
            steps {
                sh 'zip -r app.zip . -x "*.git*"'
            }
        }

        stage('Build Image with Packer') {
            steps {
                sh '''
                packer init packer/packer.pkr.hcl
                packer validate -var "image_version=$IMAGE_VERSION" packer/packer.pkr.hcl
                packer build -var "image_version=$IMAGE_VERSION" packer/packer.pkr.hcl
                '''
            }
        }

        stage('Update VMSS Model') {
            steps {
                script {
                    // Fetch the ID of the version we JUST created
                    env.IMAGE_ID = sh(
                        script: '''
                            az sig image-version show \
                            --resource-group $IMAGE_RG \
                            --gallery-name $GALLERY_NAME \
                            --gallery-image-definition $IMAGE_NAME \
                            --gallery-image-version $IMAGE_VERSION \
                            --query "id" -o tsv
                        ''',
                        returnStdout: true
                    ).trim()
                }
                sh '''
                az vmss update \
                  --resource-group $VMSS_RG \
                  --name $VMSS_NAME \
                  --set virtualMachineProfile.storageProfile.imageReference.id=$IMAGE_ID
                '''
            }
        }

        stage('Rolling VMSS Instance Update') {
            steps {
                sh '''
                set -e
                IDS=$(az vmss list-instances --resource-group $VMSS_RG --name $VMSS_NAME --query "[].instanceId" -o tsv)

                for ID in $IDS
                do
                  echo "Updating instance: $ID"
                  az vmss update-instances --resource-group $VMSS_RG --name $VMSS_NAME --instance-ids $ID
                  sleep 15
                done
                '''
            }
        }
    }
}
