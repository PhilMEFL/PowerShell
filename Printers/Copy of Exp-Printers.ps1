# Constants definitions
New-Variable outFolder '\\s-ci-mgtj01\LSA\_Scripts\martiqh\printer\export_data' -Option Constant
New-Variable ExcludedDrivers 'HP DeskJet 1120C;Oce VarioPrint 2110 PS;HP LaserJet 1200 Series PCL 6;HP LaserJet 8150 PCL 6;HP Officejet Pro K550 Series;HP Business Inkjet 2200/2250;RISO RZ 9 Series;HP Color LaserJet 4550 PCL 6HP DesignJet 1055CM by HP;HP Color LaserJet 8550 PCL 5C;HP 2500C Series;HP Color LaserJet 9500 PCL 6;HP DeskJet 1220C Printer;HP Color LaserJet 5550 PCL 6;HP Designjet T1100ps 44in HPGL2;HP Deskjet 9800 Series;HP Designjet Z6100 60in Photo HPGL2;LANIER LD145 PCL 6;Oce VarioPrint 2100 PS;HP Business Inkjet 2800 PS' -Option Constant
#"\\s-ci-mgtj01\LSA\_Scripts\martiqh\printer.ps\export_data"
# Script Variables definitions
$global:prnList = ""
$global:drvList = ""

# Hash tables creation for the IP adresses and ports
$hashIP = @{}
$hashPort = @{}

# Functions
function Get-Ports($fromServer) {
	$arrReturn = @()

	$regHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(“LOCALMACHINE”,$fromServer)
	$regKey = $regHKLM.OpenSubKey(“System\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports”)
	
	foreach ($key in $regKey.GetSubKeyNames()) {
		$temp = $regKey.OpenSubKey($key) 
		$arrRow = "" | select $($temp.GetValueNames())
		$arrRow.HostName = $key
		$arrRow.IPAddress = $temp.GetValue('IPAddress')
		$arrRow.PortNumber = $temp.GetValue('PortNumber')
		$arrReturn += $arrRow
		}
	$arrReturn
	}

function Get-Printers($fromServer) {
	$arrReturn = @()

	$regHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(“LOCALMACHINE”,$fromServer)
	$regKey = $regHKLM.OpenSubKey(“System\CurrentControlSet\Control\Print\Printers”)
	
	foreach ($key in $regKey.GetSubKeyNames()) {
		$temp = $regKey.OpenSubKey($key) 
		$arrRow = "" | select $($temp.GetValueNames())
		$arrRow.Name = $key
		
		$arrRow.Description = $temp.GetValue('Description')
		$arrRow.Location = $temp.GetValue('Location')
		$arrRow.'Printer Driver' = $temp.GetValue('Printer Driver')
		$arrRow.'Separator File' = $temp.GetValue('Separator File')
		$arrRow.Port = $temp.GetValue('Port')
		
		$arrReturn += $arrRow
		}

	$arrReturn
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
	$Driver | Out-Host
	if ($ExcludedDrivers.Contains($Driver)) {
		$false
		}
	
	if (set-DriverType($Driver) -ne 'UNKNOWN') {
		# Set the right driver
		if ($Driver.ToUpper().Contains('LASERJET')) {
			$Driver = 'HP Universal Printing PCL 6 (v5.1)'
			}
		if ($Driver.ToUpper().Contains('LEXMARK')) {
			if ($printer.Description.Toupper().Contains('T644')) {
				$printerNew.'Printer Driver' = 'Lexmark T644 PS3'
				}
			else {
				$printerNew.'Printer Driver' = 'Lexmark Universal XL'
				}
			}
		if ($printer.'Printer Driver'.ToUpper().Contains('NRG') -or 
			$printer.'Printer Driver'.ToUpper().Contains('RICOH')) {
			$printerNew.'Printer Driver' = 'PS Driver for Universal Print'
			}
				
		}
	$true
	}

