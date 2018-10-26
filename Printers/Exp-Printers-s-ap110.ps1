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
function Get-Ports($fromServer) {
	$arrReturn = @()

	$regHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(“LOCALMACHINE”,$fromServer)

	# Get Standard TCP/IP ports
	$regKey = $regHKLM.OpenSubKey(“System\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports”)
	
	foreach ($key in $regKey.GetSubKeyNames()) {
		$arrReturn += $regKey.OpenSubKey($key)
		}

	# Get HP Standard TCP/IP ports
	$regKey = $regHKLM.OpenSubKey(“System\CurrentControlSet\Control\Print\Monitors\HP Standard TCP/IP Port\Ports”)
	
	foreach ($key in $regKey.GetSubKeyNames()) {
		$arrReturn += $regKey.OpenSubKey($key)
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
	$Driver = $printer.DriverName

	# Set the right driver
	if ($Driver.ToUpper().Contains('LASERJET') -or
		$Driver.ToUpper().Contains('HP')) {
		$Driver = 'HP Universal Printing PCL 5 (v5.1)'
		}

	if ($Driver.ToUpper().Contains('LEXMARK')) {
		if ($printer.Comment.Toupper().Contains('T644')) {
			$Driver = 'Lexmark T644 PS3'
			}
		else {
			$Driver = 'Lexmark Universal'
			}
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
	
	if ($printer.SystemName -eq 'S-AP110') {
		$Comment = $Comment.replace('-','/')
		}
	$Comment = $Comment.Split("/")
	

	$tmpName = "P-$($Comment[1].toUpper()).$($Comment[3].ToUpper()).$($Comment[4].ToUpper()).$(set-DriverType($Driver))"
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
	$Comment = $Comment.split(';')
	$DG = $Location[2].ToUpper() -replace('ADMIN','HR')
	$NewLocation = "$($Location[0].ToUpper())/$($Location[1].ToUpper())/$($DG)/$($Location[3].ToUpper())"
	$NewLocation
	}
	
function set-NewComment($printer) {
	$printer.DriverName = $printer.DriverName.Replace(' PCL6','')
	$printer.DriverName = $printer.DriverName.Replace(' PCL 6','')
	$printer.DriverName = $printer.DriverName.Replace(' PCL 5','')
	$printer.DriverName = $printer.DriverName.Replace(' PS3','')
	$printer.DriverName = $printer.DriverName.Replace(' PS','')
	$printer.Location = $printer.Location.SubString(4)
	if ($printer.Comment.toUpper().Contains('02DI')) {
#		$printer.Comment = "INV:$($printer.Comment.substring($printer.Comment.toUpper().indexof('02DI'),$printer.Comment.Length - $printer.Comment.ToUpper().IndexOf('02DI')))"
		$printer.Comment = "INV:$($printer.Comment.substring($printer.Comment.toUpper().indexof('02DI'),15))"
		}
	else {
		$printer.Comment = 'INV:02DIxxxxxxxxxxx'
		}
	$NewComment = "$($printer.DriverName) - $($printer.Location) - $($printer.Comment.Replace(' ',''))".toUpper()
	$NewComment -replace('ADMIN','HR')
	}
	
function move-printer($prnNew) {
	
	$server = $prnNew.NewServer
	
	# Create port
	$port = ([WMICLASS]"\\$server\ROOT\cimv2:Win32_TCPIPPrinterPort").createInstance()
	$port.Name = $prnNew.Port
	$port.SNMPEnabled = $false 
	$port.Protocol = 1 
	$port.HostAddress = $prnNew.IPAddress 
	$port.PortNumber = $prnNew.IPPort
	$port.Put() | Out-Null

# Get the dummy printer for those drivers
	if ($prnNew.'Printer Driver' -eq 'HP Universal Printing PCL 6 (v5.1)' -or 
		$prnNew.'Printer Driver' -eq 'Lexmark Universal' -or 
		$prnNew.'Printer Driver' -eq 'Lexmark T644 PS3' -or 
		$prnNew.'Printer Driver' -eq 'PCL6 Driver for Universal Print' -or 
		$prnNew.'Printer Driver' -eq 'XEROX Global Print Driver PCL') {
		$print = Get-WmiObject -Query "select * from Win32_Printer where name = '$($prnNew.'Printer Driver')'" -ComputerName $server
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
	$print.Put() | Out-Null

# Set printing defaults for the printers without dummy queue
#	$print = Get-WmiObject -Query "select * from Win32_Printer where name = '$($print.Name)'" -ComputerName $server
	$server = "\\$server"
	$pserver = new-object System.Printing.PrintServer $server

	$pqueue = new-object System.Printing.PrintQueue -argumentList $pserver,$print.Name,1,$queueperms        

	if 	(!($prnNew.'Printer Driver' -eq 'HP Universal Printing PCL 6 (v5.1)' -or 
			$prnNew.'Printer Driver' -eq 'Lexmark Universal' -or 
			$prnNew.'Printer Driver' -eq 'Lexmark T644 PS3' -or
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

function Get-PrinterData($printer) {

	$items = $printer | get-member -MemberType NoteProperty | select name

	$printerNew = @{}
	foreach ($item in $printer | get-member -MemberType Property) {
		$printerNew.add($item.Name,$printer.$($item.Name))
		}
	$printerNew.add('IPAddress','')
	$printerNew.add('IPPort','')
	$printerNew.add('NewServer','s-ci-prt03')

	# Generate new printer name (Comment and location are used to build the new name)
	# Check description and location
	if (($printer.Comment) -and ($printer.Location))  {
		if ($printer.SystemName -eq 'S-DIGIT110') {
			$printer.Comment = $printer.Comment.Replace(',',';')
			}
		else {
			if ($printer.Comment.Split(';').length -lt 3) {
				do {
					$printer.Comment += ';**'
					}
				until ($printer.Comment.Split(';').length -eq 3)
				}
			}
		# Check if DG = HR or ADMIN and replace it by HR
		if ($printer.SystemName -eq 'S-DIGIT110') {
			$printer.Location = $printer.Location.Replace('.','/')
			$printer.Location = $printer.Location.Replace('LUX/DRB/','LUX/DRB/HR/')
			}
		$DG = $printer.Location.Split('/')
		if ($DG.Length -gt 2) {
			if (($DG[2] -eq 'HR') -or ($DG[2] -eq 'ADMIN')) {
				$printer.Location = $printer.Location -replace('ADMIN','HR')
				if ($printer.Location.split('/').Length -lt 4) {
					do {
						$printer.Location += '/**'
						}
					until ($printer.Location.split('/').Length -eq 4)
					}
				}
			else {
				$printerNew.NewServer = 's-ci-prt01'
				}
			}
		else {
			$printerNew.NewServer = 's-ci-prt01'
			}
		}
	else {
		$printerNew.NewServer = 's-ci-prt01'
		}
		
	# Check if the printer's inventory is in the list provided by P. Beriou
	if ($printerNew.NewServer -eq 's-ci-prt03') {
		$filepath = '\\d02di0815253dit\c$\Documents and Settings\ci-martiph\My Documents\WindowsPowerShell\Printers\HRLUX.xls'
		$strConn = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=`"$filepath`";Extended Properties=`"Excel 8.0;HDR=Yes;IMEX=1`";"
		$sql = "select * from [2$] where IdGenerique = '$($PrinterNew.Comment.Replace(' ','').ToUpper().Substring($PrinterNew.Comment.Replace(' ','').ToUpper().IndexOf('02DI')))'"
		$OLEDBConn = New-Object System.Data.OleDb.OleDbConnection($strConn)
		$OLEDBConn.open()
		$readcmd = New-Object system.Data.OleDb.OleDbCommand($sql,$OLEDBConn)
		$readcmd.CommandTimeout = '300'
		$da = New-Object system.Data.OleDb.OleDbDataAdapter($readcmd)
		$dt = New-Object system.Data.datatable
		$HR = $da.fill($dt)
		$OLEDBConn.close()
		if ($HR -eq 0) {
			$printerNew.NewServer = 's-ci-prt01'
			}
		}

	# Check driver
	$printerNew.'Printer Driver' = set-Driver($printer)
	if (($ExcludedDrivers.Contains($printerNew.'Printer Driver')) -or 
		($(set-DriverType($printer.DriverName)) -eq 'UNKNOWN')) {
		$printerNew.NewServer = 's-ci-prt01'
		}
	
	if ($printerNew.NewServer -eq 's-ci-prt03') {
		$printerNew.Name = set-NewPrinterName $printer.Location $printer.DriverName
		$printerNew.Location = set-NewLocation $printer.Location $printer.Comment
		$printerNew.Description = set-NewComment $printer
		# Checking PortName 
		if (!($printer.Name.Contains($printer.PortName))) {
			"Warning !!! The portname of $($oldName) is incorrect : $($printer.PortName)" | Out-File $logFile -Append
			}	
		
		# Retrieve the IP address and port
		$Port = $printer.Name
		if ($Port) {
			$printerNew.Port = $printerNew.Name
			$printerNew.IPAddress = $hashIP[$Port]
			if ($hashPort[$port]) {
				$printerNew.IPPort = $hashPort[$Port]
				}
			else {
				$printerNew.IPPort = '9100'
				}
			}
			
		"$($printer.SystemName)\$($printer.Name) ==> $($printerNew.NewServer)\$($printerNew.Name) ($($printerNew['Printer Driver']))" | Out-Host
		}

	$printerNew
	}

#########################################################################################################
# Script entry point
#########################################################################################################

cls

# Check command line arguments
	$fromServer = 's-ap110'
	$fromServer2 = 's-digit110'

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
		$printPorts2 = Get-WmiObject Win32_TCPIPPrinterPort -computer $fromServer2
		}

	foreach ($printPort in $printPorts) {
		$portName = $printPort.Name.Substring($printPort.Name.LastIndexOf('\') + 1)
		if (!($hashIP[$portName])) {
			$hashIP.Add($portName,$printPort.HostAddress)
			}
		if (!($hashPort[$portName])) {
			$hashPort.Add($portName,$printPortPortNumber)
			}
		}

	foreach ($printPort in $printPorts2) {
		$portName = $printPort.Name.Substring($printPort.Name.LastIndexOf('\') + 1)
		if (!($hashIP[$portName])) {
			$hashIP.Add($portName,$printPort.HostAddress)
			}
		if (!($hashPort[$portName])) {
			$hashPort.Add($portName,$printPortPortNumber)
			}
		}

# Read host file on s-ap110 for other ports
	$hosts = Get-Content "\\$fromServer\d$\install printers\hosts.txt"
	foreach ($line in $hosts) {
		if ($line.StartsWith('158')) {
			$temp =  $line.Split("`t")
			if (!($hashIP[$temp[1]])) {
				$hashIP.Add($temp[1],$temp[0])
				}
			}
		}

# Read host file on s-digit110 for other ports
	$hosts = Get-Content "\\$fromServer2\d$\install printers\hosts.txt"
	foreach ($line in $hosts) {
		if ($line.StartsWith('158')) {
			$temp =  $line.Split("`t")
			if (!($hashIP[$temp[2]])) {
				$hashIP.Add($temp[2],$temp[0])
				}
			}
		}

# Get the printers on the server	
	# Windows 2000 Server doesn't handle WmiObject Win32_TCPIPPrinterPort
	if ($oldOS) {
		$printers = Get-Printers $fromServer
		}
	else {
		$printers = get-wmiobject win32_printer -computer $fromServer 
		$printers2 = get-wmiobject win32_printer -computer $fromServer2 
		}

# merge printers from both servers
	foreach ($printer in $printers2) {
		$printers += $printer
		}

	$ix = 1
	foreach ($printer in $printers) {
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
		$ix++
		}
	'Script completed'	
