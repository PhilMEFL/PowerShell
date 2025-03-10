function create-xmlChild($xItem, $strChild) {
	$xTmp = $xItem
	while ($xTmp.NodeType -ne 'Document') {
		$xTmp = $xTmp.ParentNode
		}
	$xeTemp = $xTmp.CreateElement($strChild)
	$xTmp.OuterXML | Out-Host
	if ($xItem.HasChildNodes) {
		$xItem.get_LastChild().AppendChild($xeTemp) | Out-Null
		}
	else {
		$xItem.AppendChild($xeTemp) | Out-Null
		}
	$xItem.OuterXMl | Out-Host
	$xetest = $xeTemp.SelectSingleNode($strChild)
	$xeTemp
	}

function Get-SharePerm ($Shares) {
	$arrShare = @()

	foreach ($Share in $Shares) {
		$hshPerm = 	@{	'FullControl' = @();
						'Read' = @(); 
						'Read, Write' = @();
						'ReadAndExecute' = @();
						'ReadAndExecuteExtended' = @();
						'ReadAndExecute, Modify, Write' = @();
						'ReadAndExecute, Write' = @();
						'FullControl (Sub Only)' = @()
						}

		$objShare = New-Object PSobject
		Add-Member -InputObject $objShare -MemberType NoteProperty -Name 'Name' -Value $Share.Name
		
		$SecurityDescriptor = $Share.GetSecurityDescriptor() 
		foreach ($DACL in $SecurityDescriptor.Descriptor.DACL) { 
			$objPerm = "" | Select User, AccessMask, AceType 
			
			$objPerm.AccessMask = Switch ($DACL.AccessMask) { 
				2032127 {"FullControl"} 
				1179785 {"Read"} 
				1180063 {"Read, Write"} 
				1179817 {"ReadAndExecute"} 
				-1610612736 {"ReadAndExecuteExtended"}
				1245631 {"ReadAndExecute, Modify, Write"}
				1180095 {"ReadAndExecute, Write"}
				268435456 {"FullControl (Sub Only)"}
				default {$DACL.AccessMask} 
				} 

			if ($DACL.Trustee.Domain) {
				$objPerm.User = "{0}\{1}" -f $DACL.Trustee.Domain,$DACL.Trustee.Name
				}
			else {
				$objPerm.User = "{0}" -f $DACL.Trustee.Name
				}

			$hshPerm[$objPerm.AccessMask] += $objPerm.User

			$objPerm.AceType = Switch ($DACL.AceType) { 
				0 {'Allow'} 
				1 {'Deny'} 
				2 {'Audit'} 
				}

			Clear-Variable AccessMask -ErrorAction SilentlyContinue 
			Clear-Variable AceType -ErrorAction SilentlyContinue
			if (!($objShare | gm $objPerm.AccessMask)) {
				Add-Member -InputObject $objShare @{$objPerm.AccessMask = $objPerm.User}
				}
			else {
				$objShare 
				}
			} 
		$arrShare += $objShare
		}
	$arrShare
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

cls

$arrXMLbad = '\x09,\x0A,\x0D,\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}'
$hshPerm = 	@{	'Full Control' = @();
				'Read' = @(); 
				'Read, Write' = @();
				'Read And Execute' = @();
				'Read And Execute Extended' = @();
				'Read And Execute, Modify, Write' = @();
				'Read And Execute, Write' = @();
				'FullControl (Sub Only)' = @()
				}
$hshServers = @{}
$objServer = New-Object PSObject -Property @{            
        Server	= $svr            
        Status	= ''                 
        Shares	= ''           
        UserName         = $user.name            
        CreateDate       = $CreateDate            
        DateLastModified = $DateLastModified            
        AsymMetricKey    = $user.AsymMetricKey            
        DefaultSchema    = $user.DefaultSchema            
        HasDBAccess      = $user.HasDBAccess            
        ID               = $user.ID            
        LoginType        = $user.LoginType            
        Login            = $user.Login            
        Orphan           = ($user.Login -eq "")  
		}

# Set the File Name
$strOutFile = "{0}\Shares.xml" -f $MyInvocation.MyCommand.path.toString().substring(0,$MyInvocation.MyCommand.path.toString().LastIndexOf('\'))

# Create The Document
$xmlDoc  = new-object xml

$ADDomain = Get-ADDomain
# Get only Servers located in the SERVERS OU
$strBaseSRV = "OU=SERVERS,OU=_DKV_DEVICES,{0}" -f $ADDomain.DistinguishedName
$i = 1

$xmlServers = create-xmlChild $xmlDoc 'Servers'

$colServers = Get-ADComputer -filter * -SearchBase $strBaseSRV -Properties *
$colServers | sort Name | %{
	$_.Name
#	Write-Progress -Activity "Getting shared folders" -Status "Processing $($_.Name) (#$($i) of $($colServers.Count))" -PercentComplete $(($i++ / $colServers.Count) * 100)

	$hshServers.Add($_.Name,$objServer)
	# Write the Document
	$xeServer = create-xmlChild $xmlDoc "$($_.Name)"

	Clear-Variable colShares -ErrorAction SilentlyContinue 

# Check if the server is online
	if (!(Test-Connection $_.Name -Count 2 -Quiet)) {
		$hshServers[$_.Name].Status = 'Offline'
		}
	else {
		$hshServers[$_.Name].Status = 'Online'

		# Getting shares (on servers supporting WMI requests
		$colSec = get-wmiRequest 'select * from Win32_LogicalShareSecuritySetting' $_.Name

		$hshServers[$_.Name].Shares = $colSec.Name
		
		$colSec | % {
			$_.Name
			$colPath = get-wmiRequest "select Path from Win32_Share Where Name = '$($_.Name)'" $_.PSComputerName
			$objShare = "$colSec.{0}" -f $_.Name
			$_.Name = $_.Name.replace('$','_HIDDEN')
			$xeShares = create-xmlChild $xeServer 'Shares'
			$xeShares.set_InnerText($_.Name)
			
			$SecurityDescriptor = $_.GetSecurityDescriptor() 
			foreach ($DACL in $SecurityDescriptor.Descriptor.DACL) { 
				$objPerm = "" | Select User, AccessMask, AceType
	
				$objPerm.AccessMask = Switch ($DACL.AccessMask) { 
					2032127 {"Full Control"} 
					1179785 {"Read"} 
					1180063 {"Read, Write"} 
					1179817 {"Read And Execute"} 
					-1610612736 {"Read And Execute Extended"}
					1245631 {"Read And Execute, Modify, Write"}
					1180095 {"Read And Execute, Write"}
					268435456 {"Full Control (Sub Only)"}
					default {$DACL.AccessMask} 
					} 

				if ($DACL.Trustee.Domain) {
					$objPerm.User = "{0}\{1}" -f $DACL.Trustee.Domain,$DACL.Trustee.Name
					}
				else {
					$objPerm.User = "{0}" -f $DACL.Trustee.Name
					}
				
				$xeSharPerm =  create-xmlChild $xeServer 'SharePerm'
				if (!($xeSharPerm.OuterXml.Contains($objPerm.AccessMask))) {
					$xeSharPerm.set_InnerText($objPerm.AccessMask)
					}

				$xtUser = $xmlDoc.CreateTextNode($objPerm.User)
				$xePerm.AppendChild($xtUser) | Out-Null
#				if ($xePerm.get_InnerText()) {
#					$xePerm.set_InnerXml("<{0}>`r`n<{1}>" -f $xePerm.get_InnerText(),$xtUser.Value)
#					}
#				else {
#					$xePerm.set_InnerXml("<{0}>" -f $xtUser.Value)
#					}
				$xePerm.OuterXml

#				$objPerm.AceType = Switch ($DACL.AceType) { 
#					0 {'Allow'} 
#					1 {'Deny'} 
#					2 {'Audit'} 
#					}
			$xeShare.AppendChild($xePerm) | Out-Null
			}
		$xmlDoc.LastChild.AppendChild($xeServer) | Out-Null
		}
	}
	$xmlDoc.Save($strOutFile)
	}

$xmlDoc.Save($strOutFile)

#$t = [xml](new-object system.net.webclient).downloadstring($strOutFile)
#
#[System.Xml.XmlDocument] $xmlDoc = new-object System.Xml.XmlDocument
#$file = resolve-path($strOutFile)
#$xmlDoc.load($file)
#
#$xmlDoc.SelectNodes('Servers/Server') | % {
#	"{0} is {1}" -f $_.Name ,$_.Status
#	if ($_.Status -eq 'online') {
#		$_.Shares.Name
#		$_.Shares.SelectNodes('Permissions') | % {
#			for ($i = 0; $i -lt $_.user.count; $i++) {
#				$_.user[$i] + ": " + $_.permission[$i]
#				}
#			}
#		}
#	'---'
#	}