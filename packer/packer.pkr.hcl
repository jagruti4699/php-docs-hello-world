packer {
  required_plugins {
    azure = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

source "azure-arm" "php-image" {
  use_azure_cli_auth = true

  subscription_id = "a9cafd12-1202-4c01-9841-5cf127a697fa"

  managed_image_resource_group_name = "rg-images"
  build_resource_group_name         = "rg-images"

  managed_image_name = "php-image-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  vm_size = "Standard_D2s_v3"

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"

  azure_tags = {
    environment = "uat"
  }
}

build {
  sources = ["source.azure-arm.php-image"]

  # Install dependencies (FIXED)
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y || (sleep 10 && sudo apt-get update -y)",
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository universe",
      "sudo apt-get update -y",
      "sudo apt-get install -y apache2 php php-mysql unzip || (sleep 10 && sudo apt-get install -y apache2 php php-mysql unzip)",
      "sudo rm -rf /var/www/html/*"
    ]
  }

  # Copy app from Jenkins
  provisioner "file" {
    source      = "app.zip"
    destination = "/tmp/app.zip"
  }

  # Deploy app
  provisioner "shell" {
    inline = [
      "sudo unzip /tmp/app.zip -d /var/www/html",
      "sudo chown -R www-data:www-data /var/www/html",
      "sudo systemctl enable apache2"
    ]
  }
}
