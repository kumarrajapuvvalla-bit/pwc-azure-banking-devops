###############################################################
# terraform/modules/aks/main.tf
# Azure Kubernetes Service module — Private AKS 1.28
# FCA-compliant: private API, OPA Gatekeeper, WIF, PDB enforced
###############################################################

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.environment == "prod" ? "Standard" : "Free"
  tags                = var.tags

  # Private cluster — required for FCA network segmentation
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false

  # API server authorised IP ranges (applied in addition to private link)
  api_server_access_profile {
    authorized_ip_ranges = var.allowed_ip_ranges
    vnet_integration_enabled = true
    subnet_id                = var.subnet_id
  }

  default_node_pool {
    name                         = "system"
    node_count                   = var.system_node_pool_node_count
    vm_size                      = var.system_node_pool_vm_size
    vnet_subnet_id               = var.subnet_id
    os_disk_type                 = "Ephemeral"
    os_disk_size_gb              = 128
    only_critical_addons_enabled = true
    temporary_name_for_rotation  = "systemtemp"
    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    outbound_type     = "userDefinedRouting"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  azure_policy_enabled             = true
  http_application_routing_enabled = false
  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 4]
    }
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    start_time  = "02:00"
    duration    = 4
  }

  auto_scaler_profile {
    balance_similar_node_groups  = true
    expander                     = "least-waste"
    scale_down_delay_after_add   = "10m"
    scale_down_unneeded          = "10m"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count  # managed by cluster autoscaler
    ]
    prevent_destroy = false
  }
}

resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "id-${var.project}-aks-kubelet-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.app_node_pool_vm_size
  vnet_subnet_id        = var.subnet_id
  os_disk_type          = "Ephemeral"
  os_disk_size_gb       = 128
  enable_auto_scaling   = true
  min_count             = var.app_node_pool_min_count
  max_count             = var.app_node_pool_max_count
  mode                  = "User"
  tags                  = var.tags

  node_labels = {
    "workload-type" = "application"
    "environment"   = var.environment
  }

  node_taints = []

  upgrade_settings {
    max_surge = "33%"
  }

  lifecycle {
    ignore_changes = [node_count]
  }
}

# Attach ACR to AKS (pull images without credentials)
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_user_assigned_identity.kubelet.principal_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

# Key Vault Secrets Officer for CSI driver
resource "azurerm_role_assignment" "aks_kv_secrets" {
  principal_id                     = azurerm_user_assigned_identity.kubelet.principal_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = var.key_vault_id
  skip_service_principal_aad_check = true
}
