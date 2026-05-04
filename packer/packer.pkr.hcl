packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 1.0.0"
    }
  }
}

variable "image_version" {
  type = string
}

source "azure-arm" "php-image" {
  use_azure_cli_auth = true

  subscription_id = "a9cafd12-1202-4c01-9841-5cf127a697fa"
  build_resource_group_name = "rg-images-uat"

  #  INPUT (Golden Image)
  shared_image_gallery {
    subscription   = "a9cafd12-1202-4c01-9841-5cf127a697fa"
    resource_group = "rg-images-uat"
    gallery_name   = "uatsafegoldgallary"
    image_name     = "uat-golden-image-partner"
    image_version  = "0.0.1"
  }

  #  OUTPUT (New version)
  shared_image_gallery_destination {
    subscription   = "a9cafd12-1202-4c01-9841-5cf127a697fa"
    resource_group = "rg-images-uat"
    gallery_name   = "uatsafegoldgallary"
    image_name     = "uat-golden-image-partner"
    image_version  = var.image_version
  }

  security_type = "TrustedLaunch"

  vm_size = "Standard_D2s_v3"
  os_type = "Linux"

  azure_tags = {
    environment = "uat"
  }
}

build {
  sources = ["source.azure-arm.php-image"]

  provisioner "shell" {
    inline = [
      "sudo rm -rf /var/www/html/*"
    ]
  }

  provisioner "file" {
    source      = "app.zip"
    destination = "/tmp/app.zip"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y || true",
      "sudo apt-get install -y unzip || true",
      "sudo unzip /tmp/app.zip -d /var/www/html",
      "sudo chown -R www-data:www-data /var/www/html",
      "sudo systemctl restart nignx"
    ]
  }
}
