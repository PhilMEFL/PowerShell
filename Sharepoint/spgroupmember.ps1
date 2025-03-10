if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin Microsoft.SharePoint.PowerShell
    }

$SPFile = "{0}\Documents\GetGroupInformation.txt" -f $env:HOMEPath
#$SPSiteUrl = Read-Host "Enter the Url of the Site Collection "
$SPSiteUrl = 'https://portallnb.gpcocat.be'
$SPSite = Get-SPSite $SPSiteUrl -ErrorAction SilentlyContinue
if($SPSite -ne $null) {
    $SPSite.AllWebs | %{
		$strWeb = "'{0}' contains the following groups" -f $_.Title
        Write-Output $strWeb #| Out-File $SPFile -append
        Write-Output "========================"#| Out-File $SPFile -append
        $_.Groups | %{
			$strGroup = "`t{0}: {1}" -f $_.Name, $_.Roles.Name
			$strGroup
            Write-Output $strGroup #| Out-File $SPFile -append
            if ($_.Users.count) {
				$_.Users | %{
					$strUser = "`t`t{0}" -f $_.Name
                	Write-Output $strUser #| Out-File $SPFile -append
					}
                }
			else {
				$strUser = "`t`tNo member"
                Write-Output $strUser #| Out-File $SPFile -append
				}
            }

        Write-Output "========================"#| Out-File $SPFile -append
        }
    }
else {
    Write-Host "Requested Site Could Not be found"  -ForegroundColor DarkRed
    }