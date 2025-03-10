Import-Module ActiveDirectory
#
# Add the SQL Server Provider.
#

$ErrorActionPreference = "Stop"

$sqlpsreg="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps120.sqlps"

if (Get-ChildItem $sqlpsreg -ErrorAction "SilentlyContinue")
{
    throw "SQL Server Provider for Windows PowerShell is not installed."
}
else
{
    $item = Get-ItemProperty $sqlpsreg
    $sqlpsPath = [System.IO.Path]::GetDirectoryName($item.Path)
}


#
# Set mandatory variables for the SQL Server provider
#
Set-Variable -scope Global -name SqlServerMaximumChildItems -Value 0
Set-Variable -scope Global -name SqlServerConnectionTimeout -Value 30
Set-Variable -scope Global -name SqlServerIncludeSystemObjects -Value $false
Set-Variable -scope Global -name SqlServerMaximumTabCompletion -Value 1000

#
# Load the snapins, type data, format data
#
Push-Location
cd $sqlpsPath
Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100
Update-TypeData -PrependPath SQLProvider.Types.ps1xml 
update-FormatData -prependpath SQLProvider.Format.ps1xml 
Pop-Location
# Test to see if the SQLPS module is loaded, and if not, load it
if (!(Get-Module -name 'SQLPS')) {
	if (Get-Module -ListAvailable | Where-Object {$_.Name -eq 'SQLPS'}) {
		Push-Location # The SQLPS module load changes location to the Provider, so save the current location
		Import-Module -Name 'SQLPS' -DisableNameChecking
		Pop-Location # Now go back to the original location
		}
	}

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo");

# —————————————————————————
# Name:   Invoke-Ternary
# Alias:  ?:
# Author: Karl Prosser
# Desc:   Similar to the C# ? : operator e.g.
#            _name = (value != null) ? String.Empty : value;
# Usage:  1..10 | ?: {$_ -gt 5} {“Greater than 5;$_} {“Not greater than 5″;$_}
# —————————————————————————
set-alias ?: Invoke-Ternary -Option AllScope -Description “PSCX filter alias”
filter Invoke-Ternary ([scriptblock]$decider, [scriptblock]$ifTrue, [scriptblock]$ifFalse) {
	if (&$decider) { 
		&$ifTrue
   		}
	else { 
		&$ifFalse 
		}
	}

function SendMail {
	$smtpServer = 'copexc01'
	$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
	$emailFrom = 'support@gpco.be'
	$subject = 'Email Subject'
	foreach ($line in Get-Content 'D:\Scripts\lowdisk.txt') {
		$body += '$line `n'
		}
	$smtp.Send($EmailFrom,'support@gpco.be',$subject,$body)
	$body = ''
	}

Function format-DiskSize() {
	[cmdletbinding()]
		Param ([long]$Type)

	If ($Type -ge 1TB) {
		[string]::Format("{0:0.00} TB", $Type / 1TB)
		}
	ElseIf ($Type -ge 1GB) {
		[string]::Format("{0:0.00} GB", $Type / 1GB)
		}
	ElseIf ($Type -ge 1MB) {
		[string]::Format("{0:0.00} MB", $Type / 1MB)
		}
	ElseIf (
		$Type -ge 1KB) {[string]::Format("{0:0.00} KB", $Type / 1KB)
		}
	ElseIf ($Type -gt 0) {
		[string]::Format("{0:0.00} Bytes", $Type)
		}
	Else {
		""
		}
	} # End of function

cls
New-PSDrive -Name DM -Root SQLSERVER:\SQL\localhost\DEFAULT\Databases\Disks_Mgmt -PSProvider SQLSERVER
$strOutFile = 'C:\Temp\Report.txt'
#if (Test-Path $strOutFile) {
#	$arrTemp = $strOutFile.split('.')
#	$strNew = "{0}{1}.{2}" -f $arrTemp[0], ((Get-Date).AddDays(-1)).toString('yyyyMMdd'), $arrTemp[1] 
#	Rename-Item $strOutFile $strNew -Force
#	}
$HTMLTitle = "{0}'s servers daily report on {1}" -f $env:USERDOMAIN, (Get-Date).toShortDateString() | Out-File $strOutFile -Append
$sqlConnect.Open()
$i = 1
$Srvs = get-adcomputer -Filter * -properties * -SearchBase "OU=Domain Controllers,DC=gpco,DC=local"
$Srvs += get-adcomputer -Filter * -properties * -SearchBase "OU=CO_Servers,DC=gpco,DC=local"

