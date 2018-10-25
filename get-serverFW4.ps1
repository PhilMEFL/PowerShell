$arrNoFW4 = @()
function get-WMIRequest ($strQuery,$strComputer) {
	try {
		$ErrorActionPreference = "Stop"; #Make all errors terminating
		$wmiAnswer = get-wmiobject -Query $strQuery -namespace "root\CIMV2" -computername $strComputer
		}
	catch {
		Write-Warning $Error[0].Exception;
		$wmiAnswer = "Unable to query WMI {0} on {1}" -f $strQuery, $strComputer
		}
	finally {
		$ErrorActionPreference = "Continue"; #Reset the error action pref to default
		}
	$wmiAnswer
	}

cls
$ADDomain = Get-ADDomain
# Get only Servers located in the SERVERS OU
$strBaseSRV = "OU=SERVERS,OU=_DKV_DEVICES,{0}" -f $ADDomain.DistinguishedName
$i = 1
$colServers = Get-ADComputer -filter * -SearchBase $strBaseSRV -Properties *
$colServers | sort OperatingSystem | % {
	Write-Progress -Activity "Processing $($_.Name)" -Status "Processing $($_.Name) (#$($i) of $($colServers.Count))" -PercentComplete $($i++ /100 * $colServers.Count)
#	"Server {0} is running {1}" -f $_.Name, $_.OperatingSystem	
	if ($_.OperatingSystem.Contains('2008')) {
		if ($_.IPv4Address) {
			$_.Name + " : " + $_.IPv4Address

		# Checking Framework 4 installation
			[string]$RegPath = "Software\Microsoft\Windows\CurrentVersion\Uninstall"  
			$AccessReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$_.Name)  
			$regkey = $AccessReg.OpenSubKey($RegPath,$True)  
			if (!($regkey.GetSubKeyNames() | Where {$_ -like '*Framework 4*'})) {
				$arrNoFW4 += $_.Name
				}
			}
		}
	}
cls

$arrNoFW4 | sort | Out-File '2008 servers without Framework 4.txt'