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
$filePath = "C:\temp\localadmins.xml"

# Create The Document
$xmlDoc  = new-object xml

$ADDomain = Get-ADDomain
# Get only Servers located in the SERVERS OU
$strBaseSRV = "OU=SERVERS,OU=_DKV_DEVICES,{0}" -f $ADDomain.DistinguishedName
$i = 1

$xElement = $xmldoc.CreateElement('Servers')
$xmlDoc.AppendChild($xElement) | Out-Null
$xmlServers = $xmlDoc.SelectSingleNode('Servers')

$colServers = Get-ADComputer -filter * -SearchBase $strBaseSRV -Properties *
$colServers | sort Name | %{
	Write-Progress -Activity "Getting shared folders" -Status "Processing $($_.Name) (#$($i) of $($colServers.Count))" -PercentComplete $(($i++ / $colServers.Count) * 100)

	# Write the Document
	$xeServer = $xmldoc.CreateElement($_.Name)
	$xmlServers.AppendChild($xeServer) | Out-Null
	$xeServer = $xmlServers.SelectSingleNode($_.Name)

	Clear-Variable colAdmins -ErrorAction SilentlyContinue 

# Check if the server is online
	if (!(Test-Connection $_.Name -Count 2 -Quiet)) {
		$xeServer.SetAttribute('Status','Offline')
		}
	else {
		$xeServer.SetAttribute('Status','Online')

		# Getting local administrators
		$xeAdmins = $xmlDoc.CreateElement('LocalAdministrators')
		$xeServer.AppendChild($xeAdmins) | Out-Null
		$xeAdmins = $xeServer.SelectSingleNode('LocalAdministrators')

		$colAdmins = Invoke-Command $_.Name {
 			Param([string]$Name = "Administrators")
		
			net localgroup $Name | where {$_ -AND $_ -notmatch "command completed successfully"} | select -skip 4
			} 
		
		if ($colAdmins.length -gt 0) {
			$colAdmins | %{
				$xeValue = $xmlDoc.CreateElement('Member')
				$xeValue.Set_InnerText($_)
				$xeAdmins.AppendChild($xeValue) | Out-Null
				}
			}
		else {
			$xeValue = $xmlDoc.CreateElement('Error')
			$xeValue.Set_InnerText('WinRM cannot complete the operation.')
			$xeAdmins.AppendChild($xeValue) | Out-Null
			}
		$xeServer.AppendChild($xeAdmins)
		$xmlDoc.LastChild.AppendChild($xeServer) | Out-Null
		}
	}
	
$xmlDoc.Save($filePath)

$tata = 'toto'