$Srvs = $Srvs | where {(!($_.servicePrincipalName -match 'VirtualServer'))} | sort Name 
$Srvs | %{
	$strServer = $_.Name
	Write-Progress -Activity "Collecting info on server $($strServer)" -status "Processing server $($StrServer) #$i of $($Srvs.count)" -percentComplete ($i / $Srvs.count*100)
	if (Test-Connection($strServer) -quiet ) {
		$wmiDrives = Get-WmiObject -ComputerName $strServer Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
		$strDisk = "{0} disk{1}" -f ($wmiDrives.count | ?: {$_} {$wmiDrives.count} {1}), ($wmiDrives.count | ?: {$_-gt 1} {'s'} {''})
		$wmiDrives
		
		$slqCommand = $sqlConnect.CreateCommand()
		$slqCommand.CommandText = "SELECT * FROM servers WHERE name = '{0}'" -f $strServer
		$gnurf = $slqCommand.ExecuteReader()
$gnurf
$table = new-object “System.Data.DataTable”
$table.Load($gnurf)	
		$slqCommand.CommandText = " IF NOT EXISTS (SELECT name FROM servers WHERE name = '{0}')
									INSERT INTO servers (name, disks) VALUES('{0}','{1}');" -f $strServer, $wmiDrives.count
		$slqCommand.CommandText
		$gnurf = $slqCommand.ExecuteReader()
$gnurf
		$sqladapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $slqCommand

		$dataset = New-Object -TypeName System.Data.DataSet 
		$sqladapter.Fill($dataset) 
	    $dataset.Tables[0] 
		
		for ($i = 0; $i -lt $wmiDrives.Count; $i++) {
			$slqCommand.CommandText = "INSERT INTO disks (name, volume, size, Server_ID) VALUES('{0}','{1}','{2}');" -f $wmiDrives[$i].DeviceID, $wmiDrives[$i].VolumeName, $wmiDrives[$i].Size, 1
			$slqCommand.CommandText
			}

#		"<asp:Table runat='server' ID=$strTBL>" | Out-File $strOutFile -Append
# 		"<asp:TableHeaderRow runat='server' TableSection='TableHeader' CssClass='$strCss'>
#			<asp:TableHeaderCell>$strServer</asp:TableHeaderCell>
#			<asp:TableHeaderCell>$strDisk</asp:TableHeaderCell>
#			<asp:TableHeaderCell>$strStatus</asp:TableHeaderCell>
#			<asp:TableHeaderCell>&nbsp</asp:TableHeaderCell>
#		</asp:TableHeaderRow>
#
#		<asp:TableRow runat='server'>
#				<asp:TableCell runat='server'>Drive</asp:TableCell>
#				<asp:TableCell runat='server'>Capacity</asp:TableCell>
#				<asp:TableCell runat='server'>Used Space</asp:TableCell>
#				<asp:TableCell runat='server'>% Free</asp:TableCell>  
#			</asp:TableRow>" | Out-File $strOutFile -Append
#		$wmiDrives | %{
#			$numFree = ($_.FreeSpace / $_.Size * 100)
#			$strCss = ''
#			if ($numFree -lt 10) {
#				$strCss = 'error'
#				}
#			elseif ($numFree -lt 25) {
#				$strCss = 'warning'
#				}
#			"<asp:TableRow CssClass='$strCss'>
#				<asp:TableCell>{0}</asp:TableCell>
#				<asp:TableCell>{1}</asp:TableCell>
#				<asp:TableCell>{2}</asp:TableCell>
#				<asp:TableCell>{3:N2}%</asp:TableCell>
#			</asp:TableRow>" -f $_.DeviceID, (format-DiskSize($_.Size)), (format-DiskSize($_.FreeSpace)), ($_.FreeSpace / $_.Size * 100) | Out-File $strOutFile -Append
#			}
#		if (!($strStatus -eq 'ok')) {
#    		"<asp:TableRow runat='server' CssClass='hidden'>
#					<asp:TableCell runat='server'>TimeCreated</asp:TableCell>
#					<asp:TableCell runat='server'>Id</asp:TableCell>
#					<asp:TableCell runat='server'>LevelDisplayName</asp:TableCell>
#					<asp:TableCell runat='server'>Message</asp:TableCell>  
#				</asp:TableRow>" | Out-File $strOutFile -Append
#			$objError | %{
#				$strCss = $_.LevelDisplayName.ToLower()
#				"<asp:TableRow CssClass='hidden'>
#					<asp:TableCell>{0}</asp:TableCell>
#					<asp:TableCell>{1}</asp:TableCell>
#					<asp:TableCell>{2}</asp:TableCell>
#					<asp:TableCell>{3}</asp:TableCell>
#				</asp:TableRow>" -f $_.TimeCreated, $_.ID, $_.LevelDisplayName, $_.Message | Out-File $strOutFile -Append
#				}
##		$strErrors =  $objError | Out-string
#			}
	#			send-mailmessage -to "Notifications@gpco.be" -from "Philippe.martin@gpco.be" -subject $strSubject -Body $strErrors -SmtpServer copexc01
			}
	else {
		"<asp:Table runat='server' ID=$strTBL>
			<asp:TableHeaderRow CSSClass='unreach'>
				<asp:TableCell runat='server'>$strServer unreachable</asp:TableCell>
			</asp:TableHeaderRow>" | Out-File $strOutFile -Append
		}
	'</asp:Table>' | Out-File $strOutFile -Append
	$i++
	}

'</asp:Content>' | Out-File $strOutFile -Append
#$strOutFile | ConvertTo-Html -Head $HTMLheader -body $HTMLTitle #| Out-File c:\Temp\serverReport.html
Invoke-Expression $strOutFile
