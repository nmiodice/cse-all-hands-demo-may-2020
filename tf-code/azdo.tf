# Make sure to set the following environment variables:
#   AZDO_PERSONAL_ACCESS_TOKEN
#   AZDO_ORG_SERVICE_URL
provider "azuredevops" {
  version = ">= 0.0.1"
}

##
# Project & Group Management
##
resource "azuredevops_project" "p" {
  project_name = format("%s-project", var.prefix)
}

data "azuredevops_group" "readers" {
  project_id = azuredevops_project.p.id
  name = "Readers"
}

data "azuredevops_group" "contributors" {
  project_id = azuredevops_project.p.id
  name = "Contributors"
}

resource "azuredevops_user_entitlement" "user" {
    principal_name     = var.user_to_invite
}

resource "azuredevops_group" "group" {
  scope        = azuredevops_project.p.id
  display_name = "Example Group"
  description  = "Managed by Terraform"

  members = [
      azuredevops_user_entitlement.user.descriptor,
      data.azuredevops_group.readers.descriptor,
      data.azuredevops_group.contributors.descriptor
  ]
}



##
# Variables
##
resource "azuredevops_variable_group" "vars_shared" {
  project_id   = azuredevops_project.p.id
  name         = "Vars - Common"
  description  = "Managed by Terraform"
  allow_access = true

  variable {
    name  = "VAR_A"
    value = "This variable is managed by Terraform!"
  }

  variable {
    name  = "VAR_B"
    value = "So is this one!"
  }

  variable {
    name  = "SERVICE_CONNECTION_NAME"
    value = azuredevops_serviceendpoint_azurerm.endpointazure.service_endpoint_name
  }

}

resource "azuredevops_variable_group" "vars_stage" {
  project_id   = azuredevops_project.p.id
  count        = length(var.environments)
  name         = format("Vars - %s", var.environments[count.index])
  description  = "Managed by Terraform"
  allow_access = true

  variable {
    name  = "STAGE"
    value = var.environments[count.index]
  }

}

resource "azuredevops_variable_group" "vars_stage_secret" {
  project_id   = azuredevops_project.p.id
  count        = length(var.environments)
  name         = format("Secrets - %s", var.environments[count.index])
  description  = "Managed by Terraform"
  allow_access = true

  variable {
    name      = "STAGE_SECRET"
    value     = format("Secret value for %s - %s", var.environments[count.index], strrev(var.environments[count.index]))
    is_secret = true
  }

}

##
# Repository
##
resource "azuredevops_git_repository" "repo" {
  project_id = azuredevops_project.p.id
  name       = "App Repository"
  initialization {
    init_type = "Clean"
  }
}


##
# Build
##
resource "azuredevops_build_definition" "build" {
  project_id = azuredevops_project.p.id
  name       = "App Deployment Pipeline"

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.repo.id
    repo_name   = azuredevops_git_repository.repo.name
    branch_name = azuredevops_git_repository.repo.default_branch
    yml_path    = "azure-pipeline.yml"
  }

  variable_groups = concat(
    [azuredevops_variable_group.vars_shared.id],
    azuredevops_variable_group.vars_stage.*.id,
    azuredevops_variable_group.vars_stage_secret.*.id
  )
}

##
# Service Connection
##

resource "azuredevops_serviceendpoint_azurerm" "endpointazure" {
  project_id            = azuredevops_project.p.id
  service_endpoint_name = "Deployment Service Connection"
  credentials {
    serviceprincipalid  = azuread_service_principal.sp.application_id
    serviceprincipalkey = random_string.random.result
  }
  azurerm_spn_tenantid      = data.azurerm_subscription.sub.tenant_id
  azurerm_subscription_id   = data.azurerm_subscription.sub.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.sub.display_name
}

resource "azuredevops_resource_authorization" "auth" {
  project_id  = azuredevops_project.p.id
  resource_id = azuredevops_serviceendpoint_azurerm.endpointazure.id
  authorized  = true
}
