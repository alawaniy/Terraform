# variables.tf

# Resource Group
variable "resource_group_name" {
  description = "The name of the resource group containing the Event Hub and Key Vault"
  type        = string
}

# Event Hub Namespace
variable "eventhub_namespace_name" {
  description = "The name of the Event Hub namespace"
  type        = string
}

# Event Hub Name
variable "eventhub_name" {
  description = "The name of the Event Hub"
  type        = string
}

# Key Vault Name
variable "key_vault_name" {
  description = "The name of the Azure Key Vault"
  type        = string
}

# Authorization Rule Name
variable "authorization_rule_name" {
  description = "The name of the Event Hub authorization rule"
  type        = string
  default     = "send-manage-policy"
}

# Access Permissions
variable "permissions" {
  description = "The permissions to assign to the authorization rule"
  type = object({
    send   = bool
    manage = bool
    listen = bool
  })
  default = {
    send   = true
    manage = true
    listen = false
  }
}
Step 2: Local Variables
Use local variables to simplify access to variable data. You can define these in the main.tf file:

hcl
Copy code
# locals.tf (can be in the same file as main.tf if you prefer)
locals {
  eventhub_namespace_name = var.eventhub_namespace_name
  eventhub_name           = var.eventhub_name
  key_vault_name          = var.key_vault_name
  authorization_rule_name = var.authorization_rule_name
}
Step 3: Updated Terraform Code with Variables
hcl
Copy code
provider "azurerm" {
  features {}
}

# Reference existing Event Hub Namespace
data "azurerm_eventhub_namespace" "existing_namespace" {
  name                = local.eventhub_namespace_name
  resource_group_name = var.resource_group_name
}

# Reference existing Event Hub
data "azurerm_eventhub" "existing_eventhub" {
  name                = local.eventhub_name
  namespace_name      = data.azurerm_eventhub_namespace.existing_namespace.name
  resource_group_name = data.azurerm_eventhub_namespace.existing_namespace.resource_group_name
}

# Authorization Rule (Access Policy) for existing Event Hub with dynamic permissions
resource "azurerm_eventhub_authorization_rule" "send_manage_policy" {
  name                = local.authorization_rule_name
  namespace_name      = data.azurerm_eventhub_namespace.existing_namespace.name
  eventhub_name       = data.azurerm_eventhub.existing_eventhub.name
  resource_group_name = data.azurerm_eventhub_namespace.existing_namespace.resource_group_name

  # Define permissions from the variable
  send   = var.permissions.send
  manage = var.permissions.manage
  listen = var.permissions.listen
}

# Reference existing Key Vault
data "azurerm_key_vault" "existing_key_vault" {
  name                = local.key_vault_name
  resource_group_name = var.resource_group_name
}

# Store the Primary Key in Key Vault
resource "azurerm_key_vault_secret" "eventhub_send_policy_primary_key" {
  name         = "eventhub-send-policy-primary-key"
  value        = azurerm_eventhub_authorization_rule.send_manage_policy.primary_key
  key_vault_id = data.azurerm_key_vault.existing_key_vault.id
}
Step 4: Define Values in terraform.tfvars
You can define the values for these variables in a terraform.tfvars file:

hcl
Copy code
# terraform.tfvars

resource_group_name       = "your-resource-group-name"
eventhub_namespace_name   = "lp-central-logging"
eventhub_name             = "application-logs"
key_vault_name            = "your-key-vault-name"
authorization_rule_name   = "send-manage-policy"

# Customize the permissions (optional)
permissions = {
  send   = true
  manage = true
  listen = false
}