function set-NewPrinterName($Comment,$Driver) {
	[bool] $prnExist = $True
	[int] $i = 1
	[string] $tmpName = ""
	
	$Comment = $Comment.Split(",")

	$tmpName = "P-$($Comment[0].toUpper()).$($Comment[1].ToUpper()).$($Comment[2].ToUpper()).$(set-DriverBrand $Driver)"
	do {
		# avoid duplicate names
		$prnExist = $global:prnList.contains($tmpName)
		if ($prnExist) {
			$tmpDuplName = "$tmpName.$i"
			$i += 1
			}
		if ($tmpDuplName) {
			$tmpName = $tmpDuplName
			}
		}
	while ($prnExist)
	$global:prnList += "$tmpName;"
	$tmpName.replace(' ','')
	}
	
function set-NewLocation($Location,$Comment) {
	$Location = $Location.split('/')
	$Comment = $Comment.split(',')
	$NewLocation = "$($Location[0].ToUpper())/$($Location[1].ToUpper())/$($Location[2].ToUpper())/$($Location[3].ToUpper())/$($Comment[2].ToUpper())"
	$NewLocation
	}
	
function set-NewComment($printer) {
	$printer.'Printer Driver' = $printer.'Printer Driver'.Replace(' PCL6','')
	$printer.'Printer Driver' = $printer.'Printer Driver'.Replace(' PCL 6','')
	$printer.'Printer Driver' = $printer.'Printer Driver'.Replace(' PCL 5','')
	$printer.'Printer Driver' = $printer.'Printer Driver'.Replace(' PS3','')
	$printer.'Printer Driver' = $printer.'Printer Driver'.Replace(' PS','')
	$printer.Location = $printer.Location.SubString(4)
	if ($printer.Description.Contains('02DI')) {
		$printer.Description = "INV:$($printer.Description.substring($printer.Description.indexof('02DI'),15))"
		}
	else {
		$printer.Description = 'INV:02DIxxxxxxxxxxx'
		}
	$NewComment = "$($printer.'Printer Driver') - $($printer.Location) - $($printer.Description) - OldName : $($printer.Name)"
	$NewComment
	}
	
function move-printer($printerNew, $server, $printerData, $driverData) {
	$printerNew | Out-Host
	$regHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(“LOCALMACHINE”,$Server)
	$regKey = $regHKLM.OpenSubKey(“System\CurrentControlSet\Control\Print\Printers”,$true)
	$regKey.GetSubKeyNames()
	
	$regKey.CreateSubKey($printerNew.Name)
	}

