packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 1.0.0"
    }
  }
}

#  SOURCE (Golden Image from SIG)
source "azure-arm" "php-image" {
  use_azure_cli_auth = true

  subscription_id = "a9cafd12-1202-4c01-9841-5cf127a697fa"

  # Use existing RG
  build_resource_group_name = "rg-images-uat"

  #  INPUT IMAGE (Golden)
  shared_image_gallery {
    subscription   = "a9cafd12-1202-4c01-9841-5cf127a697fa"
    resource_group = "rg-images-uat"
    gallery_name   = "uatsafegoldgallary"
    image_name     = "uat-golden-image-partner"
    image_version  = "0.0.1"
  }

  #  OUTPUT IMAGE (NEW VERSION — AUTO GENERATED)
  shared_image_gallery_destination {
    subscription   = "a9cafd12-1202-4c01-9841-5cf127a697fa"
    resource_group = "rg-images-uat"
    gallery_name   = "uatsafegoldgallary"
    image_name     = "uat-golden-image-partner"

    #  Dynamic version (NO manual change needed)
    image_version  = formatdate("YYYY.MM.DD.hhmmss", timestamp())
  }

  # Required for your golden image
  security_type = "TrustedLaunch"

  vm_size = "Standard_D2s_v3"
  os_type = "Linux"

  azure_tags = {
    environment = "uat"
  }
}

#  BUILD (App deployment happens here)
build {
  sources = ["source.azure-arm.php-image"]

  # Clean existing web folder
  provisioner "shell" {
    inline = [
      "sudo rm -rf /var/www/html/*"
    ]
  }

  # Copy app.zip from Jenkins workspace
  provisioner "file" {
    source      = "app.zip"
    destination = "/tmp/app.zip"
  }

  # Deploy PHP app
  provisioner "shell" {
    inline = [
      # Safety (if unzip missing)
      "sudo apt-get update -y || true",
      "sudo apt-get install -y unzip || true",

      "sudo unzip /tmp/app.zip -d /var/www/html",
      "sudo chown -R www-data:www-data /var/www/html",

      "sudo systemctl restart apache2"
    ]
  }
}
