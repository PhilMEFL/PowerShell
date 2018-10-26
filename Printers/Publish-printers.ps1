$Printers = Get-WmiObject -Class Win32_Printer -ComputerName 's-ci-prtj03'
foreach ($printer in $printers) {
	if ($($printer.Name) -eq 'P-LEX-L00311') {
		"$($printer.Name) - $($printer.Published)"
		$printer.Published = $true
        $printer
		$printer.Put()
		"$printer.Name is now published"
		}
	}
