###############################################################
# terraform/modules/aks/outputs.tf
###############################################################

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity Federation"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity (used for RBAC assignments)"
  value       = azurerm_user_assigned_identity.kubelet.principal_id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the kubelet managed identity"
  value       = azurerm_user_assigned_identity.kubelet.client_id
}

output "node_resource_group" {
  description = "Auto-generated resource group containing AKS node resources"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "kube_config_raw" {
  description = "Raw kubeconfig (sensitive)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}
