# CSE All Hands - May 2020

This repository contains material that will be covered during the May 2020 CSE All Hands sessions

## Devcontainers

@Erik to fill out

## Terraform provider for Azure DevOps

The [Terraform provider for Azure DevOps](https://github.com/microsoft/terraform-provider-azuredevops) allows you to create and manage Azure DevOps resources through [Terraform](https://www.terraform.io/). The code included in this repository will showcase a subset of the features for this provider.

*Note:*. The Terraform Provider for Azure DevOps is not yet released to HashiCorp's official registry. Until it is, you will need to manually install it by following [the instructions](https://github.com/microsoft/terraform-provider-azuredevops/blob/master/docs/contributing.md#3-build--install-provider)

### Resources Provisioned

| Resource | Description | Backend | File |
| ---      | ---         | ---     | ---  |
| Project | A project that holds all other resources provisioned in AzDO | Azure DevOps | `tf-code/azdo.tf` |
| User | A user from AAD who is invited to the AzDO Project | Azure DevOps | `tf-code/azdo.tf` |
| Group | A group in AzDO | Azure DevOps | `tf-code/azdo.tf` |
| Group Memberships | Memberships for the created group | Azure DevOps | `tf-code/azdo.tf` |
| `Vars - Common` | A variable group used in all deployment stages | Azure DevOps | `tf-code/azdo.tf` |
| `Vars - $STAGE` | A variable group used in a specific stage. Default stages are `dev`, `qa` and `prod` | Azure DevOps | `tf-code/azdo.tf` |
| `Secrets - $STAGE` | Like `Vars - $STAGE`, but these are secrets | Azure DevOps | `tf-code/azdo.tf` |
| Git Repository | A repository | Azure DevOps | `tf-code/azdo.tf` |
| Build Definition | A build/release pipeline | Azure DevOps | `tf-code/azdo.tf` |
| Service Connection | Enables authentication with azure | Azure DevOps | `tf-code/azdo.tf` |
| Service Connection Authorization | Authorizes pipeline to use a Service Connection | Azure DevOps | `tf-code/azdo.tf` |
| AAD Application | Needed to provision service principal | Azure Active Directory | `tf-code/azure.tf` |
| Service Principal | Used by pipeline | Azure Active Directory | `tf-code/azure.tf` |
| Role Assignment | Grants permissions to Service Principal | AzureRM | `tf-code/azure.tf` |


### Deploy Resources

```bash
# 1. Source environment variables
. .envrc

# 2. Initialize Terraform
terraform init tf-code/

# 3. Deploy Resources
terraform apply -auto-approve tf-code/
```

### Push some code

```bash
# 1. Get repo clone URL
REPO_CLONE_URL=$(terraform output -json | jq -r '.repo_clone_url.value')

# 2. Clone repo using AzDO PAT
git clone $(echo $REPO_CLONE_URL | sed "s/https:\/\//https:\/\/$AZDO_PERSONAL_ACCESS_TOKEN@/g") .tmp/

# 3. Add AzDO Pipelines to Repo
mkdir .tmp/
cp pipeline-code/*.yml .tmp/
(
    cd .tmp/                                   && \
    git add -A                                 && \
    git commit -m"Adding azure pipeline files" && \
    git push
)

# 4. Remove local repo directory
rm -rf .tmp/
```

### Run Pipeline

Navigate to your newly created project in Azure DevOps and run your pipeline. You should see that the pipeline runs without issues


### Cleaning Up

> Note: This is a destructive action! Only do it if you are sure you want to destroy your environment
```bash
# 1. Destroy all provisioned resources
terraform destroy tf-code/
```