function Get-PrinterData($printer) {
	$printerNew = '' | select ${Name,Comment,Location,Driver,SeparatorFile,PortName}
	$Migrable = $false
	
	# Removing CR/LF from the used fields (To be develloped)
	$items = $printer | get-member -MemberType NoteProperty | select name
	
#	foreach ($item in $items) {
#		write-Host ($item = $printer.$item)
#		$printer[$item] -replace(10,'')
#		$printer[$item] -replace(13,'')
#		}

	$newLine = ''
	# Generate new printer name (Comment and location are used to build the new name)
	$printer.Name | Out-Host
	# Check if printer can be migrated
	$printer | Out-Host
	
	# Check description
	if ($printer.Description) {
		$printerNew.Description = $printer.Description
		if ($printerNew.Description.Split(',').length -lt 3) {
			do {
				$printerNew.Description += ',**'
				}
			until ($printerNew.Description.Split(',').length -eq 3)
			}
		$Migrable = $true
		}
	
	# Check location
	if ($printer.Location) {
		# Check if DG = HR
		$DG = $printer.Location.Split('/')
		if ($DG.Length -gt 2) {
			if ($DG[2] -eq 'HR') {
				$Migrable = $true
				}
			}
		$printerNew.Location = $printer.Location
		if ($printerNew.Location.split('/').Length -lt 4) {
			do {
				$printerNew.Location += '/**'
				}
			until ($printerNew.Location.split('/').Length -eq 4)
			}
		$Migrable = $true
		}
	
	# Check driver
	$printerNew | Out-Host
	if (set-Driver($printer)) {
		}
	$printerNew | Out-Host
		
	if ($Migrable) {
		if ($printer.'Printer Driver') {
			$printerNew.Name = set-NewPrinterName $printer.Description $printer.'Printer Driver'
			$printerNew.Location = set-NewLocation $printer.Location $printer.Description
			$printerNew.Description = set-NewComment $printer
			
		# Checking PortName 
		if (!($printer.Name.Contains($printer.Port))) {
			"Warning !!! The portname of $($printer.Name) is incorrect : $($printer.Port)" | Out-File $logFile -Append
			}	
		
			# Retrieve the IP address and port
			if ($printer.Port) {
				$IPAddress = $hashIP[$printer.Port]
				$IPPort = $hashPort[$printer.Port]
				}
			
#			$newLine = "$newName,$newComment,$newLoc,$driver,$($printer.SeparatorFile),$($printer.Port),$IPAddress,$IPPort,,$DG,yes"
			$newLine = "$newName,$newComment,$newLoc,$driver,$($printer.SeparatorFile),$newname,$IPAddress,$IPPort,,$DG,yes"
			"\\$fromServer\$($printer.Name) - $newName - $driver" | Out-Host

		# Get printer defaults
		$regHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(“LOCALMACHINE”,$fromServer)
		$regKey = $regHKLM.OpenSubKey(“System\CurrentControlSet\Control\Print\Printers”)
		$printerData = $regkey.OpenSubKey($printer.Name)
#		$printerData.Name
		
		# Get printer data
		$driverData = $printerData.OpenSubKey('printerDriverData')
#		$driverData.Name
		
			move-printer $printerNew $toServer $printerData $driverData
			}
			$printer.Name | Out-File $logFile -Append
		}
	else {
		$printer.Name | Out-File $logFile -Append
		}
	$newLine
	}
	

#########################################################################################################
# Script entry point
#########################################################################################################

cls
# Check command line arguments
if ($args.count -ne 2) {
	"Usage : exp-Printers From_Server_Name To_Server_Name"
	}
else {
	$fromServer = $args[0]
	$toServer = $args[1]	
# Create output files
	$outPath = "$outFolder\$fromServer"
	if (!(Test-Path $outPath)) {
		New-Item $outPath -type directory 
		}	
	else {
		Remove-Item $outPath\*.* -Recurse -Force
		}
	$csvFile = "$outPath\itic-allprinters.csv"
	$logFile = "$OutPath\itic-allprinters.log"
	# Create header for CSV file
	'Name,Comment,Location,Driver,Separator File,PortName,IPAddress,IPPort,empty,DG,yes' | Out-File $csvFile
		
# Get Operating system of the server
	$OS = Get-WmiObject -class Win32_OperatingSystem -computername $fromServer
	$oldOS = ($OS.Version.Substring(0,3) -eq "5.0")

# Get printers ports
	# Windows 2000 Server doesn't handle WmiObject Win32_TCPIPPrinterPort
	if ($oldOS) {
		$printPorts = Get-Ports $fromServer
		}
	else {
		$printPorts = Get-WmiObject Win32_TCPIPPrinterPort -computer $fromServer
		}
	foreach ($printPort in $printPorts) {
		$hashIP.Add($printPort.HostName,$printPort.IPAddress)
		$hashPort.Add($printPort.HostName,$printPort.PortNumber)
		}
	
# Get the printers on the server	
	# Windows 2000 Server doesn't handle WmiObject Win32_TCPIPPrinterPort
	if ($oldOS) {
		$printers = Get-Printers $fromServer
		}
	else {
		$printers = get-wmiobject win32_printer -computer $fromServer 
		}
		
	foreach ($printer in $printers) {
		# Writing csv output file
		if ($strLine = Get-PrinterData $printer) {
			$strLine | Out-File $csvFile -Append
			}
		}
	'Script completed'	
	}
