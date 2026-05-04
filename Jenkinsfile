pipeline {
    agent any

    environment {
        // --- Azure Resource Details ---
        SUBSCRIPTION  = 'a9cafd12-1202-4c01-9841-5cf127a697fa'
        VMSS_RG       = 'uat-uae-rg'
        VMSS_NAME     = 'uat-partner-vmss'
        
        // --- Storage Details ---
        STORAGE_ACC   = 'safegoldpoc' 
        CONTAINER     = 'deployments' // Make sure this container exists in your storage account
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
                // Ensures the container exists; skips if it already does
                sh "az storage container create --account-name ${env.STORAGE_ACC} --name ${env.CONTAINER} --auth-mode login || true"
            }
        }

        stage('Package & Upload Code') {
            steps {
                script {
                    // 1. Zip the current workspace code
                    sh 'zip -r app.zip . -x "*.git*" "packer/*" "Jenkinsfile"'
                    
                    // 2. Upload to the safegoldpoc storage account
                    sh "az storage blob upload --account-name ${env.STORAGE_ACC} --container-name ${env.CONTAINER} --file app.zip --name app.zip --overwrite --auth-mode login"
                    
                    // 3. Generate a 1-hour secure link (SAS) so the VM can download the zip
                    env.DEPLOY_URL = sh(
                        script: "az storage blob generate-sas --account-name ${env.STORAGE_ACC} --container-name ${env.CONTAINER} --name app.zip --permissions r --expiry `date -u -d '1 hour' +%Y-%m-%dT%H:%MZ` --full-uri -o tsv", 
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Deploy to VMSS') {
            steps {
                echo "Updating VMSS Extension to pull new code..."
                
                // We use the CustomScript extension to unzip the code into the web root
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

        stage('Rolling Refresh') {
            steps {
                echo "Applying changes to all active instances..."
                // This forces every running VM to run the script immediately
                sh "az vmss update-instances --resource-group ${env.VMSS_RG} --name ${env.VMSS_NAME} --instance-ids '*'"
            }
        }
    }
    
    post {
        always {
            // Clean up the workspace zip file
            sh 'rm -f app.zip'
        }
    }
}
