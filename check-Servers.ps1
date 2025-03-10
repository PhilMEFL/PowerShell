function Get-SharePerm ($Shares) {
	$arrShare = @()
	foreach ($Share in $Shares) { 
		$SecurityDescriptor = $Share.GetSecurityDescriptor() 
		$objShare = "" | Select Name, Perm
		$objShare.Name = $Share.Name
		$objShare.Perm = @()
		foreach ($DACL in $SecurityDescriptor.Descriptor.DACL) { 
			$objPerm = "" | Select Domain, ID, AccessMask, AceType 
			$objPerm.Domain = $DACL.Trustee.Domain
			$objPerm.ID = $DACL.Trustee.Name 
			Switch ($DACL.AccessMask) { 
				2032127 {$AccessMask = "FullControl"} 
				1179785 {$AccessMask = "Read"} 
				1180063 {$AccessMask = "Read, Write"} 
				1179817 {$AccessMask = "ReadAndExecute"} 
				-1610612736 {$AccessMask = "ReadAndExecuteExtended"}
				1245631 {$AccessMask = "ReadAndExecute, Modify, Write"}
				1180095 {$AccessMask = "ReadAndExecute, Write"}
				268435456 {$AccessMask = "FullControl (Sub Only)"}
				default {$AccessMask = $DACL.AccessMask} 
				} 
			$objPerm.AccessMask = $AccessMask 
			Switch ($DACL.AceType) { 
				0 {$AceType = "Allow"} 
				1 {$AceType = "Deny"} 
				2 {$AceType = "Audit"} 
				}
			$objPerm.AceType = $AceType 
			Clear-Variable AccessMask -ErrorAction SilentlyContinue 
			Clear-Variable AceType -ErrorAction SilentlyContinue 
			$objShare.Perm += $objPerm 
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

$NOFW4 = @()
$olSRVs = @()
$arrADSrv = @()
# Objects creation
$objUpdSess = New-Object -ComObject 'Microsoft.Update.Session'
#	$objUpdSess.ClientApplicationID = 'MSDN PowerShell Sample'
$UpdSrch = $objUpdSess.CreateUpdateSearcher()
$UpdResult = $UpdSrch.Search("IsInstalled=0 and Type='Software' and IsHidden=0")

$ADDomain = Get-ADDomain

# Get only Servers
$colServers = Get-ADComputer -LDAPFilter '(OperatingSystem=*Server*)' -Properties * | sort Name

$i = 1
$colServers | % {
	Write-Progress -Activity "Processing $($_.Name)" -Status "Processing $($_.Name) (#$($i) of $($colServers.Count))" -PercentComplete $(($i++ / $colServers.Count) * 100)

#	if ([int] $_.Name.Substring($_.Name.Length-3) -ge 26) {
#	convertTo-HTML ID, @{Label="AppPoolName";Expression={ '&lt;a href="http://powershell.com/requests.ps1x?PID=$($_.PID)&amp;AppPoolName=$($_.AppPoolName)"&gt;$($_.AppPoolName)&lt;/a&gt;' }, @{Label="CPU(s)";Expression={if ($_.CPU -ne $()) {$_.CPU.ToString("N")}}}, @{Label="Virtual Memory";Expression={[int]($_.VM/1MB)}}, @{Label="Physical Memory";Expression={[int]($_.WS/1024)}} | Out-file test.html
	$objSrv = New-Object -TypeName System.Object 
	Add-Member -inputObject $objSrv -MemberType NoteProperty -Name 'ServerName' -Value $_.Name
	Add-Member -inputObject $objSrv -MemberType NoteProperty -Name 'O.S.' -Value $_.OperatingSystem
	Add-Member -inputObject $objSrv -MemberType NoteProperty -Name 'SP' -Value (&{if(!($_.OperatingSystemServicePack)) {'N/A'} else {$_.OperatingSystemServicePack}})
	Add-Member -inputObject $objSrv -MemberType NoteProperty -Name 'IPv4' -Value $_.IPv4Address
#	Add-Member -inputObject $objSrv -MemberType NoteProperty -Name 'Server' -Value $_
	
# Check if the server is online
	if (Test-Connection $_.Name -Count 2 -Quiet) {
		$strStatus = 'Online'
		
# check UAC state
		$regHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $_.Name)
		$regKey = $regHKLM.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\policies\system')
       	if (($regKey.GetValue('ConsentPromptBehaviorAdmin') -eq 0) -and ($regKey.GetValue('PromptOnSecureDesktop') -eq 0)) {
            $strSUACtatus = 'OK'
            }
        else {
            $strSUACtatus = 'UAC on'
            }
		Add-Member -inputObject $objSrv -MemberType NoteProperty -Name 'UAC' -Value $strSUACtatus
            

#		try {
#			$ErrorActionPreference = "Stop"; #Make all errors terminating
# 			Test-WSMan -ComputerName $_.Name
# 			$strStatus += ' - Remote Manageable'
#			}
# 		catch{ 
#			$strStatus += $_.Exception.Message
#			}
#		finally {
#			$ErrorActionPreference = " continue"
#			}
		Add-Member -inputObject $objSrv -MemberType NoteProperty -Name 'Status' -Value $strStatus

		# Getting pending updates
		
$ScriptBlock = {
    $hash=@{}
    $Session = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $hash[$_.Name] = $Searcher.QueryHistory(1,1) | select -ExpandProperty Date
    $hash
	}

Invoke-Command -ComputerName $_.Name -ScriptBlock $ScriptBlock
		
		
#		$objUpdates = get-wulist -computerName $_.Name
#		try {
#			$objUpdates = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$_.Name))
#			$updSearch = $objUpdates.CreateUpdateSearcher()
#			$updavail = $updSearch.Search("IsInstalled=0").Updates
#			}
#		catch {
#			$updavail = 'Unable to get pending updates'
#			Write-Warning "$($Error[0])" 
#			} 
	 	Add-Member -inputObject $objSrv -MemberType NoteProperty -Name "Updates" -Value $objUpdates.count

		$displayGB = (get-WMIRequest 'select * from Win32_ComputerSystem' $_.Name)
		if (!($displayGB.TotalPhysicalMemory.getType().Name -eq 'String')) {
			$displayGB = "{0} GB" -f [math]::round($displayGB.TotalPhysicalMemory/1024/1024/1024, 0)
			}
		
		Add-Member -inputObject $objSrv -MemberType NoteProperty -Name "Memory" -Value $displayGB
		
#		# Getting shares (on servers supporting WMI requests
#		$colFW4 = get-wmiRequest 'select * from Win32_Product where caption like "%Framework 4%"' $_.Name
#		if (($colFW4.Count -eq 2) -or ($_.OperatingSystem.Contains('2008'))) {
#			$colFW4 = 'OK'
#			}
#		Add-Member -InputObject $objSrv -MemberType NoteProperty -Name 'FW 4' -Value $colFW4

		# Getting shares (on servers supporting WMI requests
		$colShares = get-wmiRequest 'select * from Win32_LogicalShareSecuritySetting' $_.Name
		$colSharPerm = Get-SharePerm $colShares
#		forea {ch ($i in $test) { 
#			$i.Name
#			foreach ($j in $i.Perm) {
#				"{0}\{1}:{2}"-f $j.Domain,$j.ID,$j.AccessMask
#				}
#			}
 		#Add-Member -inputObject $objSrv -MemberType NoteProperty -Name 'Shares' -Value $colSharPerm
		}
	else {
		Add-Member -inputObject $objSrv -MemberType NoteProperty -Name 'Status' -Value 'offline'
		}
	
	$arrADSrv += $objSrv
	}
#	}
if ($env:COMPUTERNAME -ne 'COHPMARTIN') {
    $arrADSrv | ConvertTo-HTML | Out-File C:\Temp\GPCOservers.htm
    Invoke-Item  C:\Temp\GPCOservers.htm
    }
else {
    $arrADSrv | ConvertTo-HTML | Out-File C:\Users\pmartin\OneDrive\IGT\GPCO\GPCOservers.htm
    Invoke-Item  C:\Users\pmartin\OneDrive\IGT\GPCO\GPCOservers.htm
    }
#| ft | Out-File 'servers.txt'