$ErrorActionPreference = 'Inquire'
Add-Type -AssemblyName System.Printing
$queueperms = [System.Printing.PrintSystemDesiredAccess]::AdministratePrinter

# Constants definitions
#New-Variable outFolder '\\s-ci-mgtj01\LSA\_Scripts\martiqh\printer\export_data' -Option Constant
New-Variable outFolder 'c:\logs' -Option Constant
New-Variable ExcludedDrivers 'HP DeskJet 1120C;Oce VarioPrint 2110 PS;HP LaserJet 1200 Series PCL 6;HP LaserJet 8150 PCL 6;HP Officejet Pro K550 Series;HP Business Inkjet 2200/2250;RISO RZ 9 Series;HP Color LaserJet 4550 PCL 6HP DesignJet 1055CM by HP;HP Color LaserJet 8550 PCL 5C;HP 2500C Series;HP Color LaserJet 9500 PCL 6;HP DeskJet 1220C Printer;HP Color LaserJet 5550 PCL 6;HP Designjet T1100ps 44in HPGL2;HP Deskjet 9800 Series;HP Designjet Z6100 60in Photo HPGL2;LANIER LD145 PCL 6;Oce VarioPrint 2100 PS;HP Business Inkjet 2800 PS' -Option Constant
#"\\s-ci-mgtj01\LSA\_Scripts\martiqh\printer.ps\export_data"
# Script Variables definitions
$global:prnList = ""
$global:drvList = ""

# Hash tables creation for the IP adresses and ports
$hashIP = @{}
$hashPort = @{}

# Functions
function Get-Printers($fromServer) {
	$arrReturn = @()

	$regHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(“LOCALMACHINE”,$fromServer)
	$regKey = $regHKLM.OpenSubKey(“System\CurrentControlSet\Control\Print\Printers”)
	foreach ($key in $regKey.GetSubKeyNames()) {
		$temp = $regKey.OpenSubKey($key) 
		if ($temp.get_ValueCount() -gt 1) {
			$errorHandler = $ErrorActionPreference
			$ErrorActionPreference = 'Continue'
			$arrRow = '' | select $($temp.GetValueNames())
			$ErrorActionPreference = $errorHandler
			$arrRow.Name = $key
			foreach ($item in $temp.getValueNames()) {
				$arrRow.$item = $temp.getValue($item)
				}
			$arrReturn += $arrRow
			}
		else {
			"Incomplete registry key for printer $key" | Out-File $logFile -Append
			}
		}
	$arrReturn
	}
	
function set-print_processor($print) {
	
	trap  {
		Write-Host "An exception has occured $($_.Exception.Message)"
		break
		}

	if ($print.PrintProcessor -ne 'WinPrint') {
		$print.PrintProcessor = 'WinPrint'
		$print.Put() | Out-Null
		$print.Name
		}
	}
	

#########################################################################################################
# Script entry point
#########################################################################################################

cls

# Check command line arguments
if ($args.count -ne 1) {
	"Usage : exp-Printers From_Server_Name"
	}
else {
	$fromServer = $args[0]

# Create output files
	$outPath = "$outFolder\$fromServer"
	if (!(Test-Path $outPath)) {
		New-Item $outPath -type directory 
		}	
	else {
		Remove-Item $outPath\*.* -Recurse -Force
		}
	$logFile = "$OutPath\itic-allprinters.log"
		
# Get the printers on the server	
	$printers = get-wmiobject win32_printer -computer $fromServer 
	
	$ix = 1
	foreach ($printer in $printers) {
		"Printer #$ix of $($printers.count) : $($printer.Name)"
		set-print_processor $printer >> $logFile
		$ix++
		}
	'Script completed'	
	}
