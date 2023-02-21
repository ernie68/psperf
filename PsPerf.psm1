Add-Type @"
    using System;
    namespace Perf.PerfCounters {
        public struct Category {
           public string CategoryName;
           public string CategoryHelp;
           public System.Diagnostics.PerformanceCounterCategoryType CategoryType;
           public string InstanceNames;
        }
        public struct Counter {
           public string CategoryName;
           public string CounterName;
           public string CounterHelp;
           public string CounterType;
        }
    }
"@

Function Get-PerfCategory
{
[Cmdletbinding()]
Param(
    [Parameter(Mandatory=$True)]
    [ValidateScript({[System.Diagnostics.PerformanceCounterCategory]::Exists('PsPerf.' + $_)})]
    [ValidateNotNullOrEmpty()]
    [string]$CategoryName
)
    
    $RegisteredCategory = [System.Diagnostics.PerformanceCounterCategory]::GetCategories() | Where-Object { $_.CategoryName -eq 'PsPerf.' + $CategoryName }
    $InstanceNames = $RegisteredCategory.GetInstanceNames()
    $Cat = New-Object Perf.PerfCounters.Category
    $Cat.CategoryName = $RegisteredCategory.CategoryName
    $Cat.CategoryHelp = $RegisteredCategory.CategoryHelp
    $Cat.CategoryType = $RegisteredCategory.CategoryType
    If ($InstanceNames -eq $Null) { $Cat.InstanceNames = $Null } Else { $Cat.InstanceNames = $InstanceNames -join ',' }

    Write-Output $Cat   
} # End function

Function Get-PerfCounter
{
[Cmdletbinding()]
Param(
    [Parameter(Mandatory=$True)]
    [ValidateScript({[System.Diagnostics.PerformanceCounterCategory]::Exists('PsPerf.' + $_)})]
    [ValidateNotNullOrEmpty()]
    [string]$CategoryName
)
    $RegisteredCategory = [System.Diagnostics.PerformanceCounterCategory]::GetCategories() | Where-Object { $_.CategoryName -eq 'PsPerf.' + $CategoryName }
    If ($RegisteredCategory.CategoryType -eq [System.Diagnostics.PerformanceCounterCategoryType]::MultiInstance) {
        $FirstInstance = @($RegisteredCategory.InstanceNames -split ',')[0]
        $RegisteredCategory.GetCounters($FirstInstance) | Foreach-Object {
            $Cnt = New-Object Perf.PerfCounters.Counter
            $Cnt.CategoryName = $RegisteredCategory.CategoryName
            $Cnt.CounterName = $_.CounterName
            $Cnt.CounterHelp = $_.CounterHelp
            $Cnt.Countertype = $_.CounterType 
            Write-Output $Cnt
        } # End GetCounters
    } Else {
        $RegisteredCategory.GetCounters() | Foreach-Object {
            $Cnt = New-Object Perf.PerfCounters.Counter
            $Cnt.CategoryName = $RegisteredCategory.CategoryName
            $Cnt.CounterName = $_.CounterName
            $Cnt.CounterHelp = $_.CounterHelp
            $Cnt.Countertype = $_.CounterType 
            Write-Output $Cnt
        } # End GetCounters
    } # End If/Else CategoryType
} # End function

Function New-PerfCategory 
{
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [ValidateScript({[System.Diagnostics.PerformanceCounterCategory]::Exists('PsPerf.' + $_) -eq $False})]
    [ValidateNotNullOrEmpty()]
    [string]$CategoryName,
    [Parameter(Mandatory=$True)]
    [string]$CategoryHelp,
    [Parameter(Mandatory=$True)]
    [System.Diagnostics.PerformanceCounterCategoryType]$CategoryType
)

    $New = New-Object Perf.PerfCounters.Category
    $New.CategoryName = "PsPerf.$CategoryName"
    $New.CategoryHelp = $CategoryHelp
    $New.CategoryType = $CategoryType
    $New.InstanceNames = $Null
    Write-Output $New
} # End function

