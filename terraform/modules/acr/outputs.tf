###############################################################
# terraform/modules/acr/outputs.tf
###############################################################

output "acr_id" {
  description = "Resource ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

output "login_server" {
  description = "Login server hostname for ACR"
  value       = azurerm_container_registry.main.login_server
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}
