resource "azurerm_public_ip" "appgw" {
  name                = "example-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  #backend_address_pool_name      = "aks-loadbalancer-beap"
  frontend_port_name             = "aks-appgw-feport"
  frontend_https_port_name       = "aks-appgw-feport-https"
  frontend_ip_configuration_name = "aks-appgw-feip"
  http_setting_name              = "aks-loadbalancer-htst"
  listener_name                  = "aks-appgw-httplstn"
  request_routing_rule_name      = "aks-appgw-rqrt"
  redirect_configuration_name    = "aks-appgw-rdrcfg"
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.app_gw_name
  resource_group_name = var.resource_group_name
  location            = var.region

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw.id]
  }

  # https://stackoverflow.com/questions/69755363/terraform-application-gateway-data-for-certificate-is-invalid
  trusted_root_certificate {
    key_vault_secret_id = azurerm_key_vault_certificate.certs["backend-cert"].versionless_secret_id
    name                = "backend-tls"
  }

  sku {
    name     = var.app_gw_sku
    tier     = var.app_gw_sku
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = module.network.vnet_subnets[var.app_gw_vnet_subnet_name].id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = local.frontend_https_port_name
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # This block is managed by AGIC. All the block's configuration will be smashed by AGIC Ingress configuration.
  backend_address_pool {
    name         = var.app_gw_backend_pool_name
    ip_addresses = var.app_gw_backend_pool_ip_addresses
  }

  # This block is managed by AGIC. All the block's configuration will be smashed by AGIC Ingress configuration.
  backend_http_settings {
    name                  = "aks-loadbalancer-apps"
    cookie_based_affinity = "Disabled"
    #path                  = "/healthz/ready"
    port            = 80
    protocol        = "Http"
    request_timeout = 60
    probe_name      = "aks-loadbalancer-istio-status"
  }

  # This block is managed by AGIC. All the block's configuration will be smashed by AGIC Ingress configuration.
  http_listener {
    name                           = "aks-loadbalancer-apps"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  # This block is managed by AGIC. All the block's configuration will be smashed by AGIC Ingress configuration.
  request_routing_rule {
    name                       = "aks-loadbalancer-apps"
    rule_type                  = "Basic"
    http_listener_name         = "aks-loadbalancer-apps"
    backend_address_pool_name  = var.app_gw_backend_pool_name
    backend_http_settings_name = "aks-loadbalancer-apps"
    priority                   = 1000
  }

  # This block is managed by AGIC. All the block's configuration will be smashed by AGIC Ingress configuration.
  probe {
    name                = "aks-loadbalancer-istio-status"
    host                = var.app_gw_backend_pool_ip_addresses[0]
    port                = 15021
    path                = "/healthz/ready"
    protocol            = "Http"
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 3
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  tags = var.tags

  # AGIC will be the one managing the App GW configurations, we don't want TF to mess with these.
  lifecycle {
    ignore_changes = [
      backend_address_pool,
      http_listener,
      backend_http_settings,
      request_routing_rule,
      probe,
      ssl_certificate,
      frontend_port,
      redirect_configuration,
      tags
    ]
  }

  depends_on = [
    azurerm_role_assignment.appgw_secrets_user
  ]
}