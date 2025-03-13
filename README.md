
# Automation of app deployment to the cloud 



## Table of Contents

- [Project Title](#project-title)
- [Description](#description)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Backend setup](#Backendsetup)
- [Terraform](#Terraform)
- [Ansible](#ansible)
- [Acknowledgments](#acknowledgments)

## Description

The purpose of this repo is to deploy python web application to digital ocean droplet by terraform, then set appropriate config to machine by ansible.

## Prerequisites

List the tools, dependencies, and software needed to run your project. Be specific about versions if necessary.

- **Cloud account** (for example DO or AWS)
- **Github account** 


## Installation

Follow these steps to get the development environment running on your local machine.

1. **Create workflow folder**:

   To run github pipelines its mandatory to have .github/workflows directory. Otherwise it wont run. You can copy structure of dirs from my project

2. **Credentials**

   To connect with Cloud provider and your Virtual machnine you gonna create its neccessary to have adequate credentials:

   - ACCESS_KEY_ID  Its you S3 credential to configure backend. Its specific for each cloud provided, always stored in bucket settings
   - ACCESS_KEY_SECRET Same as above just its a secret part of credentials not only ID
   - SSH This credential is used to access a host(VM) For AWS its ssh_key, for DigitalOcean its ssh_fingerpring
   - SSH_PRIVATE_KEY authorization pass for our ansible host that will propagate config
   - TOKEN its extra security layer from Digital Ocean, verifing access to account by external resources
   - 
   image : reposecret.png


## Backend setup

Backend is an online Digital Ocean place to store state of terraform config that we want to propagate
To configure it we need to hustle a bit
Terraform libraries for Digital Ocean storage are compatible with AWS S3 but there are some tricks:

- we need to explicitly specific provider

```hcl
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"  # You can specify the version you need
    }
}
```

- we declare it just like s3 bucket but its not, so region need to be selected
- terraform lib need to validate us by user id, we need to omit it by those parameters
  
```hcl
    region="us-east-1"                     # fake AWS reference
    skip_credentials_validation= true
    skip_requesting_account_id = true
    skip_metadata_api_check= true

```

- we are obligated to use AWS S3 bucket variables names in INIT process(terraform.yaml)

```yaml
- name: Initialize Terraform
        env:
         AWS_ACCESS_KEY_ID: ${{ secrets.ACCESS_KEY_ID }}
         AWS_SECRET_ACCESS_KEY: ${{ secrets.ACCESS_KEY_SECRET }}
        run: |
          terraform init \
            -backend-config="access_key=$AWS_ACCESS_KEY_ID" \
            -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY"

      - name: validate terraform
        env:
          TF_VAR_ssh_fingerprint: ${{ secrets.SSH }}
        run: terraform validate
        working-directory: ./

      - name: Plan terraform
        env:
          TF_VAR_do_token: ${{ secrets.TOKEN }}
          TF_VAR_ssh_fingerprint: ${{ secrets.SSH }}
          AWS_ACCESS_KEY_ID: ${{ secrets.ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.ACCESS_KEY_SECRET }}
```

## Terraform

Here we setup ansible connection to our droplet, there we use SSH_PRIVATE secret to connect

```hcl
 ansible:
    runs-on: ubuntu-latest
    needs: terraform  # Ensure the droplet is provisioned before running Ansibl

    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    # Set up Ansible
    - name: Set up Ansible
      run: |
        sudo apt update
        sudo apt install -y ansible

    # Set up SSH keys
    - name: Set up SSH private key
      run: |
        mkdir -p ~/.ssh
        echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
        chmod 600 ~/.ssh/id_rsa

    - name: Add droplet SSH key to known_hosts
      run: |
        mkdir -p ~/.ssh
        ssh-keyscan -H ${{ secrets.DROPLET_IP }} >> ~/.ssh/known_hosts
        chmod 644 ~/.ssh/known_hosts
```


Here we have machine config that is enought for our app, but in most cases 1GB of RAM is better option

```hcl
resource "digitalocean_droplet" "example" {
  name= "github-actions-droplet"
  region= "fra1"
  size= "s-1vcpu-512mb-10gb"
  image= "ubuntu-22-04-x64"
  ssh_keys= [var.ssh_fingerprint]
  backups = false
  monitoring = false
}
```

Last step is to run the playbook, I prefer to use IP address directly as its optimal for github runner. Last part of the command is a reference to our config playbook

```hcl
# Run Ansible Playbook on the new droplet
    - name: Run Ansible Playbook
      run: |
        ansible-playbook -i "${{ secrets.DROPLET_IP }}," --private-key ~/.ssh/id_rsa --user root ansible/application-config.yml
```

## Ansible

Playbook we prepared sets up a DigitalOcean droplet with Docker and Docker Compose for deploying a web application. The playbook begins by updating the system packages and installing required dependencies, such as curl, git, docker-ce, and docker-compose-plugin. It then ensures the necessary Docker GPG key is present and adds the Docker repository to the system. Docker and Docker Compose are installed, and the Docker service is started and enabled to run at boot.

Next, the playbook ensures the directory for the application exists and checks if the specified Git repository is already cloned. If not, it clones the repository, otherwise, it pulls the latest changes. Additionally, an environment file containing database credentials is created in the app's directory. Finally, the playbook uses docker-compose to start the containers in detached mode. Handlers are also defined to update the apt cache when necessary. The playbook automates the setup and deployment of the application with Docker on a DigitalOcean droplet.

The file is accessible under ansible/application-config.yml

WHAT to do 

edit a postgres container to enable web and db container to communicatate
Propage below config: 

pg_hba.conf: Ensure it's configured to allow TCP/IP connections:


host    all             all             0.0.0.0/0               trust
host    all             all             ::/0                    md5
