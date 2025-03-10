Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

function expand-RoleAssignments($spras, $intLoop) {
	$tab = "`t"
	for ($i = 1; $i -le $intLoop; $i++) {
		$tab += $tab
		}
		
    $spras | %{
		"{0}Member {1}: " -f $tab, $_.Member.ToString() #| out-file $strOutFile -append
		$_.RoleDefinitionBindings | %{
			"{0} {1}" -f $tab, $_.Name
			"{0} {1}" -f $tab, $_.Name | out-file $strOutFile -append
			}
		}
    } 

cls
#Start-SPAssignment -global    
$sites = Get-SPsite -limit All
$strOutFile = "C:\Reports\perm_{0}.txt" -f $sites.Url[0].Substring($sites.Url[0].IndexOf('//') + 2)
New-Item -Path $strOutFile -type file -Force | Out-Null

foreach ($site in $sites) {
	$Site.SiteGroups.Name
	foreach ($web in $site.allwebs) {
		Write-Host -BackgroundColor green -ForegroundColor black 'WEB: ' $web.Title
		"Web: {0}" -f $web.Title | Out-File $strOutFile -Append #-NoNewline
        expand-RoleAssignments $web.RoleAssignments 1

		foreach ($list in $web.lists) {
			$list.RootFolder.SubFolders | %{
				$_.Name
				$_.item
				if ($_.Item.ContentType.Name -eq "TestDocSet") {
					$_.Name
					$_.Files | %{
						$_.Name
						$_.HasUniqueRoleAssignments
						}
					}
				}
					
			if ($list.HasUniqueRoleAssignments) {
				"`t`t`tList: {0}" -f $list.Title | Out-File $strOutFile -Append 
				Write-Host -BackgroundColor yellow -ForegroundColor black "`tList: " $list.Title
                expand-RoleAssignments $list.RoleAssignments 2
#				$list.RoleAssignments | %{"`t`t`t`t{0}" -f $_.Member }
#				$list.RoleAssignments | %{"`t`t`t`t{0}" -f $_.Member | out-file $strOutFile -append}
				foreach ($item in $list.Items) {
					if ($item.HasUniqueRoleAssignments) {
						"`t`tItem: {0}" -f $item.Name | Out-File $strOutFile -Append 

						Write-Host -BackgroundColor red -ForegroundColor yellow "`tItem: " $item.Name
						$item.Fields['Distribution'].DefaultValueType
                        expand-RoleAssignments $item.RoleAssignments 3
#						$item.RoleAssignments | %{
#                           $_
#                            "`t`t`t`t`t`t{0}" -f $_.Member | out-file $strOutFile -append
#                            }
						}
					}
				}
			}
		}
	}

#Stop-SPAssignment -global

