#[System.Reflection.Assembly]::Load("Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c")
#[System.Reflection.Assembly]::Load("Microsoft.SharePoint.Portal, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c")
#[System.Reflection.Assembly]::Load("Microsoft.SharePoint.Publishing, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c")
#[System.Reflection.Assembly]::Load("System.Web, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
cls
Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue

$hshLists = @{
	'Quality Management' = 'Quality Owners','Quality Members'
	'Operations Management' = 'Operations Owners','Operations Members'
	'PMO' = 'PMO Owners','PMO Members'
	'Security Management' = 'Security Owners','Security Members'
	'Architecture' = 'Architecture Owners','Architecture Members'
	'Governance' = 'Governance Owners','Governance Members'
	'Bid' = 'Bid Owners','Bid Members','Bid Visitors'
#	'Calendar' = ('Security Owners','Security Members');
	}

function Get-DocInventory([string]$siteUrl) {
	$site = New-Object Microsoft.SharePoint.SPSite $siteUrl

	$web = Get-SPWeb -Identity $siteUrl
	
	$web.Lists | %{
		$_
		}

	foreach ($list in $web.Lists) {
		$list.title
#		if ($list.Title -ne 'Quality Management') {
#			continue
#			}
#		if ($list.BaseType -ne “DocumentLibrary”) {
#			continue
#			}


# documents ditribution all = shared with LNB

		$intItems = $list.items.count
		for ($i = 0; $i -le $intItems; $i++) {
			$document = $list.items[$i]

			"{0}: Distribution: {1} Level: {2}" -f $document.Name, $document.Properties.get_Item('Distribution'), $document.level
			if (($document.level -eq 'Published') -and ($document.Properties.get_Item('Distribution') -eq 'All')){
				$document.HasUniqueRoleAssignments# -eq $FALSE
				$document.RoleAssignments | %{
					$_.Member.Name 
					if ($_.Member.Name -eq 'LNB Members') {
						$_.RoleDefinitionBindings.remove($web.RoleDefinitions['Open WebParts'])
						$_.RoleDefinitionBindings.add($web.RoleDefinitions['Read'])
						$_.RoleDefinitionBindings | %{
							$_.Name
							}
						}
					}
				#$document.update()
				}
			}
		$tata = ''
		}
	$web.Dispose();
	$site.Dispose()
	}

#Get-DocInventory "http://copsp01n/dms/operations" #| Out-GridView
Get-DocInventory "http://cocsp02" | Export-Csv -NoTypeInformation -Path "c:\temp\Document_Detail_Report_IT.csv"

