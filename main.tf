terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "monitoring" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "monitoring" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.monitoring.name

  sku               = "PerGB2018"
  retention_in_days = 30
}
data "azurerm_client_config" "current" {}

resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  name               = "send-activity-logs-to-law"
  target_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"

  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "Policy"
  }
}
resource "azurerm_monitor_action_group" "security_alerts" {
  name                = "security-monitoring-action-group"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "SecAlerts"

  email_receiver {
    name          = "SecurityEngineer"
    email_address = var.alert_email
  }
}
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "resource_group_deletion" {
  name                = "resource-group-deletion-alert"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [azurerm_log_analytics_workspace.monitoring.id]
  severity             = 2

  criteria {
    query = <<-QUERY
      AzureActivity
      | where OperationNameValue =~ "MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE"
      | where ActivityStatusValue =~ "Success"
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [
      azurerm_monitor_action_group.security_alerts.id
    ]
  }
}