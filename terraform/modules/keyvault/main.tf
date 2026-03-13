###############################################################
# terraform/modules/keyvault/main.tf
# Azure Key Vault — RBAC mode, private endpoint, soft-delete
# ISO 27001: 90-day secret rotation; FCA: audit logging mandatory
###############################################################

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-${var.project}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "premium"   # Premium required for HSM-backed keys (PCI-DSS)

  # RBAC authorization — access policies deprecated for new deployments
  enable_rbac_authorization       = true

  # Soft-delete and purge protection — required for FCA data retention obligations
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true

  # No public network access — all access via Private Endpoint
  public_network_access_enabled   = false
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true  # Key Vault deletion is irreversible in production
  }
}

###############################################################
# Private Endpoint — binds Key Vault to the PE subnet
###############################################################

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-${var.project}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv-${var.project}-${var.environment}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-kv"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

###############################################################
# Diagnostic settings — audit all Key Vault operations
# FCA requirement: all access to sensitive data must be logged
###############################################################

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-kv-${var.environment}"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
  }
}

###############################################################
# RBAC: Secrets Officer for platform engineering team
###############################################################

resource "azurerm_role_assignment" "platform_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.platform_admin_group_object_id

  # skip_service_principal_aad_check = false — Groups always need AAD check
}

###############################################################
# RBAC: Secrets User for AKS kubelet identity (CSI driver)
###############################################################

resource "azurerm_role_assignment" "aks_secrets_user" {
  scope                            = azurerm_key_vault.main.id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = var.aks_kubelet_identity_id
  skip_service_principal_aad_check = true
}

###############################################################
# RBAC: Certificate User for AKS (cert-manager integration)
###############################################################

resource "azurerm_role_assignment" "aks_certificate_user" {
  scope                            = azurerm_key_vault.main.id
  role_definition_name             = "Key Vault Certificate User"
  principal_id                     = var.aks_kubelet_identity_id
  skip_service_principal_aad_check = true
}

###############################################################
# Seed secrets (placeholders — real values set by rotation script)
# Rotation script: scripts/rotate-secrets.sh
###############################################################

resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "banking-db-connection-string"
  value        = "PLACEHOLDER_ROTATE_BEFORE_USE"
  key_vault_id = azurerm_key_vault.main.id

  content_type    = "application/x-connection-string"
  expiration_date = timeadd(timestamp(), "2160h")  # 90 days

  tags = merge(var.tags, {
    SecretType = "database-credential"
    RotationSchedule = "90-day"
  })

  lifecycle {
    ignore_changes = [value, expiration_date]  # Managed by rotation script
  }

  depends_on = [azurerm_role_assignment.platform_secrets_officer]
}

resource "azurerm_key_vault_secret" "servicebus_connection_string" {
  name         = "banking-servicebus-connection-string"
  value        = "PLACEHOLDER_ROTATE_BEFORE_USE"
  key_vault_id = azurerm_key_vault.main.id

  content_type    = "application/x-connection-string"
  expiration_date = timeadd(timestamp(), "2160h")

  tags = merge(var.tags, {
    SecretType = "servicebus-credential"
    RotationSchedule = "90-day"
  })

  lifecycle {
    ignore_changes = [value, expiration_date]
  }

  depends_on = [azurerm_role_assignment.platform_secrets_officer]
}
