output "resource_group_name" {
  description = "Name of the monitoring resource group"
  value       = azurerm_resource_group.monitoring.name
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.monitoring.name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.monitoring.id
}

output "action_group_id" {
  description = "Resource ID of the security alert action group"
  value       = azurerm_monitor_action_group.security_alerts.id
}

output "alert_rule_name" {
  description = "Name of the resource group deletion alert"
  value       = azurerm_monitor_scheduled_query_rules_alert_v2.resource_group_deletion.name
}