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
$hashServer = @{'OIB'='s-ci-prt05';'OIL'='s-ci-prt04';'EPSO'='s-ci-prt04';'PMO'='s-ci-prt05';'HR'='S-ci-prt03';'ADMIN'='s-ci-prt03'}
$hashDG = @{'OIB'='OIB';'OIL'='OIL';'EPSO'='EPS';'PMO'='PMO';'HR'='DHR';'ADMIN'='DHR'}

# Functions
function Get-Ports($fromServer) {
	$arrReturn = @()

	$regHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(“LOCALMACHINE”,$fromServer)

	# Get Standard TCP/IP ports
	$regKey = $regHKLM.OpenSubKey(“System\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports”)
	
	foreach ($key in $regKey.GetSubKeyNames()) {
		$arrReturn += $regKey.OpenSubKey($key)
		}

	# Get HP Standard TCP/IP ports if any
	if ($regKey = $regHKLM.OpenSubKey(“System\CurrentControlSet\Control\Print\Monitors\HP Standard TCP/IP Port\Ports”)) {
		foreach ($key in $regKey.GetSubKeyNames()) {		
			$arrReturn += $regKey.OpenSubKey($key)
			}
		}

	$arrReturn
	}

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

function Get-PrinterData($printer) {

	$items = $printer | get-member -MemberType NoteProperty | select name

# Generate a hash table with the new printer elements
	$printerNew = @{}
	foreach ($item in $items) {
		$printerNew.add($item.Name,$printer.$($item.Name))
		}
	$printerNew.add('IPAddress','')
	$printerNew.add('IPPort','')
	$printerNew.add('NewServer','')

# Generate new printer name (Comment and location are used to build the new name)
# Check description and location
	if (($printer.Description) -and ($printer.Location))  {
		if ($printer.Description.Split(',').length -lt 3) {
			do {
				$printer.Description += ',**'
				}
			until ($printer.Description.Split(',').length -eq 3)
			}
		$printer.Location = $printer.Location -replace('ADMIN','HR')
		$printer.Location | Out-Host
		$DG = $printer.Location.Split('/')
		$DG[2] | Out-Host
		$printerNew.NewServer = $hashServer[$DG[2]]

		if ($DG.Length -gt 2) {
			if ($DG[2] -eq 'HR') {
				if ($printer.Location.split('/').Length -lt 4) {
					do {
						$printer.Location += '/**'
						}
					until ($printer.Location.split('/').Length -eq 4)
					}
				}
			}
		else {
			$printerNew.NewServer = 's-ci-prt01'
			}
		
# Check driver
	
		$printerNew.'Printer Driver' = set-Driver($printer)
		if ($ExcludedDrivers.Contains($printerNew.'Printer Driver')) {
			$printerNew.NewServer = 's-ci-prt01'
			}
		else {
			if ($(set-DriverType($printer.'Printer Driver')) -eq 'UNKNOWN') {
				$printerNew.NewServer = 's-ci-prt01'
				}
			}
	
		$printerNew.Name = set-NewPrinterName $printer.Description $printer.'Printer Driver'
		$printerNew.Location = set-NewLocation $printer.Location $printer.Description
		$printerNew.Description = set-NewComment $printer

	
# Retrieve the IP address and port
		$Port = $printer.port
		if ($Port) {
			$printerNew.Port = [string]::Format("P02DI{0:7}{1:3}",$printerNew.Description.substring($printerNew.Description.indexof('INV:') +10,7),$hashDG[$printerNew.Location.Split('/')[2]])
			$printerNew.Port | Out-Host
			$printerNew.IPAddress = $hashIP[$Port]
			$printerNew.IPPort = 9100
			}
			
		"$fromServer\$($printer.Name) ==> $($printerNew.NewServer)\$($printerNew.Name) ($($printerNew['Printer Driver']))" | Out-Host
		}

	$printerNew
	}

function set-DriverType($Driver) {
	[string] $PrnType = "UNKNOWN"
	
	if ($Driver.ToUpper().Contains('LASERJET') -or 
		$Driver.ToUpper().Contains('HP UNIVERSAL PRINTING')) {
			$PrnType = 'HP'
			}	
	if ($Driver.ToUpper().Contains('NRG') -or
		$Driver.ToUpper().Contains('LANIER') -or
		$Driver.ToUpper().Contains('RICOH')) {
			$PrnType = 'COPIER'
			}		
	if ($Driver.ToUpper().Contains('XEROX') -or
		$Driver.ToUpper().Contains('INKJET') -or
		$Driver.ToUpper().Contains('COLOR') -or
		$Driver.ToUpper().Contains('NRG MP C2500')) {
			$PrnType = 'COLOUR'
			}
	if	($Driver.ToUpper().Contains('LEXMARK')) {
			$PrnType = 'LEX'
			}
	$PrnType
	}
		
