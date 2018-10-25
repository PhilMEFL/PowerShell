Function Get-OSInfo {
    param ([String]$ComputerName = '.')

    $infos = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName
	if ($infos) {
    	$infos | Select-Object -property @{Name='ComputerName'; Expression = {$_.Csname}},
                                     @{Name='OS'; Expression = {$_.caption}},
#                                     @{Name='ServicePack'; Expression = {$_.csdversion}},
                                     @{Name='InstallationDate'; Expression ={[system.Management.ManagementDateTimeConverter]::ToDateTime($_.Installdate)}}
		}
	else {
		$infos = $ComputerName
		}
	$infos
	}
	
Get-Content u:\Martin\NoWinRM.txt | %{
#	$_
	Get-OSInfo $_
	}
