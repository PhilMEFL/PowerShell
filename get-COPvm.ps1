cls
Connect-VIServer copvc01 | Out-Null
$objXL = New-Object -ComObject Excel.application
$objXL.DisplayAlerts = $false
$objXL.Workbooks.Add() | Out-Null
$intCol = 1
#('VM','Description','CPU','Memory','Disk','Supported Windows Version','Supported VMWare Version','Notes') | {	
#	$objXL.cells.item(1, $intCol++) = $strTitle
#	}
foreach ($strTitle in ('VM','Description','CPU','Memory','Disk','Supported Windows Version','Supported VMWare Version','Notes')) {
	$objXL.cells.item(1, $intCol++) = $strTitle
	}
$intRow = 1

$VMs = (Get-VM | sort $_.name)

foreach ($vm in $VMs) {
	Write-Progress -Activity "Collecting Virtual Machines" -status "Finding file $vm" -percentComplete ($intRow / $VMs.count*100)
	$intRow++
	$intCol = 1

	$objXL.cells.item($intRow, $intCol++) = $vm.Name
	$objXL.cells.item($intRow, $intCol++) = $vm.Host.Name
	$objXL.cells.item($intRow, $intCol++) = "{0} cores" -f $vm.get_NumCpu()
	$objXL.cells.item($intRow, $intCol++) = "{0} GB" -f  $vm.MemoryGB
	$objXL.cells.item($intRow, $intCol++) = "{0:N2} GB" -f $vm.ProvisionedSpaceGB
	$objXL.cells.item($intRow, $intCol++) = $vm.Guest.OSFullName
	$objXL.cells.item($intRow, $intCol++) = "VMWare ESX {0} " -f $vm.Host.Version
	}
$rngUsed = $objXL.Worksheets.Item(1).usedRange
$rngUsed.entireColumn.Autofit()
$objXL.Worksheets.Item(1).Name = 'COP Virtual Machines'
$objXL.Worksheets.Item(1).SaveAs('c:\temp\COPvms.xlsx')
$objXL.DisplayAlerts = $true
$objXL.Visible = $true
