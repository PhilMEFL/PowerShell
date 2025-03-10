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

# Set the File Name
$filePath = .\localadmins.csv'

'Server,Status,Error,Local Administrators' | Out-File $filePath

$ADDomain = Get-ADDomain
# Get only Servers located in the SERVERS OU
$strBaseSRV = "OU=SERVERS,OU=_DKV_DEVICES,{0}" -f $ADDomain.DistinguishedName
$i = 1

$colServers = Get-ADComputer -filter * -SearchBase $strBaseSRV -Properties *
$colServers | sort Name | %{
	Write-Progress -Activity "Getting shared folders" -Status "Processing $($_.Name) (#$($i) of $($colServers.Count))" -PercentComplete $(($i++ / $colServers.Count) * 100)

	$strLine = "{0}," -f $_.Name

	Clear-Variable colAdmins -ErrorAction SilentlyContinue 

# Check if the server is online
	 if (!(Test-Connection $_.Name -Count 2 -Quiet)) {
		$strLine += 'Offline,'
		}
	else {
		$strLine += 'Online,'
		$colAdmins = Invoke-Command $_.Name {
 			Param([string]$Name = "Administrators")
		
			net localgroup $Name | where {$_ -AND $_ -notmatch "command completed successfully"} | select -skip 4
			} 
		
		if ($colAdmins.length -gt 0) {
			$colAdmins | %{
				$strLine += ",{0}" -f $_
				}
			}
		else {
			$strLine += 'WinRM cannot complete the operation.'
			}
		}
	$strLine |  Out-File $filePath -Append
	}