function set-Driver($printer) {
	$Driver = $printer.'Printer Driver'

	# Set the right driver
	if ($Driver.ToUpper().Contains('LASERJET') -or
		$Driver.ToUpper().Contains('HP')) {
		$Driver = 'HP Universal Printing PCL 5 (v5.2)'
		}

	if ($Driver.ToUpper().Contains('LEXMARK')) {
		$Driver = 'Lexmark Universal'
		}
		
	if ($Driver.ToUpper().Contains('NRG') -or 
		$Driver.ToUpper().Contains('LANIER') -or
		$Driver.ToUpper().Contains('RICOH')) {
		$Driver = 'PCL6 Driver for Universal Print'
		}

	if ($Driver.ToUpper().Contains('XEROX')) {
		$Driver = 'XEROX Global Print Driver PCL'
		}

	$Driver
	}

function set-NewPrinterName($Comment,$Driver) {
	[bool] $prnExist = $True
	[int] $i = 1
	[string] $tmpName = ""
	
	$Comment = $Comment.Split(",")

	$tmpName = "P-$($Comment[0].toUpper()).$($Comment[1].ToUpper()).$($Comment[2].ToUpper()).$(set-DriverType($Driver))"
	# avoid duplicate names
	while ($global:prnList.contains($tmpName)) {
		$temp = $tmpName.split('.')
		if ($i -eq 1) {
			$temp += [string] $i++
			}
		else {
			$temp[4] = [string] $i++
			}
		$tmpName = "$($temp[0]).$($temp[1]).$($temp[2]).$($temp[3]).$($temp[4])"
		}
	$global:prnList += "$tmpName;"
	$tmpName
	}
	
function set-NewLocation($Location,$Comment) {
	$Location = $Location.split('/')
	$Comment = $Comment.split(',')
	$DG = $Location[2].ToUpper() -replace('ADMIN','HR')
	$NewLocation = "$($Location[0].ToUpper())/$($Location[1].ToUpper())/$($DG)/$($Location[3].ToUpper())/$($Comment[2].ToUpper())"
	$NewLocation = [string]::Format("{0:3}/{1:4}/{2}/{3:2}/{4:3}",$Location[0].ToUpper(),$Location[1].ToUpper(),$Location[2].ToUpper(),$Location[3].ToUpper(),$Comment[2].ToUpper().padleft(3,'0'))
	$NewLocation | Out-Host
	$NewLocation
	}
	
function set-NewComment($printer) {
	$printer.'Printer Driver' = $printer.'Printer Driver'.Replace(' PCL6','')
	$printer.'Printer Driver' = $printer.'Printer Driver'.Replace(' PCL 6','')
	$printer.'Printer Driver' = $printer.'Printer Driver'.Replace(' PCL 5','')
	$printer.'Printer Driver' = $printer.'Printer Driver'.Replace(' PS3','')
	$printer.'Printer Driver' = $printer.'Printer Driver'.Replace(' PS','')
	$printer.Location = $printer.Location.SubString(4)
	if ($printer.Description.toUpper().Contains('02DI')) {
		$printer.Description = "INV:$($printer.Description.substring($printer.Description.toUpper().indexof('02DI'),$printer.Description.Length - $printer.Description.ToUpper().IndexOf('02DI')))"
		}
	else {
		$printer.Description = 'INV:02DIxxxxxxxxxxx'
		}
	$NewComment = "$($printer.'Printer Driver') - $($printer.Location) - $($printer.Description)".toUpper()
	$NewComment -replace('ADMIN','HR')
	}
	
