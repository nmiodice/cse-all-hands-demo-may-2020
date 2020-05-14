provider "azuread" {
  version = 0.8
}
provider "random" {
  version = 2.2
}
provider "azurerm" {
  version = "=2.0.0"
  features {}
}

data "azurerm_subscription" "sub" {
}

resource "azuread_application" "app" {
  name = format("%s-deploy-app", var.prefix)
}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.app.application_id
}

resource "random_string" "random" {
  length  = 16
  special = true
}

resource "azuread_service_principal_password" "passwd" {
  service_principal_id = azuread_service_principal.sp.id
  value                = random_string.random.result
  end_date             = "2099-01-01T01:02:03Z"
}

resource "azurerm_role_assignment" "rbac" {
  scope                = data.azurerm_subscription.sub.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.sp.object_id
}