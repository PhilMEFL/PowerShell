function new-xElement {
	param (	[Xml]$xml,
			[string]$strElName,
			[string]$strAttrib)
			
	$xeElem = $xml.CreateElement($strElName)
	$xeElem.SetAttribute('Name', $strAttrib)
	,$xeElem
	}
	
function add-XML {
	param (	[xml]$xml,
			[string]$strElem)

	$xeNew = $xml.CreateElement($strElem)
	$xeNew.create
	$xml.AppendChild($xeNew)
	#,$xml.OuterXml
	,$xml
	}

function read-XML {
	param ($xml)
	
	$xml.ChildNodes | % {
		"{0}: {1}" -f $_.LocalName, $_.Name;
		if ($_.HasChildNodes) {
			read-XML $_
			}
		}
	}

Function Get-Accounts {
	param  ([string]$StrAccount,
			[string]$strComputer,
			[System.Xml.XmlLinkedNode]$xeParent)

	$arrMembers = @()
	if ($StrAccount.Contains('GPCO\')) {
		$StrAccount = $StrAccount.Substring($StrAccount.indexof('\') + 1)

		Get-ADObject -LDAPFilter "(samaccountname=$StrAccount)" -SearchBase 'DC=gpco,DC=local' | %{
			$objAD = $_
			switch ($objAD.objectClass) {
				'group' {
					$arrMembers = ((Get-ADGroupMember $objAD.Name).SID).Value
					}
				'user' {
					$arrMembers += ((Get-ADUser $objAD.DistinguishedName).SID).Value
					}
				'computer' {
					$arrMembers += ((Get-ADComputer $objAD.DistinguishedName).SID).Value
					}
				}
			}
			
		get-Names $StrAccount $arrMembers $xeParent
		}
	else {
		$StrAccount = if ($StrAccount.contains('BUILTIN')) {
						$StrAccount.replace('BUILTIN\','')
						} 
					elseif ($StrAccount.contains('NT AUTHORITY')) {
						$StrAccount.replace('NT AUTHORITY','')
						}
					elseif ($StrAccount.contains('NT SERVICE')) {
						$StrAccount.replace('NT SERVICE','')
						}
					else {
						$StrAccount
						}

		Get-LocalAccount $StrAccount $strComputer $xeParent
		}

	,$xeParent
	}

function get-Names ($strName, $arrMembers, $xeParent) {

	$xeMembers = $xml.CreateElement('Members')
	$xeMembers.SetAttribute('Name', $strName)
	for ($i = 0; $i -lt $arrMembers.count; $i++) {
		$objAD = Get-ADObject -LDAPFilter "(objectSID=$($arrMembers[$i]))" -SearchBase 'DC=gpco,DC=local'
		$xeTemp = $xml.CreateElement($objAD.objectClass)
		switch ($objAD.objectClass) {
			'group' {
				$xeTemp.SetAttribute('Name',$objAD.Name)
				Get-Names $objAD.Name ((Get-ADGroupMember $objAD.Name).SID).Value $xeTemp
				}	
			'user' {
				$objAD = get-ADUser $arrmembers[$i] 
				$strUser = if (!($objAD.Enabled)) {
					' (disabled)'
					}
				$strUser = "{0}{1}" -f $objAD.Name, $strUser
				$xeTemp.SetAttribute('Name', $strUser)
				}
			'computer' {
				$objAD = get-ADComputer $arrmembers[$i] 
				$xeTemp.SetAttribute('Name', $objAD.Name)
				}
			}
		$xeMembers.AppendChild($xeTemp)
		}
	if ($xeParent.get_Name() -eq 'group') {
		$xeMembers.user | %{
			$xeTemp = $xml.CreateElement($objAD.objectClass)
			$xeTemp.SetAttribute('Name', $_.Name)
			$xeParent.AppendChild($xeTemp)
			}
		}
	else {
		$xeParent.AppendChild($xeMembers)
		}
	}

Function Get-LocalAccount {
	param  ([string]$StrUser,
			[string]$strComputer,
			[System.Xml.XmlLinkedNode]$xeParent)

	$xeMembers = $xml.CreateElement('LocalMembers')
	"Checking local perms for {0} on {1}." -f $StrUser, $strComputer | Out-Host

	$StrUser | %{
		$wmiGroup = get-WMIRequest "select * from Win32_Group where Name = '$strUser'" $strComputer
		if ($wmiGroup) {
			$wmiUsers = get-WMIRequest "select * from win32_groupuser where GroupComponent = `"Win32_Group.Domain='$($StrComputer)'`,Name='$($wmiGroup.name)'`"" $strComputer 
			$wmiUsers | %{
				$strAcc = ($_.PartComponent.replace("Domain=",",").replace(",Name=","\").replace("\\",",").replace('"','').split(","))[2]
				if ($_.PartComponent.Contains('Group')) {
					$xeTemp = $xml.CreateElement($strAcc.Substring($strAcc.IndexOf('\') + 1).Replace(' ','_'))
					Get-Accounts $strAcc '' $xeTemp
					}
				else {
					$xeTemp = $xml.CreateElement('User')
					$xeTemp.SetAttribute('Name', $strAcc)
					}
				$xeMembers.AppendChild($xeTemp)
				}
			}
		else {
			$xeMembers.SetAttribute('Name', $strUser)
			}
		}
	$xeParent.AppendChild($xeMembers)
	}

function get-permissions {
	param (	[Object]$objShare,
			[System.Xml.XmlLinkedNode]$xeParent)

	$objShare | %{
		$strServer = $_.PSComputerName
		$xeSharePerm = if ($_.__CLASS -eq 'Win32_LogicalShareSecuritySetting') {
				$xml.CreateElement('SharePerms')
				}
			else {
				$xml.CreateElement('FSPerms')
				}				
		$_.GetSecurityDescriptor().Descriptor.DACL | %{
			$strAccount = if ($_.Trustee.Domain) {
				"{0}\{1}" -f $_.Trustee.Domain,$_.Trustee.Name
				}
			else {
				"{0}" -f $_.Trustee.Name
				}
		
		Get-Accounts $StrAccount $strServer $xeSharePerm

		if ($_.AccessMask -gt 268435450) {
			$strPerm = 'Special permissions'
			}
		else {
			$strPerm = [Security.AccessControl.FileSystemRights] $($_.AccessMask -as [Security.AccessControl.FileSystemRights])
			}
		
			$xeSharePerm.SetAttribute('Name', $strPerm)
			$xeParent.AppendChild($xeSharePerm)	
			}
		}
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
    Param(	$strSRV = $env:ComputerName,
			[System.Xml.XmlLinkedNode]$xeParent)
	
	$wmiShareSecurity = get-WMIRequest "select * from win32_LogicalShareSecuritySetting" $strSRV
	$wmiShareSecurity | %{
		if (($_.GetType().Name.Contains('Object')) -and ($_.Name -ne 'print$')) {
#		if ($_.GetType().Name.Contains('Object')) {
			$xeShare = new-xElement $xml 'Share' $_.Name
			get-permissions $_ $xeShare
			$strPath = (get-wmiRequest "select Path from Win32_Share Where Name = '$($_.Name)'" $_.PSComputerName).Path

			$SharedNTFSSecs = get-WMIRequest "select * from win32_LogicalFileSecuritySetting Where Path = '$($strPath.Replace('\','\\'))'" $strSRV 
			get-permissions $SharedNTFSSecs $xeShare
			}
		else {
			$xeShare = $xml.CreateElement('Nothing')
#			$xeShare.SetAttribute('Name','No share')
			}
		$xeParent.AppendChild($xeShare)	
		}

	}

cls
#		$ErrorActionPreference = "Stop"; #Make all errors terminating
#$ShareType = @{
#    			0 = 'Disk Drive'
#    			1 = 'Print Queue'
#    			2 = 'Device'
#    			3 = 'IPC'
#  				2147483648 = 'Disk Drive Admin'
#  				2147483649 = 'Print Queue Admin'
#  				2147483650 = 'Device Admin'
#  				2147483651 = 'IPC Admin'
#				}
#
#$filePath = '.\shares.txt'
#"Shared Folders permissions" | Out-File $filePath
#
$xml = New-Object xml 
$xml.LoadXml("<?xml version='1.0' encoding='utf-8'?><GPCoShares></GPCoShares>")

$ix = 1

$Srvs = get-adcomputer -Filter * -properties * -SearchBase "OU=Domain Controllers,DC=gpco,DC=local"
$Srvs += get-adcomputer -Filter * -properties * -SearchBase "OU=CO_Servers,DC=gpco,DC=local"

$i = 1
$Srvs = $Srvs | where {(!($_.servicePrincipalName -match 'VirtualServer'))} | sort Name 
$Srvs | %{
	Write-Progress -Activity "Getting shared folders" -Status "Processing $($_.Name) (#$($i) of $($Srvs.Count))" -PercentComplete $(($i++ / $Srvs.Count) * 100)
#	$xeServer = new-xElement $xml 'Server' $_.Name
	$xeServer = $xml.CreateElement($_.Name)
	if (Test-Connection($_.Name) -quiet ) {
		Get-SharePermission $_.Name $xeServer
#		$xeServer.OuterXml		
#		$xeServer = add-xElement $xeShare $xeServer
		}
	else {
		Update-HashTable $hshServers $_.Name 'Not responding'
		}
	$xml.FirstChild.NextSibling.AppendChild($xeServer)
	}
cls
$xml.Save('SharePerm2.xml')
read-XML $xml