$Printers = Get-WmiObject -Class Win32_Printer -ComputerName 's-ci-prt03'
foreach ($printer in $printers) {
	$printer
	foreach ($cap in $printer.CapabilityDescriptions) {
		$cap
		}
	$printer.CurrentCapabilities = $printer.Capabilities
	$printer.CurrentCapabilities
	
	$printer.Put('CurrentCapabilities',$printer.CurrentCapabilities)
	}
