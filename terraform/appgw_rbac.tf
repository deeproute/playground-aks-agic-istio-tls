resource "azurerm_user_assigned_identity" "appgw" {
  name                = "appgw-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Required for AppGW to access secrets in key vault (AppGW is using the same identity as AKS)
resource "azurerm_role_assignment" "appgw_secrets_user" {
  scope                = module.akv.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id # azurerm_user_assigned_identity.aks_user.principal_id 
}

