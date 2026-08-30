# Azure Monitoring & Security Operations with Terraform

## Project Overview

This project demonstrates how Terraform can be used to build a centralized monitoring and security alerting environment in Microsoft Azure.

The environment collects Azure management activity, routes selected logs into a Log Analytics Workspace, allows cloud activity to be investigated using KQL, and automatically generates alerts when specific infrastructure events occur.

The project was built around a real-world scenario where a cloud or security team needs visibility into changes occurring across an Azure environment.

---

## Scenario

A company has infrastructure running in Microsoft Azure but lacks centralized visibility into administrative and security-related activity.

The cloud and security teams need a way to:

- Collect important Azure activity logs
- Centralize logs for investigation
- Search cloud activity using KQL
- Detect potentially high-impact infrastructure changes
- Automatically notify the appropriate team when specific events occur

Terraform was used to deploy the monitoring and alerting infrastructure in a repeatable way.

---

## Architecture

```text
Azure Subscription / Resources
            |
            v
    Azure Activity Log
            |
            v
    Diagnostic Setting
            |
            v
 Log Analytics Workspace
            |
            v
      KQL Investigation
            |
            v
 Azure Monitor Alert Rule
            |
            v
       Action Group
            |
            v
    Email Notification
```

---

## Monitoring Workflow

The project follows a simple monitoring workflow:

```text
Collect → Centralize → Investigate → Detect → Alert
```

### Collect

Azure automatically records management-plane events in the Azure Activity Log.

Examples include:

- Resource creation
- Resource deletion
- Configuration changes
- Administrative operations
- Policy activity

### Centralize

A subscription-level Diagnostic Setting routes selected Azure Activity Log categories into a centralized Log Analytics Workspace.

The following categories are collected:

- Administrative
- Security
- Policy

### Investigate

Kusto Query Language (KQL) is used to search and investigate activity stored in Log Analytics.

### Detect

An Azure Monitor scheduled query alert automatically searches the collected logs for successful Resource Group deletion events.

### Alert

When the detection condition is met, an Azure Monitor Action Group sends an email notification.

---

## Infrastructure Deployed with Terraform

Terraform was used to deploy and configure:

- Azure Resource Group
- Log Analytics Workspace
- Subscription-level Diagnostic Setting
- Administrative Activity Log collection
- Security Activity Log collection
- Policy Activity Log collection
- Azure Monitor Action Group
- KQL-based scheduled query alert
- Email notification configuration

---

## Terraform Structure

```text
terraform-azure-monitoring-security/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── .terraform.lock.hcl
├── .gitignore
└── README.md
```

### main.tf

Defines the Azure infrastructure, including:

- Resource Group
- Log Analytics Workspace
- Diagnostic Setting
- Action Group
- Azure Monitor scheduled query alert

### variables.tf

Defines reusable input variables such as:

- Resource Group name
- Azure region
- Log Analytics Workspace name
- Alert email address

### terraform.tfvars

Provides local values for the Terraform variables.

This file is excluded from GitHub using `.gitignore`.

### outputs.tf

Returns useful information after deployment, including:

- Resource Group name
- Log Analytics Workspace name
- Log Analytics Workspace ID
- Action Group ID
- Alert Rule name

---

## Log Analytics Workspace

The Log Analytics Workspace acts as the centralized location for querying and analyzing the Azure activity collected by the monitoring environment.

The workspace was configured with:

```hcl
sku               = "PerGB2018"
retention_in_days = 30
```

This keeps collected logs available for investigation while maintaining a limited retention period for the lab environment.

---

## Diagnostic Settings

Terraform configures a subscription-level Diagnostic Setting.

The Diagnostic Setting sends selected Azure Activity Log categories to the Log Analytics Workspace.

```hcl
enabled_log {
  category = "Administrative"
}

enabled_log {
  category = "Security"
}

enabled_log {
  category = "Policy"
}
```

The current Azure subscription is dynamically identified using:

```hcl
data "azurerm_client_config" "current" {}
```

This prevents the subscription ID from needing to be hardcoded into the Terraform configuration.

---

## KQL Investigation

After deploying the monitoring infrastructure, Azure CLI was used to generate test activity.

A temporary Resource Group was created to produce an administrative event.

The activity was then located in Log Analytics using KQL.

Example investigation query:

```kusto
AzureActivity
| where TimeGenerated > ago(1h)
| sort by TimeGenerated desc
```

A more targeted query was also used:

```kusto
AzureActivity
| where TimeGenerated > ago(1h)
| where OperationNameValue contains "resourcegroups"
| project TimeGenerated, OperationNameValue, ActivityStatusValue, ResourceGroup
| sort by TimeGenerated desc
```

This allowed the exact operation names and activity statuses recorded by Azure to be investigated.

---

## Automated Detection Rule

The project includes an Azure Monitor scheduled query alert designed to detect successful Resource Group deletions.

The final KQL detection query is:

```kusto
AzureActivity
| where OperationNameValue =~ "MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE"
| where ActivityStatusValue =~ "Success"
```

The alert condition is configured to trigger when:

