# # terraform {
# #   required_providers {
# #     azurerm = {
# #       source  = "hashicorp/azurerm"
# #       version = "3.0.2"
# #     }
# #     kubernetes = {
# #       source  = "hashicorp/kubernetes"
# #       version = ">= 2.0.1"
# #     }
# #   }
# # }

# # data "terraform_remote_state" "aks" {
# #   backend = "local"

# #   config = {
# #     path = "../terraform.tfstate"
# #   }
# # }

# # Retrieve AKS cluster information
# # provider "azurerm" {
# #   features {}
# # }

# # data "azurerm_kubernetes_cluster" "cluster" {
# #   name                = data.terraform_remote_state.aks.outputs.kubernetes_cluster_name
# #   resource_group_name = data.terraform_remote_state.aks.outputs.resource_group_name
# # }

# # data "azurerm_kubernetes_cluster" "example" {
# #   name                = "myakscluster"
# #   resource_group_name = "my-example-resource-group"
# # }

provider "kubernetes" {
  host = module.aks.host
  #host = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host

  client_certificate     = module.aks.client_certificate
  client_key             = module.aks.client_key
  cluster_ca_certificate = module.aks.cluster_ca_certificate
}

# resource "kubernetes_secret" "example" {
#   metadata {
#     name = "basic-auth"
#     namespace = "default"
#   }

#   data = {
#     username = "admin"
#     password = "P4ssw0rd"
#   }

#   type = "kubernetes.io/tls"
# }
