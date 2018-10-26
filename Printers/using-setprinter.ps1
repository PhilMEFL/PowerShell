$DetailedPrinterInfo = 2
$DefaultPrinterSettings = 8
$computername = $args[0]

$ErrorActionPreference="SilentlyContinue" 
 
Trap { 
    Write-Warning "There was an error connecting to the remote computer or creating the process" 
    Continue 
}     
 
Write-Host "Connecting to $computername" -ForegroundColor RED 
Write-Host "Process to create is $cmd" -ForegroundColor RED
 
[wmiclass]$wmi="\\$computername\root\cimv2:win32_process" 
 
#bail out if the object didn't get created 
if (!$wmi) {
	return
	} 
$Printers = Get-WmiObject -Class Win32_Printer -ComputerName $computername 
foreach ($printer in $printers) {
	$printer.Capabilities
#	$cmd = "setprinter -show \\$($computername)\$($printer.name) $DetailedPrinterInfo pdevmode=dmPaperSize=9, dmPaperLength=2970, dmPaperWidth=2100, dmFormName=A4"
	$cmd = "setprinter -show \\$($computername)\$($printer.name) $DetailedPrinterInfo 'pdevmode=dmDuplex=2, dmColor=1, dmCollate=1, dmFields=|duplex collate'"
	Write-Host "Process to create is $cmd" -ForegroundColor RED
	$remote=$wmi.Create($cmd) 
 
	if ($remote.returnvalue -eq 0) { 
    	Write-Host "Successfully launched $cmd on $computername with a process id of" $remote.processid -ForegroundColor GREEN 
		} 
	else { 
    	Write-Host "Failed to launch $cmd on $computername. ReturnValue is" $remote.ReturnValue -ForegroundColor RED 
		} 
	$tata = 'toto'
	}