Function Register-PerfCounter
{
[CmdLetBinding()]
Param(
    [Parameter(Mandatory=$True,ParameterSetName='ExistingCategory')]
    [ValidateScript({[System.Diagnostics.PerformanceCounterCategory]::Exists('PsPerf.' + $_)})]
    [string]$CategoryName,
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$CounterName,
    [Parameter(Mandatory=$True)]
    [System.Diagnostics.PerformanceCounterType]$CounterType,
    [Parameter(Mandatory=$False)]
    [string]$CounterHelp = 'Created by PsPerf Powershell Module by Ørnulf Schømer. No Help text has been specified by user.',
    [Parameter(Mandatory=$True,ParameterSetName='NewCategory')]
    [ValidateScript({[System.Diagnostics.PerformanceCounterCategory]::Exists('PsPerf.' + $_.CategoryName) -eq $False})]
    [Perf.PerfCounters.Category]$Category
)
Begin { }
Process {
    Switch ($PSCmdlet.ParameterSetName) {
        'ExistingCategory' {
            $RetrievedCategory = Get-PerfCategory -CategoryName $CategoryName
            $RetrievedCounters = Get-PerfCounter -CategoryName $CategoryName
            
            Write-Verbose "Removing counter category $($RetrievedCategory.CategoryName)"
            [System.Diagnostics.PerformanceCounterCategory]::Delete($RetrievedCategory.CategoryName) | Out-Null

            $Counters = New-Object  System.Diagnostics.CounterCreationDataCollection
            Foreach ($Ctr in $RetrievedCounters) {                
                $CounterData = New-Object  System.Diagnostics.CounterCreationData
                $CounterData.CounterName = $Ctr.CounterName.Trim()
                $CounterData.CounterType = $Ctr.CounterType
                $CounterData.CounterHelp = $Ctr.CounterHelp.Trim()
                $Counters.Add($CounterData) | Out-Null
            }
            #.. adding the new counter
            $CounterData = New-Object  System.Diagnostics.CounterCreationData
            $CounterData.CounterName = $CounterName
            $CounterData.CounterType = $CounterType
            $CounterData.CounterHelp = $CounterHelp
            $Counters.Add($CounterData) | Out-Null

            Write-Verbose "Replacing Category with counters"
            [System.Diagnostics.PerformanceCounterCategory]::Create($RetrievedCategory.CategoryName, $RetrievedCategory.CategoryHelp, $RetrievedCategory.CategoryType, $Counters) | Out-Null     
        } # End 'Existingcategory'
        'NewCategory'      {
            $NewCounters = New-Object  System.Diagnostics.CounterCreationDataCollection
            $CounterData = New-Object  System.Diagnostics.CounterCreationData
            $CounterData.CounterName = $CounterName
            $CounterData.CounterType = $CounterType
            $CounterData.CounterHelp = $CounterHelp
            $NewCounters.Add($CounterData) | Out-Null
            # Collection with one counter created, now register it to the system using passed category data
             Write-Verbose "Creating counter category $($Category.CategoryName) and adding first counter $($CounterData.CounterName)"
            [System.Diagnostics.PerformanceCounterCategory]::Create($Category.CategoryName, $Category.CategoryHelp, $Category.CategoryType, $NewCounters) | Out-Null
        }
    } # End Switch
} # End Process
End {}
} # End function

Function Unregister-PerfCategory
{
[Cmdletbinding()]
Param(
    [Parameter(Mandatory=$True)]
    [ValidateScript({[System.Diagnostics.PerformanceCounterCategory]::Exists('PsPerf.' + $_)})]
    [ValidateNotNullOrEmpty()]
    [string]$CategoryName
)

Begin { }
Process {
    Write-Verbose "Removing performance counter category $CategoryName"
    Foreach ($Category in [System.Diagnostics.PerformanceCounterCategory]::GetCategories() | Where-Object { $_.CategoryName -eq "PsPerf.$CategoryName" }) {
        [System.Diagnostics.PerformanceCounterCategory]::Delete('PsPerf.' + $Category.CategoryName) | Out-Null
    }    
} # End Process
End {}
} # End Function

