###############################################################
# terraform/modules/networking/variables.tf
###############################################################

variable "resource_group_name" {
    description = "Name of the networking resource group"
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
    description = "Address prefix for the Private Endpoint subnet"
    type        = string
    default     = "10.1.1.0/24"
}

variable "firewall_private_ip" {
    description = "Private IP address of the Azure Firewall for UDR egress routing"
    type        = string
    default     = "10.1.2.4"
}
