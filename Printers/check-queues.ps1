function isNumeric ($x){
	try {
		0 + $x | Out-Null
		return $true
		} 
	catch {
		return $false    
		}
	}

'Getting printers on s-ci-prt06'
$printers06 = Get-WmiObject -Query "select * from Win32_Printer" -ComputerName 's-ci-prt06' | Sort-Object Name
foreach ($printer in $printers06) {
	if (!($printer.Name.Contains('Shadow'))) {
		$tmp = $printer.Name.Split('.')
		if ($tmp.length -gt 4) {
			if (!(isNumeric($tmp[4]))) {
				'Old name : ' + $printer.Name
				$printer.Name = "$($tmp[0]).$($tmp[1]).$($tmp[2]).$($tmp[4])"
				if ($tmp.Length -eq 6) {
					$printer.Name = "$($printer.Name).$($tmp[5])"
					}
				'New name : ' + $printer.Name
				$printer
				}
			}
		}
	}
