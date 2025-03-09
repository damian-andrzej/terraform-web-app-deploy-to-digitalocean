steps to do 

make folder for workflows and create terraform.yml
check if works.

```yaml
name: Terraform Apply

on:
  push:
    branches:
      - main  # Trigger on push to the main branch

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      # Checkout the code
      - name: Checkout code
        uses: actions/checkout@v3

      # Set up Terraform
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v1

      # Cache Terraform providers
      - name: Cache Terraform providers
        uses: actions/cache@v2
        with:
          path: ~/.terraform.d/plugin-cache
          key: ${{ runner.os }}-terraform-${{ hashFiles('**/*.tf') }}
          restore-keys: |
            ${{ runner.os }}-terraform-

      # Initialize Terraform
      - name: Terraform Init
        run: terraform init

      # Run Terraform plan (optional)
      - name: Terraform Plan
        run: terraform plan

      # Run Terraform apply
      - name: Terraform Apply
        run: terraform apply -auto-approve
        env:
          # Reference GitHub secret containing SSH fingerprint
          SSH: ${{ secrets.SSH}}
          DIGITALOCEAN_TOKEN: ${{ secrets.TOKEN }}
```
