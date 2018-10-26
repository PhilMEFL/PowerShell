$hash06 = @{}
'Getting printers on s-ci-prt02'
$printers02 = Get-WmiObject -Query "select * from Win32_Printer" -ComputerName 's-ci-prt02' | Sort-Object Name
'Getting printers on s-ci-prt06'
$printers06 = Get-WmiObject -Query "select * from Win32_Printer" -ComputerName 's-ci-prt06' | Sort-Object Name
foreach ($printer in $printers06) {
	$hash06.add($printer.Name,'s-ci-prt06')
	}
$i = 1
foreach ($printer in $printers02) {
	if ($printer.name -eq 'P-B-28.00.008.LEX') {
		$tata = 'toto'
		}
	if (!($hash06[$($printer.Name)] -eq 's-ci-prt06')) {
		if (!($printer.Name.EndsWith(' Shadow'))) {
			$printer.Name
			$i++
			}
		}
	}
"There are $i missing printers on s-ci-prt06"