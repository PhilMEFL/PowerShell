$hshPerm = @{'1179817' = 'Read';
			 '1245631' = 'Change';
			 '2032127' = 'FullControl'}

function Update-HashTable {
	param ($hshTable, $strKey, $strValue)

	if (!($hshTable.ContainsKey($strKey))) {
		$hshTable.Add($strKey, @())
		}
	$hshTable[$strKey] += $strValue
	$hshTable
	}

function get-permissions {
	param ($objTBD)

	$hshPerm = @{}
	
	$objTBD | %{
		$strUser = if ($_.Trustee.Domain) {
			"{0}\{1}" -f $_.Trustee.Domain,$_.Trustee.Name
			}
		else {
			"{0}" -f $_.Trustee.Name
			}
		$strPerm = [Security.AccessControl.FileSystemRights] $($_.AccessMask -as [Security.AccessControl.FileSystemRights])
		$hshPerm = Update-HashTable $hshPerm $strPerm $strUser
		}
	$hshPerm
	}
	
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

function Get-SharePermission {
    Param($strSRV = $env:ComputerName)
	
	$objPerm = New-Object System.Management.Automation.PSObject

	$objShareSec = Get-WMIObject win32_LogicalShareSecuritySetting -comp $strSRV -ErrorAction Ignore
    
    $objShareSec | %{
		Add-Member -InputObject $objPerm -MemberType  NoteProperty -Name $_.Name -value @()
		$strPath = (get-wmiRequest "select Path from Win32_Share Where Name = '$($_.Name)'" $_.PSComputerName).Path
		$strPath = [regex]::Escape($strPath)

		$SharedNTFSSecs = Get-WmiObject -Class Win32_LogicalFileSecuritySetting -Filter "Path='$strPath'" -ComputerName $strSRV -ErrorAction SilentlyContinue
		$hshNTPerm = get-permissions $SharedNTFSSecs.GetSecurityDescriptor().Descriptor.DACL

		$hshSharePerm = get-permissions $_.GetSecurityDescriptor().Descriptor.DACL
		$objPerm.($_.Name) += @{'Share_Permissions' = $hshSharePerm;
								'NTFS_Permissions' = $hshNTPerm}
		}
	$objPerm
	}

cls
$hshServers = @{}
$ADDomain = Get-ADDomain
# Get only Servers located in the SERVERS OU
$strBaseSRV = "OU=SERVERS,OU=_DKV_DEVICES,{0}" -f $ADDomain.DistinguishedName
$colServers = Get-ADComputer -filter * -SearchBase $strBaseSRV -Properties *

Get-SharePermission DKVACCSRVM003 | gm | Export-Csv c:\temp\shares.csv

#$colServers | %{
#	$hshServers.Add($_.Name, @())
#	$hshServers[$_.Name] += Get-SharePermission $_.Name
#	$hshServers[$_.Name]
#	}
	
