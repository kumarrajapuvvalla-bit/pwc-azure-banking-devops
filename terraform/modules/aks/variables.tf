###############################################################
# terraform/modules/aks/variables.tf
###############################################################

variable "resource_group_name" {
  description = "Name of the resource group for the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "location_short" {
  description = "Short code for the Azure region used in resource naming"
  type        = string
  default     = "uks"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "project" {
  description = "Project name used in resource naming"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
}

variable "subnet_id" {
  description = "ID of the AKS node subnet"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace"
  type        = string
}

variable "system_node_pool_vm_size" {
  description = "VM size for the system node pool"
  type        = string
  default     = "Standard_D4ds_v5"
}

variable "system_node_pool_node_count" {
  description = "Node count for the system node pool"
  type        = number
  default     = 3
}

variable "app_node_pool_vm_size" {
  description = "VM size for the application node pool"
  type        = string
  default     = "Standard_D8ds_v5"
}

variable "app_node_pool_min_count" {
  description = "Minimum node count for application node pool autoscaling"
  type        = number
  default     = 3
}

variable "app_node_pool_max_count" {
  description = "Maximum node count for application node pool autoscaling"
  type        = number
  default     = 20
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault for CSI secrets driver"
  type        = string
}

variable "acr_id" {
  description = "Resource ID of the Azure Container Registry for AcrPull assignment"
  type        = string
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS cluster admin access"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "CIDR ranges permitted to access the private AKS API server"
  type        = list(string)
  default     = []
}
