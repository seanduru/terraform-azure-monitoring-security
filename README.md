# Azure Monitoring, Microsoft Sentinel & Security Operations with Terraform

## Project Overview

This project demonstrates the deployment of an Azure monitoring and security operations environment using Terraform. The environment centralizes Azure activity logs in Log Analytics, uses KQL for log analysis, and integrates Microsoft Sentinel for SIEM based security monitoring and incident detection.

The project originally focused on Azure Monitor, Log Analytics, scheduled query alerts, and Action Groups. It was then expanded with Microsoft Sentinel to create an end to end security detection and incident investigation workflow.

A Microsoft Sentinel scheduled analytics rule was implemented to detect successful Azure resource group deletions. Controlled Azure activity was generated to test the detection, successfully producing both a security alert and security incident.

The resulting incident was investigated using KQL to identify the initiating account, affected resource, source IP address, operation timeline, and surrounding account activity. The incident was classified as a true positive with benign authorized activity and documented through a complete investigation workflow.

## Architecture

The project implements the following workflow:

### Azure Monitoring Pipeline

Azure Subscription  
→ Azure Activity Logs  
→ Log Analytics Workspace  
→ KQL Query  
→ Azure Monitor Scheduled Query Alert  
→ Action Group  
→ Email Notification

### Microsoft Sentinel Security Pipeline

Azure Subscription  
→ Azure Activity Logs  
→ Log Analytics Workspace  
→ Microsoft Sentinel  
→ KQL Scheduled Analytics Rule  
→ Security Alert  
→ Security Incident  
→ SOC Investigation and Triage

## Technologies Used

- Microsoft Azure
- Terraform
- Microsoft Sentinel
- Azure Monitor
- Log Analytics
- Kusto Query Language
- Azure Activity Logs
- Azure Action Groups
- Azure CLI
- Git
- GitHub

## Infrastructure as Code

Terraform is used to deploy and configure the monitoring and security environment, including:

- Azure Resource Group
- Log Analytics Workspace
- Azure Activity diagnostic settings
- Azure Monitor Action Group
- Azure Monitor scheduled query alert
- Microsoft Sentinel workspace onboarding
- Microsoft Sentinel scheduled analytics rule

Using Infrastructure as Code makes the environment repeatable, version controlled, and easier to maintain.

## Centralized Logging

Azure Activity Logs are forwarded into the Log Analytics workspace using Azure diagnostic settings.

The following activity categories are collected:

- Administrative
- Security
- Policy

This provides centralized visibility into subscription level activity and allows the logs to be queried using KQL.

## Azure Monitor Detection

The original monitoring portion of the project uses an Azure Monitor scheduled query rule to detect successful resource group deletions.

The rule searches Azure Activity logs for:

```kusto
AzureActivity
| where OperationNameValue =~ "MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE"
| where ActivityStatusValue =~ "Success"
```

When the condition is met, Azure Monitor triggers an alert and uses an Action Group to send a notification.

This demonstrates traditional cloud monitoring and operational alerting.

## Microsoft Sentinel Integration

Microsoft Sentinel was enabled on the existing Log Analytics workspace to extend the project from cloud monitoring into SIEM based security operations.

Terraform was used to onboard the workspace to Microsoft Sentinel and deploy a scheduled analytics rule.

The Sentinel rule searches for successful resource group deletion activity every five minutes and analyzes a fifteen minute query window.

The detection is configured with a Medium severity and automatically creates a security incident when the rule is triggered.

## Sentinel Detection Rule

The scheduled analytics rule uses the following KQL:

```kusto
AzureActivity
| where OperationNameValue =~ "MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE"
| where ActivityStatusValue =~ "Success"
```

This activity may be security relevant because unauthorized deletion of cloud infrastructure can affect system availability and may indicate destructive activity or misuse of privileged access.

## Detection Testing

To validate the detection pipeline, a temporary Azure resource group was intentionally created and deleted using Azure CLI.

Test resource:

```text
SENTINEL-INCIDENT-TEST-RG
```

The deletion event was successfully ingested into the `AzureActivity` table.

Microsoft Sentinel evaluated the event against the scheduled analytics rule and generated:

- A Microsoft Sentinel Security Alert
- A Microsoft Sentinel Security Incident

This validated the complete security detection pipeline.

## Incident Investigation

The generated incident was investigated using KQL and Azure Activity logs.

The investigation focused on answering:

- Who performed the activity?
- What resource was affected?
- Was the operation successful?
- What source IP initiated the activity?
- What activity occurred immediately before and after the event?
- Was the activity consistent with other activity from the account?

### Investigation Findings

The investigation identified:

**Actor:** `seanduru@gmail.com`

