###############################################################
# terraform/variables.tf
# Input variables for PwC Azure Banking Platform
###############################################################

variable "environment" {
  description = "Deployment environment (dev | staging | prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Primary Azure region"
  type        = string
  default     = "uksouth"
}

variable "location_short" {
  description = "Short code for the Azure region used in resource naming"
  type        = string
  default     = "uks"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version — must be an approved version per quarterly patch schedule"
  type        = string
  default     = "1.28.5"
}

variable "vnet_address_space" {
  description = "Address space for the platform VNet"
  type        = list(string)
  default     = ["10.0.0.0/14"]
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for the AKS node subnet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "agw_subnet_address_prefix" {
  description = "Address prefix for the Application Gateway subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "pe_subnet_address_prefix" {
  description = "Address prefix for Private Endpoint subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "cost_centre" {
  description = "Cost centre code for billing allocation"
  type        = string
  default     = "CC-PLAT-001"
}

variable "alert_email" {
  description = "Email address for infrastructure alerts"
  type        = string
  sensitive   = true
}

variable "pagerduty_webhook" {
  description = "PagerDuty webhook URL for critical alerts"
  type        = string
  sensitive   = true
}

variable "allowed_ip_ranges" {
  description = "CIDR ranges permitted to access private AKS API server"
  type        = list(string)
  default     = []
}

variable "tags_override" {
  description = "Optional tag overrides to merge with common_tags"
  type        = map(string)
  default     = {}
}
