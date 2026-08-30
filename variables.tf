variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
}
variable "alert_email" {
  description = "Email address that receives Azure Monitor alerts"
  type        = string
  sensitive   = true
}
