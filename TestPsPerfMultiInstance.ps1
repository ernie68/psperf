$Category     = 'Alerta'
$CategoryHelp = 'SCOM -> Alerta Counters'
$CounterName  = 'Alert Count'
$CounterHelp  = 'Number of alerts sendt to Alerta'

$NewCounters = New-Object  System.Diagnostics.CounterCreationDataCollection
$CounterData = New-Object  System.Diagnostics.CounterCreationData
$CounterData.CounterName = $CounterName
$CounterData.CounterType = [System.Diagnostics.PerformanceCounterType]::NumberOfItems32
$CounterData.CounterHelp = $CounterHelp
$NewCounters.Add($CounterData) | Out-Null

# Collection created, now register it to the system using passed category data

$CategoryType = [System.Diagnostics.PerformanceCounterCategoryType]::MultiInstance
[System.Diagnostics.PerformanceCounterCategory]::Create($Category, $CategoryHelp, $CategoryType, $NewCounters) | Out-Null

# Performance Category Created with counter

# Instantiate and use counter
$c = new-object System.Diagnostics.PerformanceCounter -ArgumentList "Alerta","Alert Count","Connector",$false
$d = new-object System.Diagnostics.PerformanceCounter -ArgumentList "Alerta","Alert Count","Refresh",$false

$c.RawValue = 100
$d.RawValue = 100


