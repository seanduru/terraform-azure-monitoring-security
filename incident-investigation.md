# Microsoft Sentinel Incident Investigation

## Incident Summary

**Incident:** Successful Resource Group Deletion  
**Severity:** Medium  
**Detection Source:** Microsoft Sentinel  
**Affected Resource:** SENTINEL-INCIDENT-TEST-RG  
**Actor:** seanduru@gmail.com  
**Source IP:** 69.125.78.116  
**Operation:** Microsoft.Resources/subscriptions/resourceGroups/delete  
**Result:** Success  
**Classification:** True Positive - Benign Authorized Activity

## Investigation Timeline

### 1. Detection Triggered
Microsoft Sentinel generated a Medium severity incident after the scheduled analytics rule detected a successful Azure resource group deletion.

### 2. Identity and Source Analysis
Azure Activity logs identified the actor as `seanduru@gmail.com` and the source IP as `69.125.78.116`.

### 3. Operation Timeline
Using the event Correlation ID, the deletion operation was reconstructed:

- 7:38:05.525 PM - Deletion started
- 7:38:05.635 PM - Deletion accepted by Azure
- 7:38:06.916 PM - Deletion completed successfully

All events originated from the same identity and source IP.

### 4. Activity Context
Activity surrounding the incident showed that `SENTINEL-INCIDENT-TEST-RG` was successfully created approximately 26 seconds before its deletion by the same identity and source IP.

Additional analysis of the actor's Azure activity over the previous 24 hours showed that `69.125.78.116` was the primary source IP, accounting for 28 recorded operations.

## Analyst Determination

The detection was classified as a **True Positive - Benign Authorized Activity**.

Microsoft Sentinel correctly detected a successful resource group deletion. Investigation confirmed that the resource group was intentionally created and deleted as part of an authorized security detection test.

The same identity and source IP were associated with both the creation and deletion activity. Review of surrounding Azure activity did not identify evidence indicating unauthorized or malicious behavior.

## Resolution

No containment or remediation actions were required.

The incident was documented and resolved as authorized administrative activity generated during a controlled Microsoft Sentinel detection test.

## Final Disposition

**True Positive - Benign Authorized Activity**

## KQL Investigation Queries

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