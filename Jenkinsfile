pipeline {
    agent any

    environment {
        // --- Azure Resource Details ---
        SUBSCRIPTION  = 'a9cafd12-1202-4c01-9841-5cf127a697fa'
        VMSS_RG       = 'uat-uae-rg'
        VMSS_NAME     = 'uat-api-vmss'
        
        // --- Storage Details ---
        STORAGE_ACC   = 'uatsafegold' 
        CONTAINER     = 'uat-api-code' 
    }

    stages {
        stage('Azure Login') {
            steps {
                sh "az login --identity"
                sh "az account set --subscription ${env.SUBSCRIPTION}"
            }
        }

        stage('Create Deployment Container') {
            steps {
                // Checks if container exists, creates it if not. auth-mode login uses your Managed Identity permissions.
                sh "az storage container create --account-name ${env.STORAGE_ACC} --name ${env.CONTAINER} --auth-mode login || true"
            }
        }

        stage('Package & Upload Code') {
            steps {
                script {
                    // 1. Zip the current workspace code, excluding infrastructure and git files
                    sh 'zip -r app.zip . -x "*.git*" "packer/*" "Jenkinsfile"'
                    
                    // 2. Upload to the storage account (Requires Storage Blob Data Contributor role)
                    sh "az storage blob upload --account-name ${env.STORAGE_ACC} --container-name ${env.CONTAINER} --file app.zip --name app.zip --overwrite --auth-mode login"
                    
                    // 3. Generate a temporary 1-hour secure SAS link for the VMs to download the zip
                    env.DEPLOY_URL = sh(
                        script: "az storage blob generate-sas --account-name ${env.STORAGE_ACC} --container-name ${env.CONTAINER} --name app.zip --permissions r --expiry `date -u -d '1 hour' +%Y-%m-%dT%H:%MZ` --full-uri -o tsv", 
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Set VMSS Extension') {
            steps {
                echo "Updating VMSS Extension Model with new code URL..."
                
                // This updates the 'Model'. New instances will automatically use these settings.
                sh """
                az vmss extension set \
                  --publisher Microsoft.Azure.Extensions \
                  --version 2.0 \
                  --name CustomScript \
                  --resource-group ${env.VMSS_RG} \
                  --vmss-name ${env.VMSS_NAME} \
                  --settings '{"fileUris": ["${env.DEPLOY_URL}"], "commandToExecute": "sudo unzip -o app.zip -d /var/www/html && sudo chown -R www-data:www-data /var/www/html && sudo systemctl restart nginx"}'
                """
            }
        }

        stage('Rolling One-by-One Update') {
            steps {
                echo "Starting sequential update to ensure zero downtime..."
                sh """
                # Get the list of all active instance IDs
                INSTANCE_IDS=\$(az vmss list-instances \
                    --resource-group ${env.VMSS_RG} \
                    --name ${env.VMSS_NAME} \
                    --query "[].instanceId" -o tsv)

                for ID in \$INSTANCE_IDS; do
                    echo "------------------------------------------------"
                    echo "Processing Instance: \$ID"
                    echo "------------------------------------------------"
                    
                    # Trigger the update on the specific instance
                    az vmss update-instances \
                        --resource-group ${env.VMSS_RG} \
                        --name ${env.VMSS_NAME} \
                        --instance-ids \$ID

                    echo "Instance \$ID updated. Waiting 30s for health probes to stabilize..."
                    sleep 30
                done
                
                echo "Deployment successfully rolled out to all instances."
                """
            }
        }
    }
    
    post {
        always {
            // Workspace cleanup
            sh 'rm -f app.zip'
        }
        success {
            echo "Deployment to ${env.VMSS_NAME} completed successfully."
        }
        failure {
            echo "Deployment failed. Please check the 'Package & Upload' permissions or VMSS status."
        }
    }
}
