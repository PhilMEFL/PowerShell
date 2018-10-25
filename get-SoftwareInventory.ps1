<#

	Script	: Software Inventory 
	Purpose	: List of all software installed on a computer
    Based on the original work by Aman Dhally, posted at
    http://powershell.com/cs/media/p/18510.aspx
    V1 - 8/21/2012 - Aman Dhally
    V2 - 7/17/2013 - Eliminated redundant calls and cleaned up HTML, Bob McCoy

#>
cls
#variables
$DebugPreference = "SilentlyContinue"
$UserName = (Get-Item Env:\USERNAME).Value
$ComputerName = (Get-Item Env:\COMPUTERNAME).Value
$FileName = (Join-Path -Path ((Get-ChildItem Env:\USERPROFILE).value) -ChildPath $ComputerName) + ".html"
$strOutFile = '\\copfps01\it_ops\Marc L\InstalledSoftware.csv'
if (Test-Path $strOutFile) {
	$arrTemp = $strOutFile.split('.')
	$strNew = "{0}{1}.{2}" -f $arrTemp[0], ((Get-Date).AddDays(-1)).toString('yyyyMMdd'), $arrTemp[1] 
	Rename-Item $strOutFile $strNew -Force
	}


# HTML Style
$style = @"
<style>
BODY{background-color:Lavender}
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse}
TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:thistle}
TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:PaleGoldenrod}
</style>
"@

# Remove old report if it exists
if (Test-Path -Path $FileName) {
    Remove-Item $FileName
	Write-Debug "$FileName removed"
	}

$ix = 1

$Srvs = get-adcomputer -Filter * -properties * -SearchBase "OU=Domain Controllers,DC=gpco,DC=local"
$Srvs += get-adcomputer -Filter * -properties * -SearchBase "OU=CO_Servers,DC=gpco,DC=local"

$i = 1
$Srvs = $Srvs | where {(!($_.servicePrincipalName -match 'VirtualServer'))} | sort Name 
'Software Invetory' > $strOutFile
$Srvs | %{
	Write-Progress -Activity "Getting shared folders" -Status "Processing $($_.Name) (#$($i) of $($Srvs.Count))" -PercentComplete $(($i++ / $Srvs.Count) * 100)
	$_.Name >> $strOutFile
# Run command 
	$objWMI = Get-WmiObject win32_Product -ComputerName $_.Name | 
		Select Name,Version,PackageName,Installdate,Vendor | 
		Sort Installdate -Descending 
	$objWMI | %{
		"{0}, {1}, {2}/{3}/{4}" -f$_.Name, $_.Vendor, $_.Installdate.Substring(6,2),$_.Installdate.Substring(4,2),$_.Installdate.Substring(0,4) >> $strOutFile
		}
	}

	
#Get-WmiObject win32_Product -ComputerName $ComputerName | 
#	Select Name,Version,PackageName,Installdate,Vendor | 
#	Sort Installdate -Descending | 
#	%{ $_.installdate = "{0}/{1}/{2}" -f $_.installdate.substring(6,2),$_.installdate.substring(4,2),$_.installdate.substring(0,4) } |
#	ConvertTo-Html -Head "<title>Software Information for $ComputerName</title>`n$style" `
#         -PreContent "<h1>Computer Name: $ComputerName</h1><h2>Software Installed</h2>" `
#         -PostContent "Report generated on $(get-date) by $UserName on computer $ComputerName" |
#	Out-File -FilePath $FileName
#    							 
## View the file 
#	Write-Debug "File saved $FileName"
#	Invoke-Item -Path $FileName 
#
## Finish
#
#