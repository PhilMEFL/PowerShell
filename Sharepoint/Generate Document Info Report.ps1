[System.Reflection.Assembly]::Load("Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c")
[System.Reflection.Assembly]::Load("Microsoft.SharePoint.Portal, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c")
[System.Reflection.Assembly]::Load("Microsoft.SharePoint.Publishing, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c")
[System.Reflection.Assembly]::Load("System.Web, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")

function Get-DocInventory([string]$siteUrl) {
	$site = New-Object Microsoft.SharePoint.SPSite $siteUrl
	foreach ($web in $site.AllWebs) {
		if ($web.Url -eq 'http://copsp01/dms/lnb') {
			continue
			}
		foreach ($list in $web.Lists) {
			if ($list.BaseType -ne “DocumentLibrary”) {
				continue
				}

			foreach ($item in $list.Items) {
				$item.Title
				if ( $item.Title -eq 'ARC_ListOfArtefacts') {
					$item
					}
				$data = @{
#					"Site" = $site.Url
					"Web" = $web.Url
					"list" = $list.Title
					"Item ID" = $item.ID
					"Item URL" = $item.Url
					"Item Title" = $item.Title
					"Item Created" = $item["Created"]
					"Item Modified" = $item["Modified"]
					"Created By" = $item["Author"]
					"Modified By" = $item["Editor"]
					"File Size" = $item.File.Length/1KB
#					"File Size (MB)" = $item.File.Length/1MB
					}
				New-Object PSObject -Property $data
				}
			}
		$web.Dispose();
		}
	$site.Dispose()
	}

#Get-DocInventory "http://copsp01" | Out-GridView
Get-DocInventory "http://copsp01" | Export-Csv -NoTypeInformation -Path "c:\Reports\Document_Detail_Report.csv"