```text
Table rows > 0
```

This means that if the query finds one or more successful Resource Group deletion events within the evaluation window, Azure Monitor can trigger the alert.

---

## Alert Configuration

The alert is configured with:

```text
Severity:                2 - Warning
Evaluation Frequency:    5 minutes
Window Duration:         15 minutes
Measurement:             Table rows
Aggregation:             Count
Operator:                Greater than
Threshold:               0
```

The rule evaluates every 5 minutes while searching a 15-minute window of telemetry.

The larger detection window helps account for possible delays between an Azure operation occurring and the corresponding event becoming available in Log Analytics.

---

## Action Group

An Azure Monitor Action Group was created to define who should be notified and how the notification should be delivered when the alert fires.

For this project, the Action Group uses an email receiver.

Conceptually:

```text
Alert Rule
"What happened?"
      |
      v
Successful Resource Group deletion detected
      |
      v
Action Group
"Who should be notified and how?"
      |
      v
Email Notification
```

---

## Testing the Monitoring Pipeline

The monitoring system was tested using temporary Azure Resource Groups created through Azure CLI.

Example:

```bash
az group create \
  --name security-alert-test-rg \
  --location eastus
```

The Resource Group was then deleted outside Terraform:

```bash
az group delete \
  --name security-alert-test-rg \
  --yes \
  --no-wait
```

Performing the operation outside Terraform simulated an infrastructure change occurring elsewhere in the Azure environment.

The expected workflow was:

```text
Resource Group Deleted
        |
        v
Azure Activity Log Records Event
        |
        v
Diagnostic Setting Routes Event
        |
        v
Log Analytics Receives Event
        |
        v
KQL Detection Matches Event
        |
        v
Azure Monitor Alert Fires
        |
        v
Action Group Activates
        |
        v
Email Notification Sent
```

The final test successfully generated the Azure Monitor alert and email notification.

---

## Troubleshooting

The first automated detection test did not trigger an alert.

Instead of assuming the monitoring infrastructure was broken, the individual parts of the pipeline were tested.

First, the Resource Group deletion was confirmed in Log Analytics.

The actual operation value recorded by Azure was:

```text
MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE
```

The original KQL detection used a case-sensitive comparison:

```kusto
OperationNameValue == "Microsoft.Resources/subscriptions/resourcegroups/delete"
```

Because `==` performs a case-sensitive comparison, the detection query did not match the actual telemetry.

The query was corrected to use the case-insensitive equality operator:

```kusto
OperationNameValue =~ "MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE"
```

The activity status comparison was also configured using:

```kusto
ActivityStatusValue =~ "Success"
```

The corrected query was tested manually in Log Analytics and successfully returned the deletion event.

---

## Handling Log Ingestion Delay

During testing, another issue became apparent.

The original alert configuration used:

```hcl
evaluation_frequency = "PT5M"
window_duration      = "PT5M"
```

This meant Azure evaluated the alert every 5 minutes while only searching a 5-minute window.

Because telemetry can take time to arrive in Log Analytics, a narrow window could make detection less reliable.

The configuration was changed to:

```hcl
evaluation_frequency = "PT5M"
window_duration      = "PT15M"
```

The alert now:

```text
Runs every 5 minutes
        |
        v
Searches the previous 15 minutes
        |
        v
Looks for successful Resource Group deletions
```

After redeploying the corrected configuration with Terraform and generating a new test event, the alert triggered successfully.

---

## Validation

Terraform configuration was validated throughout the project using:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

These commands were used to:

- Maintain consistent Terraform formatting
- Validate Terraform configuration
- Review proposed infrastructure changes
- Deploy changes to Azure

---

## Security Considerations

Several practices were used to avoid exposing unnecessary information in the repository.

The `.gitignore` file excludes:

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfplan
crash.log
crash.*.log
.DS_Store
```

This prevents local Terraform state and variable values such as the alert email address from being committed to GitHub.

The `.terraform.lock.hcl` file can remain committed so provider dependency versions are tracked.

---

## Skills Demonstrated

- Microsoft Azure
- Terraform
- Infrastructure as Code
- Azure Monitor
- Log Analytics
- Kusto Query Language (KQL)
- Azure Activity Logs
- Diagnostic Settings
- Scheduled Query Alerts
- Action Groups
- Azure CLI
- Cloud Monitoring
- Security Monitoring
- Log Investigation
- Automated Alerting
- Infrastructure Troubleshooting
- Terraform State Management

---

## Key Takeaway

This project demonstrated how cloud activity can move from raw Azure telemetry into a usable monitoring and detection workflow:

```text
Collect → Centralize → Investigate → Detect → Alert
```

More importantly, the project demonstrated that successfully deploying monitoring infrastructure does not automatically mean the detection logic works.

The monitoring pipeline had to be tested using real Azure activity, the resulting telemetry had to be investigated with KQL, the detection query had to be corrected based on the actual log data, and the alert evaluation window had to be adjusted to account for ingestion delay.

The final result was a Terraform managed Azure monitoring environment that successfully detected a Resource Group deletion and generated an automated email notification.