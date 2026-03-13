###############################################################
# terraform/modules/acr/variables.tf
###############################################################

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "location_short" { type = string; default = "uks" }
variable "environment" { type = string }
variable "project" { type = string }
variable "tags" { type = map(string) }
variable "sku" { type = string; default = "Premium" }
variable "pe_subnet_id" { type = string }
variable "private_dns_zone_id" { type = string }
