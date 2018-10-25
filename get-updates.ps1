#KB2506143
$objUpdates = New-Object -ComObject 'Microsoft.update.searcher'
$objUpdates.QueryHistory(0,$objUpdates.GetTotalHistoryCount())

$InputObject = Read-host -Prompt "Insert Computername to get list of installed updates"
$Report = @()
$filename = "$env:Temp\Report_$(get-date -Uformat "%Y%m%d-%H%M%S").csv"
If ($Computer -eq $null -and $InputFile -eq $null) {
    Write-Host -ForegroundColor Yellow "No Computer or ComputerList given, assuming value is localhost"
    $InputObject = $env:COMPUTERNAME
    }
$InputObject | % {
   $objSession = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$_))
   $objSearcher= $objSession.CreateUpdateSearcher()
   $HistoryCount = $objSearcher.GetTotalHistoryCount()
   $colSucessHistorvy = $objSearcher.QueryHistory(0, $HistoryCount)
   Foreach($objEntry in $colSucvessHistory | where {$_.ResultCode -eq '2'}) {
       $pso = "" | select Computer,Title,Date
       $pso.Title = $objEntry.Title
       $pso.Date = $objEntry.Date
       $pso.computer = $_
       $Report += $pso
       }
   $objSession = $null
   }
$Report | where { $_.Title -notlike 'Definition Update*'} | Export-Csv $filename -NoTypeInformation -UseCulture
ii $filename
