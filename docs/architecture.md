# Platform Architecture

## Overview

This document describes the reference architecture for the PwC UK Core Banking Cloud Transformation platform, deployed on Microsoft Azure.

## Infrastructure Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Microsoft Azure (UK South)                       │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                   Virtual Network (10.0.0.0/14)              │    │
│  │                                                               │    │
│  │  ┌──────────────────┐    ┌────────────────────────────────┐  │    │
│  │  │  AGW Subnet      │    │  AKS Subnet (10.0.0.0/16)      │  │    │
│  │  │  (10.1.0.0/24)   │    │                                │  │    │
│  │  │                  │    │  ┌──────────────────────────┐  │  │    │
│  │  │  App Gateway +   │───▶│  │  AKS Private Cluster     │  │  │    │
│  │  │  WAF Policy      │    │  │  (v1.28, 3 AZs)          │  │  │    │
│  │  │                  │    │  │                          │  │  │    │
│  │  └──────────────────┘    │  │  ┌────────────────────┐  │  │  │    │
│  │                          │  │  │ System Node Pool   │  │  │  │    │
│  │  ┌──────────────────┐    │  │  │ (D4ds_v5 x3)       │  │  │  │    │
│  │  │  PE Subnet       │    │  │  └────────────────────┘  │  │  │    │
│  │  │  (10.1.1.0/24)   │    │  │  ┌────────────────────┐  │  │  │    │
│  │  │                  │    │  │  │ App Node Pool      │  │  │  │    │
│  │  │  Private         │    │  │  │ (D8ds_v5 x3-20)    │  │  │  │    │
│  │  │  Endpoints for:  │    │  │  └────────────────────┘  │  │  │    │
│  │  │  • Key Vault     │    │  └──────────────────────────┘  │  │    │
│  │  │  • ACR           │    └────────────────────────────────┘  │    │
│  │  │  • SQL Server    │                                         │    │
│  │  └──────────────────┘                                         │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  Platform Services:                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  ┌───────────┐  │
│  │ Azure Key   │  │ Azure       │  │ Log Analytics│  │ Azure     │  │
│  │ Vault       │  │ Container   │  │ Workspace    │  │ Service   │  │
│  │ (RBAC)      │  │ Registry    │  │ (90-day ret) │  │ Bus       │  │
│  └─────────────┘  └─────────────┘  └──────────────┘  └───────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Design Principles

The platform architecture adheres to the following principles, shaped by FCA, PCI-DSS, and ISO 27001 requirements.

**Zero-trust networking** is enforced through private AKS API server endpoints, private link for all PaaS services, and explicit network security groups for all subnets. No public IPs are attached to cluster nodes.

**Immutable infrastructure** means all changes flow through Terraform with exact provider version pinning (e.g. `azurerm = "= 3.85.0"`). No wildcard version constraints (`~>`) are permitted. This was a direct response to a production incident where an auto-upgraded azurerm provider destroyed six production subnets.

**Workload Identity Federation** replaces all static Service Principal credentials. Every GitHub Actions workflow and Kubernetes workload authenticates using OIDC tokens, eliminating the 90-day manual rotation that previously caused pipeline failures during releases.

**Multi-zone high availability** is achieved by spreading AKS node pools across all three UK South availability zones using topology spread constraints. Pod Disruption Budgets ensure a minimum of 2 replicas survive any planned maintenance.

## Network Architecture

All external traffic enters through Azure Application Gateway with WAF Policy in Prevention mode. The Application Gateway terminates TLS and forwards to AKS internal load balancer services.

AKS nodes route all egress through Azure Firewall with a UDR (User Defined Route) to prevent data exfiltration. Azure Container Registry, Key Vault, and SQL Server are accessed exclusively via Private Endpoints with corresponding Private DNS zones linked to the VNet.

## Security Architecture

Key Vault is configured with RBAC authorization (not access policies). AKS uses the CSI Secrets Store driver to mount Key Vault secrets as volume files, with 2-minute automatic rotation. No Kubernetes secrets contain plaintext credentials.

OPA Gatekeeper enforces cluster policies including: no privileged containers, mandatory resource limits, read-only root filesystems, and non-root user IDs. Policy violations block pod scheduling.

Azure Defender for Containers and Microsoft Defender for Cloud provide runtime threat detection with integration into the Log Analytics workspace and PagerDuty alerting.

## Disaster Recovery

Recovery Time Objective (RTO): 4 hours for P0 incidents.
Recovery Point Objective (RPO): 15 minutes (Azure SQL geo-redundant backups).

The blue-green deployment pattern maintains a warm standby using Helm release history. Rollback to the previous release takes approximately 90 seconds via `helm rollback`.

Terraform state is stored in Azure Blob Storage with versioning and soft-delete enabled. State lock uses Azure Blob lease mechanism.
