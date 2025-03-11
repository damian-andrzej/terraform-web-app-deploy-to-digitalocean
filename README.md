The purpose of this repo is to deploy python web application to digital ocean droplet by terraform, then set appropriate config to machine by ansible.



### Backend setup

To configure online Digital Ocean place to store state for terraform file we need to hustle a bit
Terraform libs are compatible with AWS S3 but there are some tricks:
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

