
foreach($computer in Get-ADComputers) {
#$computer.cn = 'cohpmartin'
#$computer.operatingSystem = 'Windows 8.1 Pro'
	$computer.cn + " - " + $computer.operatingSystem
	try {
		$currComputer = Get-WmiObject win32_computersystem -ComputerName $computer.cn
		}
	catch {
		$currComputer = ''
		}
	$objComputer = New-Object PsObject -Property @{System = $computer.cn; Model = '{0} {1}' -f $currComputer.Manufacturer, $currComputer.Model ; OS = $computer.operatingSystem}
		
	if (!($objComputer.OS.ToLower().Contains('server'))) {
		$objWMI = Get-WmiObject win32_Product -ComputerName $objComputer.Name | 
#	    	Select Name,Version,PackageName,Installdate,Vendor | 
	    	Select Name,Version | 
    		Sort Installdate -Descending

		$strfile = "{0}\documents\WindowsPowershell\{1}.txt" -f $env:userprofile,$computer.cn
		foreach ($detail in $objWMI) {
			$detail.Name
			$detail.Version
			}
		$objWMI | ft | Out-File $strfile
		
		Get-Content $strfile
		}
	}