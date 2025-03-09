provider "digitalocean" {
  token = var.token
}

resource "digitalocean_droplet" "example" {
  name     = "github-actions-droplet"
  region   = "nyc3"
  size     = "s-1vcpu-512mb-10gb"
  image    = "ubuntu-22-04-x64"
  ssh_keys = [var.ssh_fingerprint]
  backups = false
  monitoring = false
}

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_fingerprint" {
  description = "SSH Key Fingerprint"
  type        = string
}
