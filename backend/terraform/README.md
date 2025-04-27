## Terraform Setup:
### On first usage:

1. Create a new project in Google Cloud Platform
2. Authorize the Google Cloud SDK
```bash
gcloud auth login
```
(on machines without a browser the `--no-browser` flag can be used)
2. Select the project in the Google Cloud SDK
```bash
gcloud config set project <project-id>
```

3. Create a new service account and download the key file using [create-gcloud-credentials.sh](../scripts/create-gcloud-credentials.sh) (ensure you have the necessary permissions on the google cloud)

4. Tweak the terraform [variables.tf](backend/terraform/variables.tf) file to match your project id and service account key file path

5. Prepare terraform for migrating the backend to google cloud.
   1. disable the "gcs" backend in the [terraform_backend.tf](terraform_backend.tf) file (comment it out)
   2. run `terraform init`, then `terraform apply` once
   3. Restore the gcs backend (uncomment it)
5. Create a Google Cloud Bucket for the terraform state
```bash
./migrate_backend_to_gcloud.sh
```

6. Deploy the infrastructure using terraform:
```bash
tf.sh init
tf.sh apply
```
From now on use tf.sh as a wrapper for terraform commands. It will automatically use proper credentials without the need to set the environment variables.

### On