Function Unregister-PerfCounter
{
[Cmdletbinding()]
Param(
    [Parameter(Mandatory=$True)]
    [ValidateScript({[System.Diagnostics.PerformanceCounterCategory]::Exists('PsPerf.' + $_)})]
    [ValidateNotNullOrEmpty()]
    [string]$CategoryName,
    [Parameter(Mandatory=$True)]  
    [string]$CounterName
)

Begin { 
    $RetrievedCategory = Get-PerfCategory -CategoryName $CategoryName
    $RetrievedCounters = Get-PerfCounter -CategoryName $CategoryName | Where-Object { $_.CounterName -eq $CounterName }
    If ($RetrievedCounters -eq $Null) {
        Throw "Category $CategoryName does not contain a counter $CounterName."
    }
    $RetrievedCounters = Get-PerfCounter -CategoryName $CategoryName
}
Process {            
    Write-Verbose "Removing counter category $($CategoryName)"
    [System.Diagnostics.PerformanceCounterCategory]::Delete('PsPerf.' + $CategoryName) | Out-Null
    
    # Re-add everything but the selected counter
    $Counters = New-Object  System.Diagnostics.CounterCreationDataCollection
    Foreach ($Ctr in $RetrievedCounters | Where-Object { $_.CounterName -ne $CounterName}) {
        Write-Verbose "Re-adding counter $Ctr.CounterName"
        $CounterData = New-Object  System.Diagnostics.CounterCreationData
        $CounterData.CounterName = $Ctr.CounterName
        $CounterData.CounterType = $Ctr.CounterType
        $CounterData.CounterHelp = $Ctr.CounterHelp
        $Counters.Add($CounterData) | Out-Null
    } # End Foreach Savedcounter

    If ($Counters.Count -gt 0) {
        Write-Verbose "Recreating counter category $CategoryName with counters"
        [System.Diagnostics.PerformanceCounterCategory]::Create($RetrievedCategory.CategoryName, $RetrievedCategory.CategoryHelp, $RetrievedCategory.CategoryType, $Counters) | Out-Null
    } Else {
        Write-Verbose "Last counter removed"
    } # End if/else $Counters > 0    
} # End Process
End {}
} # End Function

Function Out-PerfCounter
{
    Foreach ($Category in [System.Diagnostics.PerformanceCounterCategory]::GetCategories() | Where-Object { $_.CategoryName -match "^PsPerf" }) {
        $Instances = @($Category.GetInstanceNames())
        If ($Category.CategoryType -eq [System.Diagnostics.PerformanceCounterCategoryType]::MultiInstance -and $Instances.Count -gt 0) {
            # MultiInstance           
            Foreach($Instance in $Instances | Select-Object -first 1) {
                Foreach ($Counter in $Category.GetCounters($Instance)) {
                    Write-Output $Counter            
                }
            } 
        } Else {
            # Single instance
            Foreach ($Counter in $Category.GetCounters()) {
                Write-Output $Counter            
            }
        }     
    }
} # End Function

Function New-PerfCounter
{
[Cmdletbinding()]
Param(
    [Parameter(Mandatory=$True)]
    [ValidateScript({[System.Diagnostics.PerformanceCounterCategory]::Exists('PsPerf.' + $_)})]
    [string]$CategoryName,
    [Parameter(Mandatory=$True)]    
    [string]$CounterName,
    [Parameter(Mandatory=$False)]   
    $InstanceName = $Null     
)

Begin {
    $RetrievedCategory = Get-PerfCategory -CategoryName $CategoryName
    $RetrievedCounters = Get-PerfCounter -CategoryName $CategoryName | Where-Object { $_.CounterName -eq $CounterName }
    If ($RetrievedCounters -eq $Null) {
        Throw "Category $CategoryName does not contain a counter $CounterName."
    }
}
Process {
    If ($RetrievedCategory.CategoryType -eq [System.Diagnostics.PerformanceCounterCategoryType]::MultiInstance) {
        $Counter = New-Object  System.Diagnostics.PerformanceCounter("PsPerf.$CategoryName", $CounterName, $InstanceName, $false)
        Write-Output $Counter
    } ElseIf ($RetrievedCategory.CategoryType -eq [System.Diagnostics.PerformanceCounterCategoryType]::SingleInstance) {        
        $Counter = New-Object  System.Diagnostics.PerformanceCounter("PsPerf.$CategoryName", $CounterName, $false)
        Write-Output $Counter
    } Else {
        Throw "Category Type $($RetrievedCategory.CategoryType)" 
    }
}
End {}
} # End function