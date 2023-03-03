#Creates the following alert rules for all current and future VMs in a subscription

#Thresholds for each alert
#CPU greater than 80%
#Available memory bytes less than 1 GB
#Data Disk IOPs consumed percentage is greater than 95%
#OS disk IOPS consumed percentage is greater than 95%

#Variables based on environment
$resourceGroup = "RG1"
$targetResourceRegion = "USGov Arizona"
$tenantId = "40a3c411-b2a7-4f7b-a28e-05bf8dd7ab7b"
$subscriptionIds = Get-AzSubscription -TenantId "$tenantId"
$subscriptionIds = $subscriptionIds.Id

#Set windowsize and frequency parameters
$windowSize = New-TimeSpan -Minutes 5
$frequency = New-TimeSpan -Minutes 5

#Count to Append Count to Rule Name
$i = 0

Foreach ($subscriptionId in $subscriptionIds){

$i++

#CPU Percentage Condition
$conditionCPU = New-AzMetricAlertRuleV2Criteria `
-MetricName "Percentage CPU" `
-TimeAggregation Average `
-Operator GreaterThan `
-Threshold 0.8

#CPU Percentage Create Alert Rule
Add-AzMetricAlertRuleV2 `
    -Name "PercentageCPURule$i" `
    -Description "This rule generates an alert when CPU utilization rises above 80%" `
    -ResourceGroupName "$resourceGroup" `
    -WindowSize $windowSize `
    -Frequency $frequency `
    -TargetResourceScope "/subscriptions/$subscriptionId" `
    -TargetResourceType "Microsoft.Compute/virtualMachines" `
    -TargetResourceRegion "$targetResourceRegion" `
    -Condition $conditionCPU `
    -Severity 2

#Available Memory Bytes Condition
$conditionMemory = New-AzMetricAlertRuleV2Criteria `
    -MetricName "Available Memory Bytes"`
    -TimeAggregation Average `
    -Operator LessThan `
    -Threshold 1000000000

#Available Memory Bytes Create Alert Rule
Add-AzMetricAlertRuleV2 `
    -Name "AvailableMemoryBytesRule$i" `
    -Description "This rule generates an alert when available memory drops below 1 GB" `
    -ResourceGroupName "$resourceGroup" `
    -WindowSize $windowSize `
    -Frequency $frequency `
    -TargetResourceScope "/subscriptions/$subscriptionId" `
    -TargetResourceType "Microsoft.Compute/virtualMachines" `
    -TargetResourceRegion "$targetResourceRegion" `
    -Condition $conditionMemory `
    -Severity 2

#Data Disk IOPs Consumed Condition
$conditionDataDiskIOPs = New-AzMetricAlertRuleV2Criteria `
-MetricName "Data Disk IOPS Consumed Percentage" `
-TimeAggregation Average `
-Operator GreaterThan `
-Threshold 0.95

#Data Disk IOPs Consumed Create Alert Rule
Add-AzMetricAlertRuleV2 `
    -Name "DataDiskIOPSConsumedPercentageRule$i" `
    -Description "This rule generates an alert when the IOPs on the Data Disk rises above 95%" `
    -ResourceGroupName "$resourceGroup" `
    -WindowSize $windowSize `
    -Frequency $frequency `
    -TargetResourceScope "/subscriptions/$subscriptionId" `
    -TargetResourceType "Microsoft.Compute/virtualMachines" `
    -TargetResourceRegion "$targetResourceRegion" `
    -Condition $conditionDataDiskIOPs `
    -Severity 2

#OS Disk IOPS Consumed Condition
$conditionOSDiskIOPs = New-AzMetricAlertRuleV2Criteria `
-MetricName "OS Disk IOPS Consumed Percentage" `
-TimeAggregation Average `
-Operator GreaterThan `
-Threshold 0.95

#OS Disk IOPs Consumed Create Alert Rule
Add-AzMetricAlertRuleV2 `
    -Name "OSDiskIOPSConsumedPercentageRule$i" `
    -Description "This rule generates an alert when the IOPs on the OS Disk rises above 95%" `
    -ResourceGroupName "$resourceGroup" `
    -WindowSize $windowSize `
    -Frequency $frequency `
    -TargetResourceScope "/subscriptions/$subscriptionId" `
    -TargetResourceType "Microsoft.Compute/virtualMachines" `
    -TargetResourceRegion "$targetResourceRegion" `
    -Condition $conditionOSDiskIOPs `
    -Severity 2
}