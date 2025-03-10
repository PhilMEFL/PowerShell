if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin Microsoft.SharePoint.PowerShell
    }

function Get-SiteCollectionGroups {
    Param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		[string]$outputFullFilePath = 'C:\Temp\groupPerms.txt',
		[Parameter(Mandatory=$false)]
		[switch]$selectSites,
		[Parameter(Mandatory=$false)]
		[char]$csvSeparator = ';',
		[Parameter(Mandatory=$false)]
		[char]$internalSeparator = ','
		)
	
	Write-Host "Collecting site collection groups";
	$arrSite = @();
	$arrSiteGroups = @();
	$sites = Get-SPWeb -Site http://localhost

	[int]$intCount = 1;
	[int]$total = $sites.Count;
	[string]$intCountFormat = "0" * $total.ToString().Length;
	foreach ($site in $sites) {
		Write-Host -BackgroundColor green -ForegroundColor black 'WEB: ' $Site
		"{0}/{1} [{2}]:" -f $intCount,$total,$Site
 		foreach ($group in $Site.SiteGroups) {
            if ($group.Title) {
                $group.title
                }
            [string]$groupUsers = "";
			$group.Users | %{
				$groupUsers += "{0}$($internalSeparator)" -f $_.DisplayName
				}
			if ($groupUsers -match "$($internalSeparator)$") {
				$groupUsers = $groupUsers.Substring(0, $groupUsers.Length - 1)
				}
				
			[string]$groupRoles = "";
			$group.Roles | %{
#				$_
				$groupRoles += "{0}$($internalSeparator)" -f $_.Name
				}
			if ($groupRoles -match "$($internalSeparator)$") {
				$groupRoles = $groupRoles.Substring(0, $groupRoles.Length-1);
				}
			if ($group.Roles.count) {
				$tata = 'toto'
				}
#			"Roles: " + $groupRoles
			$Group | Add-Member -MemberType NoteProperty -Name "SiteCollectionUrl" -Value $Site.Url
			$Group | Add-Member -MemberType NoteProperty -Name "GroupOwner" -Value $Group.Owner.DisplayName
			$Group | Add-Member -MemberType NoteProperty -Name "GroupUsers" -Value $GroupUsers
			$Group | Add-Member -MemberType NoteProperty -Name "GroupRoles" -Value $groupRoles
			$arrSiteGroups += $Group;
            }
#		$site.lists | %{
#	  		if ($_.HasUniqueRoleAssignments) {
##				"`tList: {0}" -f $_.Title #| Out-File $strOutFile -Append 
#				Write-Host -BackgroundColor yellow -ForegroundColor black "`tList: " $_.RootFolder
##				$list.RoleAssignments | %{"`t{0}" -f $_.Member }
##				$list.RoleAssignments | %{"`t`t{0}" -f $_.Member | out-file $strOutFile -append}
##				foreach ($item in $_.Items) {
##					Write-Host -BackgroundColor Red -ForegroundColor Black "`tItem: " $item.Name
##					if ($item.HasUniqueRoleAssignments) {
###						"`t`tItem: {0}" -f $item.Name # | Out-File $strOutFile -Append 
##						Write-Host -BackgroundColor red -ForegroundColor yellow "`tItem: " $item.Name
##						$item.RoleAssignments | %{"`t´t{0}" -f $_ }
##						#| out-file $strOutFile -append}
##						}
##					}
#				}
#			}
		$intCount++
		Write-Host "$($Site.Lists.Count) groups are successfully collected"
		$tata = 'toto'
        }
	$Site | Add-Member -MemberType NoteProperty -Name "SiteCollectionUrl" -Value $Site.Url
	$Site | Add-Member -MemberType NoteProperty -Name "Groupekess" -Value $arrSiteGroups
	$arrSite += $site
#	}
    $arrSiteGroups | %{
        $_.SiteCollectionUrl 
        $_ | Export-Csv -Path $outputFullFilePath -Delimiter $csvSeparator -NoTypeInformation
	$arrSiteGroups | Select LoginName, GroupOwner, GroupUsers, GroupRoles | Export-Csv -Path $outputFullFilePath -Delimiter $csvSeparator -NoTypeInformation
        }


#    $arrsite | select SiteCollectionUrl, Groupekess 
#	| Export-Csv -Path $outputFullFilePath -Delimiter $csvSeparator -NoTypeInformation
#	| Select SiteCollectionUrl,LoginName,Title,Owner,OwnerTitle,GroupUsers,GroupRoles | Export-Csv -Path $outputFullFilePath -Delimiter $csvSeparator -NoTypeInformation
    Write-Host "Site collection groups are collected and written to $outputFullFilePath"
}

cls
Get-SiteCollectionGroups C:\Temp\groupPerms.txt