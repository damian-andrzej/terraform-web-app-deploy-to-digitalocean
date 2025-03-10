terraform {
  backend "s3" {
    bucket                      = "s3-backend"               # Name of your DigitalOcean Space (S3 bucket)
    key                         = "terraform.tfstate"        # Path where Terraform state will be stored
    region                      = "fra1"                     # DigitalOcean region
    endpoint                    = "https://s3-backend.fra1.digitaloceanspaces.com"  # Endpoint URL for DigitalOcean Spaces
    access_key                  = var.s3_access_key_id          # Access key from your GitHub Secrets
    secret_key                  = var.s3_secret_key_secret           # Secret key from your GitHub Secrets
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

provider "digitalocean" {
  token = var.token
}

resource "digitalocean_droplet" "example" {
  name     = "github-actions-droplet"
  region   = "nyc3"
  size     = "s-1vcpu-512mb-10gb"
  image    = "ubuntu-22-04-x64"
  ssh_keys = [var.ssh]
  backups = false
  monitoring = false
}

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh" {
  description = "SSH Key Fingerprint"
  type        = string
}
