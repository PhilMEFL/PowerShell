$schedule = new-object -com("Schedule.Service") 
$schedule.connect()
$schedule.getfolder("Microsoft\Windows\PowerShell\ScheduledJobs").gettasks(0)
$tasks = $schedule.getfolder("Microsoft\Windows\PowerShell\ScheduledJobs").gettasks(0)
$tasks

#$tasks | select Name, LastRunTime

foreach ($t in $tasks) {
	$t.Name
    foreach ($a in $t.Actions)
    {
        Write-Host "Task Action Path: $($a.Path)" # This worked
        Write-Host "Task Action Working Dir: $($a.workingDirectory)" # This also worked
    }

    $firstAction = $t.Actions.Item.Invoke(1)
    Write-Host "1st Action Path: $($firstAction.Path)"
    Write-Host "1st Action Working Dir: $($firstAction.WorkingDirectory)"
}