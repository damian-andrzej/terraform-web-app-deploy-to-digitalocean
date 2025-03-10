terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"  # You can specify the version you need
    }
}

terraform {
  backend "s3" {
    bucket = "s3-backend"               # Name of your DigitalOcean Space (S3 bucket)
    key= "terraform.tfstate"        # Path where Terraform state will be stored
    region="us-east-1"                     # DigitalOcean region
    endpoint= "https://fra1.digitaloceanspaces.com"  # Endpoint URL for DigitalOcean Spaces

    skip_credentials_validation= true
    skip_requesting_account_id = true
    skip_metadata_api_check= true
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "example" {
  name= "github-actions-droplet"
  region= "fra1"
  size= "s-1vcpu-512mb-10gb"
  image= "ubuntu-22-04-x64"
  ssh_keys= [var.TF_VAR_ssh_fingerprint]
  backups = false
  monitoring = false
}

variable "do_token" {
  description = "DigitalOcean API token"
  type= string
  sensitive = true
}

variable "ssh" {
  description = "SSH Key Fingerprint"
  type = string
}
