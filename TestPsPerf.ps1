$Category     = 'Alerta'
$CategoryHelp = 'SCOM -> Alerta Counters'
$CounterName  = 'ConnectorAlertCount'
$CounterHelp  = 'Number of alerts sendt to Alerta'

$NewCounters = New-Object  System.Diagnostics.CounterCreationDataCollection
$CounterData = New-Object  System.Diagnostics.CounterCreationData
$CounterData.CounterName = $CounterName
$CounterData.CounterType = [System.Diagnostics.PerformanceCounterType]::NumberOfItems32
$CounterData.CounterHelp = $CounterHelp
$NewCounters.Add($CounterData) | Out-Null

# Collection created, now register it to the system using passed category data

$CategoryType = [System.Diagnostics.PerformanceCounterCategoryType]::SingleInstance
[System.Diagnostics.PerformanceCounterCategory]::Create($Category, $CategoryHelp, $CategoryType, $NewCounters) | Out-Null

# Performance Category Created with counter

# Instantiate and use counter
$c = new-object System.Diagnostics.PerformanceCounter -ArgumentList "Alerta","ConnectorAlertCount",$false
$c.RawValue = 100
$c.RawValue = 150
$c.RawValue = 200

$c.RawValue = 50
$c.RawValue = 30

