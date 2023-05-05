resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.region

  tags = var.tags
}

module "network" {
  source = "../../terraform-modules-azure/network/vnet/"

  region              = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = var.vnet_name
  address_spaces      = var.vnet_address_spaces
  subnets             = var.vnet_subnets

  tags = var.tags
}

# Required so we can define the Azure App Gateway Subnet to the AKS RouteTable
resource "azurerm_route_table" "this" {
  name                = "aks-routetable"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

# Here we add the AKS Subnet to the routetable
resource "azurerm_subnet_route_table_association" "aks_subnet" {
  subnet_id      = module.network.vnet_subnets["aks-subnet"].id
  route_table_id = azurerm_route_table.this.id
}

# Here we add the App GW Subnet to the routetable, we need to use the same routetable so App GW can communicate with AKS Kubenet
resource "azurerm_subnet_route_table_association" "appgw_subnet" {
  subnet_id      = module.network.vnet_subnets[var.app_gw_vnet_subnet_name].id
  route_table_id = azurerm_route_table.this.id
}