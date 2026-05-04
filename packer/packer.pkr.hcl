packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 1.0.0"
    }
  }
}

#  SOURCE: using your SIG golden image
source "azure-arm" "php-image" {
  use_azure_cli_auth = true

  subscription_id = "a9cafd12-1202-4c01-9841-5cf127a697fa"
  build_resource_group_name = "rg-images-uat"

  shared_image_gallery {
    subscription   = "a9cafd12-1202-4c01-9841-5cf127a697fa"
    resource_group = "rg-images-uat"
    gallery_name   = "uatsafegoldgallary"
    image_name     = "uat-golden-image-partner"
    image_version  = "0.0.1"
  }

  managed_image_name                = "php-image-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  managed_image_resource_group_name = "rg-images-uat"

  location = "UAE North"
  vm_size  = "Standard_D2s_v3"
  os_type  = "Linux"

  azure_tags = {
    environment = "uat"
  }
}

#  BUILD: this is where your app is copied
build {
  sources = ["source.azure-arm.php-image"]

  # Clean old files (optional)
  provisioner "shell" {
    inline = [
      "sudo rm -rf /var/www/html/*"
    ]
  }

  #  COPY your app.zip from Jenkins workspace
  provisioner "file" {
    source      = "app.zip"
    destination = "/tmp/app.zip"
  }

  #  Deploy your PHP app
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y || true",   # safety (optional)
      "sudo apt-get install -y unzip || true",

      "sudo unzip /tmp/app.zip -d /var/www/html",
      "sudo chown -R www-data:www-data /var/www/html",

      "sudo systemctl restart apache2"
    ]
  }
}
