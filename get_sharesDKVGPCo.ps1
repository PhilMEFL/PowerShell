function display_hash {
	param ($hshTable)
	$txtOut = ''
	
	$hshTable | Out-Host
	$hshTable.get_Keys() | %{
		$txtOut += "`t`t`t{0} : " -f $_
		foreach ($strAcc in $hshTable[$_]) {
			$txtOut += "{0}, " -f $strAcc
			}
		$txtOut = $txtOut.Substring(0,$txtOut.LastIndexOf(',')) + "`r`n"
		}
	$txtOut
	}

function Update-HashTable {
	param ($hshTable, $strKey, $strValue)

	if (!($hshTable.ContainsKey($strKey))) {
		$hshTable.Add($strKey, @())
		}
	$hshTable[$strKey] += $strValue
	$hshTable
	}

function get-permissions {
	param ($objPerms)

	$hshPerm = @{}
	
	$objPerms | %{
		$strUser = if ($_.Trustee.Domain) {
			"{0}\{1}" -f $_.Trustee.Domain,$_.Trustee.Name
			}
		else {
			"{0}" -f $_.Trustee.Name
			}
			
		if ($_.AccessMask -gt 268435450) {
			$strPerm = 'Special permissions'
			}
		else {
			$strPerm = [Security.AccessControl.FileSystemRights] $($_.AccessMask -as [Security.AccessControl.FileSystemRights])
			}
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
	$txtOut = "{0}`r`n" -f $strSRV
	$objShareSec = get-WMIRequest "select * from win32_LogicalShareSecuritySetting" $strSRV 

	if ($objShareSec) {
		if ($objShareSec.GetType().Name.Contains('Object')) {
	    	$objShareSec | %{
				$test = get-WMIRequest "select type from win32_Share where name = '$($_.Name)'" $strSRV 
				if (($test.type -eq 0) -or ($_.name.Contains('$'))) {  # the share is a file share or hidden share
					Add-Member -InputObject $objPerm -MemberType  NoteProperty -Name $_.Name -value @()
					$txtOut += "`t{0}`r`n" -f $_.Name

					$hshSharePerm = get-permissions $_.GetSecurityDescriptor().Descriptor.DACL
					$txtOut += "`t`tShare permissions`r`n"
					$txtOut += display_hash $hshSharePerm
		
					$strPath = (get-wmiRequest "select Path from Win32_Share Where Name = '$($_.Name)'" $_.PSComputerName).Path
					$strPath = $strPath.Replace('\','\\')
					$txtOut += "`t`tNTFS permissions`r`n"
					$SharedNTFSSecs = get-WMIRequest "select * from win32_LogicalFileSecuritySetting Where Path = '$($strPath)'" $strSRV 
					$hshNTPerm = get-permissions $SharedNTFSSecs.GetSecurityDescriptor().Descriptor.DACL
					$txtOut += display_hash $hshNTPerm

					$objPerm.($_.Name) += @{'Share_Permissions' = $hshSharePerm;
											'NTFS_Permissions' = $hshNTPerm}
					}
				}	
			}
		else {
			$txtOut += $objShareSec
			}
		}
	$objPerm
	$txtOut | Out-File $filePath -Append
	}

cls
$filePath = '.\shares.txt'
"Shared Folders permissions" | Out-File $filePath

$hshServers = @{}
$Srvs = get-adcomputer -Filter * -properties * -SearchBase "OU=Domain Controllers,DC=gpco,DC=local"
$Srvs += get-adcomputer -Filter * -properties * -SearchBase "OU=CO_Servers,DC=gpco,DC=local"

$i = 1
$Srvs = $Srvs | where {(!($_.servicePrincipalName -match 'VirtualServer'))} | sort Name 
$Srvs | %{
	Write-Progress -Activity "Getting shared folders" -Status "Processing $($_.Name) (#$($i) of $($Srvs.Count))" -PercentComplete $(($i++ / $Srvs.Count) * 100)

	$hshServers.Add($_.Name, @())
#	$hshServers[$_.Name] += Get-SharePermission $_.Name
	if (Test-Connection($_.Name) -quiet ) {
		Get-SharePermission $_.Name
		}
	else {
		$txtout = $_.Name + ' unreachable' | Out-File $filePath -Append
		}
	}

display_hash $hshServers