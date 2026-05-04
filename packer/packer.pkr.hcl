packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 1.0.0"
    }
  }
}

source "azure-arm" "php-image" {
  use_azure_cli_auth = true

  subscription_id = "a9cafd12-1202-4c01-9841-5cf127a697fa"

  build_resource_group_name = "rg-images-uat"

  #  USING YOUR SIG GOLDEN IMAGE
  source_image_id = "/subscriptions/a9cafd12-1202-4c01-9841-5cf127a697fa/resourceGroups/rg-images-uat/providers/Microsoft.Compute/galleries/uatsafegoldgallary/images/uat-golden-image-partner/versions/0.0.1"

  managed_image_name                = "php-image-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  managed_image_resource_group_name = "rg-images-uat"

  location = "UAE North"
  vm_size  = "Standard_D2s_v3"

  os_type = "Linux"

  azure_tags = {
    environment = "uat"
  }
}

build {
  sources = ["source.azure-arm.php-image"]

  # Clean default web folder
  provisioner "shell" {
    inline = [
      "sudo rm -rf /var/www/html/*"
    ]
  }

  # Copy your PHP app
  provisioner "file" {
    source      = "app.zip"
    destination = "/tmp/app.zip"
  }

  # Deploy app
  provisioner "shell" {
    inline = [
      "sudo unzip /tmp/app.zip -d /var/www/html",
      "sudo chown -R www-data:www-data /var/www/html",
      "sudo systemctl restart apache2"
    ]
  }
}
