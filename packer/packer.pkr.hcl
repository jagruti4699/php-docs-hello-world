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

  managed_image_resource_group_name = "rg-images-uat"
  managed_image_name                = "php-image-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  location  = "UAE North"
  vm_size   = "Standard_D2als_v6"

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

  provisioner "shell" {
    inline = [
      "sudo apt update",
      "sudo apt install -y apache2 php php-mysql unzip",
      "sudo rm -rf /var/www/html/*"
    ]
  }

  provisioner "file" {
    source      = "app.zip"
    destination = "/tmp/app.zip"
  }

  provisioner "shell" {
    inline = [
      "sudo unzip /tmp/app.zip -d /var/www/html",
      "sudo chown -R www-data:www-data /var/www/html",
      "sudo systemctl enable apache2"
    ]
  }
}
