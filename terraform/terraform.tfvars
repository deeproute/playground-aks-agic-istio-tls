region              = "eastus2"
resource_group_name = "playground-aks-agic-istio"

tags = {
  Owner = "deeproute"
}

### INFRA
vnet_name           = "infra"
vnet_address_spaces = ["10.100.0.0/16"]
vnet_subnets = [{
  name             = "aks-subnet"
  vnet_name        = "infra"
  address_prefixes = ["10.100.1.0/24"]
  }, {
  name             = "aks-appgw"
  vnet_name        = "infra"
  address_prefixes = ["10.100.2.0/24"]
}]

### AKS
cluster_name            = "aks-agic-istio"
private_cluster_enabled = false
kubernetes_version      = "1.23.15"
network_plugin          = "kubenet"
network_policy          = "calico"

node_pools = [{
  name                   = "default"
  orchestrator_version   = "1.23.15"
  vm_size                = "Standard_B2ms"
  enable_host_encryption = true
  os_disk_size_gb        = null
  os_disk_type           = null
  vnet_name              = "infra"
  subnet_name            = "aks-subnet"
  node_count             = 1
  enable_auto_scaling    = false
  min_count              = null
  max_count              = null
  max_pods               = null
  availability_zones     = ["1", "2", "3"]
  enable_public_ip       = false
  ultra_ssd_enabled      = false
  labels                 = {}
  taints                 = []
  mode                   = "System"
  },
]

## APP GW Vars
app_gw_name                      = "appgw-aks-istio"
app_gw_vnet_name                 = "infra"
app_gw_vnet_subnet_name          = "aks-appgw"
app_gw_backend_pool_name         = "aks-loadbalancer-beap"
app_gw_backend_pool_ip_addresses = ["10.100.1.254"] # Forced to create one backend pool, frontend, http settings and listener even if we aren't going to use them.

### KEY VAULT
key_vault_name                           = "akv-aks-certificates"
key_vault_randomize_name_suffix          = false # Using it to avoid getting the same destroyed AKV by always using the same name
key_vault_sku_tier                       = "standard"
key_vault_disk_encryption_access_enabled = true
key_vault_vm_access_enabled              = true
key_vault_soft_delete_retention_days     = 7
key_vault_purge_protection_enabled       = false
key_vault_enable_rbac                    = true # RBAC is the preferred role way to assign roles over the keys.

key_vault_certificates = [{
  name                      = "backend-cert"
  subject_cn                = "CN=backend.example.com"
  content_type              = "application/x-pkcs12"
  validity_in_months        = 12
  subject_alternative_names = []
  },
  # {
  #   name                          = "frontend-cert"
  #   subject_cn                    = "CN=frontend.example.com"
  #   content_type                  = "application/x-pkcs12"
  #   validity_in_months            = 12
  #   subject_alternative_names     = []                            
  # },
]
