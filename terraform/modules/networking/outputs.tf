###############################################################
# terraform/modules/networking/outputs.tf
###############################################################

output "vnet_id" {
  description = "Resource ID of the platform VNet"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the platform VNet"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "Resource ID of the AKS node subnet"
  value       = azurerm_subnet.aks.id
}

output "agw_subnet_id" {
  description = "Resource ID of the Application Gateway subnet"
  value       = azurerm_subnet.appgateway.id
}

output "pe_subnet_id" {
  description = "Resource ID of the Private Endpoint subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "keyvault_private_dns_zone_id" {
  description = "Resource ID of the Key Vault private DNS zone"
  value       = azurerm_private_dns_zone.keyvault.id
}

output "acr_private_dns_zone_id" {
  description = "Resource ID of the ACR private DNS zone"
  value       = azurerm_private_dns_zone.acr.id
}

output "servicebus_private_dns_zone_id" {
  description = "Resource ID of the Service Bus private DNS zone"
  value       = azurerm_private_dns_zone.servicebus.id
}

output "aks_nsg_id" {
  description = "Resource ID of the AKS subnet NSG"
  value       = azurerm_network_security_group.aks.id
}