function move-printer($prnNew) {
	
	trap  {
		Write-Host "An exception has occured $($_.Exception.Message)"
		break
		}
	if ($prnNew.NewServer -ne 's-ci-prt03') {
		$server = $prnNew.NewServer
	
# Create port
		$port = ([WMICLASS]"\\$server\ROOT\cimv2:Win32_TCPIPPrinterPort").createInstance()
		$port.Name = $prnNew.Port
		$port.SNMPEnabled = $false 
		$port.Protocol = 1 
		$port.HostAddress = $prnNew.IPAddress 
		$port.PortNumber = 9100
#		$port.Put() | Out-Null

# Get the dummy printer for those drivers
		if ($prnNew.'Printer Driver' -eq 'HP Universal Printing PCL 5 (v5.2)' -or 
			$prnNew.'Printer Driver' -eq 'Lexmark Universal' -or 
			$prnNew.'Printer Driver' -eq 'PCL6 Driver for Universal Print' -or 
			$prnNew.'Printer Driver' -eq 'XEROX Global Print Driver PCL') {
			$print = Get-WmiObject -Query "select * from Win32_Printer where name = '_$($prnNew.'Printer Driver')'" -ComputerName $server
			}
		else {
			$print = ([WMICLASS]"\\$server\ROOT\cimv2:Win32_Printer").createInstance() 
			}

		$print.Attributes = $prnNew.Attributes
		$print.Comment = $prnNew.Description
		$print.DeviceID = $prnNew.Name
		$print.DriverName = $prnNew.'Printer Driver'
		$print.Hidden = $false
		$print.Location = $prnNew.Location
		$print.Name = $prnNew.Name
		$print.Network = $true
		$print.PortName = $prnNew.Port
		$print.PrintProcessor = 'WinPrint'
		$print.Shared = $true
		$print.Sharename = $prnNew.Name
#		$print.Put() | Out-Null

# Set printing defaults for the printers without dummy queue
#	$print = Get-WmiObject -Query "select * from Win32_Printer where name = '$($print.Name)'" -ComputerName $server
		$server = "\\$server"
		$pserver = new-object System.Printing.PrintServer $server

		$pqueue = new-object System.Printing.PrintQueue -argumentList $pserver,$print.Name,1,$queueperms        

		if 	(!($prnNew.'Printer Driver' -eq 'HP Universal Printing PCL 5 (v5.2)' -or 
				$prnNew.'Printer Driver' -eq 'Lexmark Universal' -or 
				$prnNew.'Printer Driver' -eq 'PCL6 Driver for Universal Print' -or 
				$prnNew.'Printer Driver' -eq 'XEROX Global Print Driver PCL')) {
			if ($pqueue.GetPrintCapabilities().OutputColorCapability.Contains([System.Printing.OutputColor]::Color)) {
				$pqueue.DefaultPrintTicket.OutputColor = [System.Printing.OutputColor]::Color
				}
			if ($pqueue.GetPrintCapabilities().DuplexingCapability.Contains([System.Printing.Duplexing]::TwoSidedLongEdge)) {        
				$pqueue.DefaultPrintTicket.Duplexing = [System.Printing.Duplexing]::TwoSidedLongEdge		
				}
			$pqueue.commit()	
			}
		}
	}

#########################################################################################################
# Script entry point
#########################################################################################################

cls

#foreach ($fromServer in ('s-ap502','s-ap503','s-ap110','s-digit110')) {
foreach ($fromServer in ('s-ap502')) {
	"Getting printer's information from $($fromServer)"
# Create output files
	$outPath = "$outFolder\$fromServer"
	if (!(Test-Path $outPath)) {
		New-Item $outPath -type directory 
		}	
	else {
		Remove-Item $outPath\*.* -Recurse -Force
		}
	$csvFile = "$outPath\itic-allprinters.csv"
	$ITICcsvFile = "$Outpath\HR-itic.csv"
	$logFile = "$OutPath\itic-allprinters.log"
	"New name,Description,Location,Driver,Separator file,Port,IP Address,IP Port,Old Name" | Out-File $csvFile

	$printPorts = Get-Ports $fromServer

	foreach ($printPort in $printPorts) {
		$portName = $printPort.Name.Substring($printPort.Name.LastIndexOf('\') + 1)
		if (!($hashIP[$portName])) {
			if ($printPort.GetValue('IPAddress').length -gt 0) {
				$hashIP.Add($portName,$printPort.GetValue('IPAddress'))
				}
			}
		}

# Read host file on s-ap110 and s-digit110 for other ports
	if (($fromServer -eq 's-ap110') -or ($fromServer -eq 's-digit110')) {
		$hosts = Get-Content "\\$fromServer\d$\install printers\hosts.txt"
		foreach ($line in $hosts) {
			if ($line.StartsWith('158')) {
# Fields in the file are tab separated
				$temp =  $line.Split("`t")
				if (!($hashIP[$temp[1]])) {
					$hashIP.Add($temp[1],$temp[0])
					}
				}	
			}
		}
	
# Get the printers on the servers	
		$printers += Get-Printers $fromServer
	}

# Try to migrate each printer found
	$ix = 1
	foreach ($printer in $printers) {
#		if ($ix -gt 627) {
		$oldName = $printer.Name
		"Printer #$ix of $($printers.count) : $oldName"
		# Move printer to the right server
		$prnNew = Get-PrinterData $printer
		if ($prnNew['NewServer'] -eq 's-ci-prt03') {
			"$($prnNew['Name']),$($prnNew['Description']),$($prnNew['Location']),$($prnNew['Printer Driver']),$($prnNew['SeparatorFile']),$($prnNew['Port']),$($prnNew['IPAddress']),$($prnNew['IPPort']),$($oldName)" | Out-File $csvFile -Append
			"$($oldName),$($prnNew['Name']),$($prnNew.Location),$($prnNew.Description.Substring($prnNew.description.indexof('INV:')))" | Out-File $ITICcsvFile -Append
			move-printer $prnNew
			}
		else {
			"$($prnNew.Name),$($prnNew.Description),$($prnNew.Location),$($prnNew.'Printer Driver'),$($printer.SeparatorFile),$($prnNew.Port),$($prnNew.IPAddress),$($prnNew.IPPort)" | Out-File $logFile -Append
			}
#		}
		$ix++
		}
	'Script completed'	

