Import-Module ActiveDirectory

function SendMail {
	$smtpServer = 'copexc01'
	$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
	$emailFrom = 'support@gpco.be'
	$subject = “Email Subject”
	foreach ($line in Get-Content “D:\Scripts\lowdisk.txt”) {
		$body += “$line `n”
		}
	$smtp.Send($EmailFrom,'support@gpco.be',$subject,$body)
	$body = “”
	}

Function Format-DiskSize() {
Param ([decimal]$Type)
If ($Type -ge 1TB) {[string]::Format("{0:0} TB", $Type / 1TB)}
ElseIf ($Type -ge 1GB) {[string]::Format("{0:0} GB", $Type / 1GB)}
ElseIf ($Type -ge 1MB) {[string]::Format("{0:0} MB", $Type / 1MB)}
ElseIf ($Type -ge 1KB) {[string]::Format("{0:0} KB", $Type / 1KB)}
ElseIf ($Type -gt 0) {[string]::Format("{0:0} Bytes", $Type)}
Else {""}
} # End of Function Format-DiskSize

format-diskSize 14392569695

$strOutFile = 'C:\TempIn\Report.htm'
#$strOutFile = 'C:\Users\pmartin\OneDrive\IGT\GPCO\Projects\GPCOReports\Report.aspx'
#$strOutFile = '\\copwa01\ServersReport\Default.aspx'
if (Test-Path $strOutFile) {
	$arrTemp = $strOutFile.split('.')
	$strNew = "{0}{1}.{2}" -f $arrTemp[0], ((Get-Date).AddDays(-1)).toString('yyyyMMdd'), $arrTemp[1] 
	Rename-Item $strOutFile $strNew -Force
	}
 
$HTMLTitle = "<h1>{0}'s servers disks usage on {1}</h1>" -f $env:USERDOMAIN, (Get-Date).toShortDateString() | Out-File $strOutFile

$i = 1
$Srvs = get-adcomputer -Filter * -properties * -SearchBase "OU=Domain Controllers,DC=gpco,DC=local"
$Srvs += get-adcomputer -Filter * -properties * -SearchBase "OU=CO_Servers,DC=gpco,DC=local"

$Srvs | sort Name| % {
	if (!($_.servicePrincipalName -match 'VirtualServer')) {
		$strServer = $_.Name
		Write-Progress -Activity "Collecting info on server $($strServer)" -status "Processing server $($StrServer) #$i of $($Srvs.count)" -percentComplete ($i / $Srvs.count*100)
		if (Test-Connection($strServer)-quiet ) {
		"<h2>$strServer</h2>" | Out-File $strOutFile -Append
			$drives = Get-WmiObject -ComputerName $strServer Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | %{
				"{0} is {1:2} with {2:N2} % free {3:N2} %<p>" -f  $_.deviceID, (format-DiskSize $_.Size), (format-DiskSize $_.FreeSpace), ($_.FreeSpace / $_.Size * 100) | Out-File $strOutFile -Append
				}
			}
		else {
			"<h2 class='unreach'>$strServer" + ' unreachable' + '</h2>' | Out-File $strOutFile -Append
			}
		$i++
		}
	}
	
'</asp:Content>' | Out-File $strOutFile -Append
#$strOutFile | ConvertTo-Html -Head $HTMLheader -body $HTMLTitle #| Out-File c:\Temp\serverReport.html
Invoke-Expression $strOutFile
