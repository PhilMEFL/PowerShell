cls

Import-Module C:\Users\pmartin\Documents\WindowsPowershell\Modules\ScheduledJobTools\ScheduledJobTools.psm1
$action = New-ScheduledTaskAction -Execute 'Powershell.exe'  -Argument '-NoProfile -WindowStyle Hidden -command "& {get-eventlog -logname Application -After ((get-date).AddDays(-1)) | Export-Csv -Path c:\fso\applog.csv -Force -NoTypeInformation}"'

$trigger =  New-ScheduledTaskTrigger -Daily -At 9am

#Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "AppLog" -Description "Daily dump of Applog"

Register-ScheduledJob -Name EnergyAnalysisJob -Trigger $trigger -ScriptBlock {
	powercfg.exe -energy -xml -output C:\temp\energy.xml -duration 60 | Out-Null
	$EnergyReport = [xml](get-content C:\temp\energy.xml)
	$namespace = @{ ns = "http://schemas.microsoft.com/energy/2007" }
	$xPath = "//ns:EnergyReport/ns:Troubleshooter/ns:AnalysisLog/ns:LogEntry[ns:Severity = 'Error']"
	$EnergyErrors = $EnergyReport | Select-Xml -XPath $xPath -Namespace $namespace 
	$EnergyErrors.Node | select Name, Description 
	}


Export-ScheduledJob EnergyAnalysisJob -Path c:\Temp


Import-ScheduledJob -Path 'c:\temp\EnergyAnalysisJob.xml'


$glubzoup = Import-ScheduledJob -Path C:\Users\pmartin\AppData\Local\Microsoft\Windows\PowerShell\ScheduledJobs\WSUpdate
$glubzoup

function getTasks($path) {
    $out = @()

    # Get tasks from subfolders
    $schedule.GetFolder($path).GetFolders(0) | % {
        $out += getTasks($_.Path)
    }

    # Get root tasks
    $schedule.GetFolder($path).GetTasks(0) | % {
        $xml = [xml]$_.xml
        $out += New-Object psobject -Property @{
            "Name" = $_.Name
            "Path" = $_.Path
            "LastRunTime" = $_.LastRunTime
            "NextRunTime" = $_.NextRunTime
            "Actions" = ($xml.Task.Actions.Exec | % { "$($_.Command) $($_.Arguments)" }) -join "`n"
        }
    }


    #Output
    $out
}
cls
$tasks = @()

$schedule = New-Object -ComObject "Schedule.Service"
$schedule.Connect('COPWA01') 

# Start inventory
$tasks = getTasks("\")

# Close com
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($schedule) | Out-Null
Remove-Variable schedule

# Output all tasks
$tasks.Count
$tasks | ? {$_.Name -eq "WSUS updates" }