**Affected Resource:** `SENTINEL-INCIDENT-TEST-RG`

**Operation:** Resource Group Deletion

**Result:** Success

**Source IP:** `69.125.78.116`

**Correlation ID:** `c53dae21-eb89-4f47-bd1c-c9163eb9fd2c`

The correlated operation showed the following sequence:

```text
7:38:05.525 PM - Deletion started
7:38:05.635 PM - Deletion accepted
7:38:06.916 PM - Deletion completed successfully
```

Activity surrounding the incident showed that the same account and source IP created the test resource group approximately 26 seconds before deleting it.

Additional analysis showed that the source IP associated with the deletion was also the primary source IP observed for the account during the reviewed 24 hour period.

## KQL Investigation

### Identify Resource Group Deletion Events

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| where OperationNameValue =~ "MICROSOFT.RESOURCES/SUBSCRIPTIONS/RESOURCEGROUPS/DELETE"
| project TimeGenerated, Caller, ResourceGroup, OperationNameValue, ActivityStatusValue, CallerIpAddress, CorrelationId
| order by TimeGenerated desc
```

### Reconstruct the Correlated Operation

```kusto
AzureActivity
| where CorrelationId == "c53dae21-eb89-4f47-bd1c-c9163eb9fd2c"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue, ResourceGroup, CallerIpAddress
| order by TimeGenerated asc
```

### Investigate Surrounding Account Activity

```kusto
AzureActivity
| where TimeGenerated between (datetime(2026-09-04 19:30:00) .. datetime(2026-09-04 19:45:00))
| where Caller =~ "seanduru@gmail.com"
| project TimeGenerated, OperationNameValue, ActivityStatusValue, ResourceGroup, CallerIpAddress
| order by TimeGenerated asc
```

### Analyze Source IP Activity

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| where Caller =~ "seanduru@gmail.com"
| summarize Operations=count() by CallerIpAddress
| order by Operations desc
```

## Incident Classification

The incident was classified as:

**True Positive | Benign Authorized Activity**

The Sentinel detection was a true positive because the resource group deletion actually occurred and matched the intended detection logic.

The underlying activity was determined to be benign because the resource group was intentionally created and deleted as part of an authorized security detection test.

No containment or remediation actions were required.

## SOC Investigation Workflow

This project demonstrates the following Tier 1 security operations workflow:

Detection  
→ Alert Validation  
→ Incident Creation  
→ Identity Analysis  
→ Source IP Analysis  
→ Event Correlation  
→ Timeline Reconstruction  
→ Surrounding Activity Analysis  
→ Classification  
→ Documentation  
→ Resolution

## Monitoring vs SIEM Detection

The project demonstrates the difference between traditional cloud monitoring and SIEM based security operations.

### Azure Monitor

Azure Monitor detects an operational condition and triggers an Action Group notification.

```text
Activity → Log Analytics → KQL → Azure Monitor Alert → Notification
```

### Microsoft Sentinel

Microsoft Sentinel treats matching activity as a security detection and creates security objects that can be investigated.

```text
Activity → Log Analytics → KQL Analytics Rule → Security Alert → Security Incident → Investigation
```

This allows the same Azure telemetry to support both cloud operations and security operations use cases.

## Key Skills Demonstrated

- Infrastructure as Code with Terraform
- Microsoft Azure resource deployment
- Microsoft Sentinel SIEM configuration
- Log Analytics workspace management
- Azure Activity Log collection
- KQL log analysis
- Scheduled security detection engineering
- Azure Monitor alerting
- Security alert validation
- Incident investigation and triage
- Event correlation
- Timeline reconstruction
- Source IP and identity analysis
- Incident classification
- SOC documentation
- Cloud security monitoring
- Operational troubleshooting
- Git based infrastructure version control

## Project Files

```text
main.tf
variables.tf
outputs.tf
README.md
incident-investigation.md
```

`main.tf` contains the Azure monitoring and Microsoft Sentinel infrastructure.

`incident-investigation.md` contains the documented SOC investigation, findings, classification, and resolution.

## Security Considerations

Terraform state files are excluded from source control because state can contain infrastructure details and potentially sensitive information.

Sensitive values should not be hardcoded into Terraform configuration or committed to GitHub.

## Key Takeaway

This project demonstrates an end to end cloud monitoring and security operations workflow rather than only infrastructure deployment.

Terraform was used to deploy the monitoring and security resources, Azure Activity Logs and Log Analytics provided centralized telemetry, Azure Monitor provided operational alerting, and Microsoft Sentinel extended the environment with SIEM based detection and incident generation.

The generated incident was then investigated using KQL to establish identity, source, timeline, context, and final disposition, demonstrating both cloud engineering and security operations skills.