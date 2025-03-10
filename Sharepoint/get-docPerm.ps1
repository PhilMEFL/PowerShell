cls
if (!(Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)) {
	Add-PSSnapin "Microsoft.SharePoint.PowerShell"
	}

$Properties = @{
				SiteUrl = ''
				SiteTitle = ''
				ListTitle = ''
				ObjectType = ''
				ObjectUrl = ''
				ParentGroup = ''
				GroupOwner = ''
				MemberType = ''
				MemberName = ''
				MemberLoginName = ''
				JobTitle = ''
				Department = ''
				RoleDefinitionBindings = ''
				}
$arrPerms = @()
$UserInfoList = ''
$RootWeb = ''
#$ExportFileDirectory = Read-Host "Enter the Directory Path to create permissions export file"
$ExportFileDirectory = 'c:\temp'

function get-SPPerm ($SPObj) {
	function get-RoleAssignments ($roles) {
		$roles | %{
			$arrRoles = @()
			$_.RoleDefinitionBindings | %{
				$arrRoles += $_.Name
				}
			}
		}
	
	$SPObj
	switch ($SPObj.gettype().Name) {
		'SPWeb' {
			if ($SPObj.HasUniqueRoleAssignments) {
				get-RoleAssignments	$SPObj.RoleAssignments
				$Member = $_.Member
				if ($Member.GetType().Name -eq "SPGroup") {
					$objPerm = New-Object -TypeName PSObject -Property $properties
					$objPerm.SiteUrl = $_.Url
					$objPerm.SiteTitle = $_.Title
					$objPerm.ListTitle = "NA"
					$objPerm.ObjectType = "Site"
					$objPerm.ObjectUrl = $_.ServerRelativeUrl
					$objPerm.MemberType = 'SPGroup'
					$objPerm.ParentGroup = $Member.Name
					$objPerm.GroupOwner = $Member.Owner.Name
					$objPerm.MemberName = $Member.Name
					$objPerm.MemberLoginName = $Member.LoginName
					$objPerm.JobTitle = 'NA'
					$objPerm.Department = 'NA'
					$objPerm.RoleDefinitionBindings = $arrRoles -join ","
					}
					}
			elseif ($MemberType -eq "SPUser") {
				$JobTitle="NA"
				$Department="NA"
				try {
					$userinfo = $UserInfoList.GetItemById($_.ID)
					$JobTitle=$userinfo["JobTitle"]
					$Department=$userinfo["Department"]
					}
				catch {
					}
				$permission = New-Object -TypeName PSObject -Property $properties
				$objPerm.SiteUrl = $siteUrl
				$objPerm.SiteTitle = $siteTitle
				$objPerm.ListTitle = "NA"
				$objPerm.ObjectType = "Site"
				$objPerm.MemberType = $MemberType
				$objPerm.ObjectUrl = $siteRelativeUrl
				$objPerm.ParentGroup = "NA"
				$objPerm.GroupOwner = "NA"
				$objPerm.MemberName = $MemberName
				$objPerm.MemberLoginName = $MemberLoginName
				$objPerm.JobTitle = $JobTitle
				$objPerm.Department = $Department
				$objPerm.RoleDefinitionBindings = $arrRoles -join ","
				}
			}
		'SPList' {
			'SPList'
			if ($list.HasUniqueRoleAssignments) {
				$list.RoleAssignments | %{
					$RoleDefinitionBindings = ''
					$_.RoleDefinitionBindings | %{
					$RoleDefinitionBindings += $_.Name
					}
				$MemberName = $_.Member.Name
				$MemberLoginName = $_.Member.LoginName
				$MemberType = $_.Member.GetType().Name
				$JobTitle="NA"
				$Department="NA"
				if ($MemberType -eq "SPUser") {
					try {
						$userinfo = $UserInfoList.GetItemById($_.ID)
						$JobTitle=$userinfo["JobTitle"]
						$Department=$userinfo["Department"]
						}
					catch {
						}
					}
#						$permission = New-Object -TypeName PSObject -Property $properties
#						$permission.SiteUrl = $siteUrl
#						$permission.SiteTitle = $siteTitle
#						$permission.ListTitle = $listTitle
#						$permission.ObjectType = $list.BaseType.ToString()
#						$permission.ObjectUrl = $listUrl
#						$permission.ParentGroup = "NA"
#						$permission.GroupOwner = "NA"
#						$permission.MemberType = $MemberType
#						$permission.MemberName = $MemberName
#						$permission.MemberLoginName = $MemberLoginName
#						$permission.JobTitle = $JobTitle
#						$permission.Department = $Department
#						$permission.RoleDefinitionBindings = $RoleDefinitionBindings -join ","
						$arrPerms += fill-perm $siteTitle
						$arrPerms += $permission
						}
					}

			}
		'SPDocumentLibrary' {
			'SPDocumentLibrary'
			}
		}
	$arrPerms += $objPerm
					
#				switch ($SPObj.gettype().Name) {
#					'SPWeb' {
#						#Expand Groups
#						$SPObj.Groups[$MemberName].Users | %{
#							$JobTitle="NA"
#							$Department="NA"
#							try {
#								$userinfo = $UserInfoList.GetItemById($_.ID)
#								$JobTitle=$userinfo["JobTitle"]
#								$Department=$userinfo["Department"]
#								}
#							catch {
#								}
#							
#							$permission = New-Object -TypeName PSObject -Property $properties
#							$permission.SiteUrl =$siteUrl
#							$permission.SiteTitle = $siteTitle
#							$permission.ListTitle = "NA"
#							$permission.ObjectType = "Site"
#							$permission.ObjectUrl = $siteRelativeUrl
#							$permission.MemberType = "SPGroupMember"
#							$permission.ParentGroup = $MemberName
#							$permission.GroupOwner = $GroupOwner
#							$permission.MemberName = $_.DisplayName
#							$permission.MemberLoginName = $_.UserLogin
#							$permission.JobTitle = $JobTitle
#							$permission.Department = $Department
#							$permission.RoleDefinitionBindings = $arrRoles -join ","
#							$Permissions += $permission
#							}
		}

if (Test-Path $ExportFileDirectory) {
	Get-SPSite | Get-SPWeb -limit ALL | %{
		$web = $_

		#Root Web of the Site Collection
		if ($_.IsRootWeb) {
			$RootSiteTitle = $_.Title
			$RootWeb = $_
			$UserInfoList = $RootWeb.GetList([string]::concat($_.Url,"/_catalogs/users"))
			}

		$siteUrl = $_.Url
		$siteRelativeUrl = $_.ServerRelativeUrl
		
		Write-Host $_.Url -Foregroundcolor 'Red'
		$objPerm = New-Object -TypeName PSObject -Property $properties
		$objPerm.SiteUrl = $_.Url

		$arrPerms += $objPerm
		$siteTitle = $_.Title

		#Get Site Level Permissions if it's unique
		get-SPPerm $_
		#Get all Uniquely secured objects
		$uniqueObjects = $_.GetWebsAndListsWithUniquePermissions()
	
		#Get uniquely secured Lists pertaining to the current site
		$uniqueObjects | ?{$_.WebId -eq $web.Id -and $_.Type -eq "List"} | %{
			$listUrl = ($_.Url)
			$list = $web.GetList($listUrl)
		
			#Exclude internal system lists and check if it has unique permissions
			if (!$list.Hidden) {
				Write-Host $list.Title -Foregroundcolor 'DarkGreen'
				$listTitle = $list.Title
			
				#Check List Permissions
#				get-SPPerm $List
				if ($list.HasUniqueRoleAssignments) {
					$list.RoleAssignments | %{
						$RoleDefinitionBindings = ''
						$_.RoleDefinitionBindings | %{
							$RoleDefinitionBindings += $_.Name
							}
						$MemberName = $_.Member.Name
						$MemberLoginName = $_.Member.LoginName
						$MemberType = $_.Member.GetType().Name
						$JobTitle="NA"
						$Department="NA"
						if ($MemberType -eq "SPUser") {
							try {
								$userinfo = $UserInfoList.GetItemById($_.ID)
								$JobTitle=$userinfo["JobTitle"]
								$Department=$userinfo["Department"]
								}
							catch {
								}
							}
#						$permission = New-Object -TypeName PSObject -Property $properties
#						$permission.SiteUrl = $siteUrl
#						$permission.SiteTitle = $siteTitle
#						$permission.ListTitle = $listTitle
#						$permission.ObjectType = $list.BaseType.ToString()
#						$permission.ObjectUrl = $listUrl
#						$permission.ParentGroup = "NA"
#						$permission.GroupOwner = "NA"
#						$permission.MemberType = $MemberType
#						$permission.MemberName = $MemberName
#						$permission.MemberLoginName = $MemberLoginName
#						$permission.JobTitle = $JobTitle
#						$permission.Department = $Department
#						$permission.RoleDefinitionBindings = $RoleDefinitionBindings -join ","
						$arrPerms += fill-perm $siteTitle
						$arrPerms += $permission
						}
					}
				if ($list.BaseType -eq "DocumentLibrary") {
					#Check All Folders
					$list.Folders | %{
						$folderUrl = $_.Url
#						get-SPPerm $folderUrl
						if ($_.HasUniqueRoleAssignments) {
							$_.RoleAssignments | %{
								$RoleDefinitionBindings = ""
							
								#Get Permission Level against the Permission
								$_.RoleDefinitionBindings | %{
									$RoleDefinitionBindings += $_.Name
									}
								$MemberName = $_.Member.Name
								$MemberLoginName = $_.Member.LoginName
								$MemberType = $_.Member.GetType().Name
								$JobTitle="NA"
								$Department="NA"
								if ($MemberType -eq "SPUser") {
									try {
										$userinfo = $UserInfoList.GetItemById($_.ID)
										$JobTitle=$userinfo["JobTitle"]
										$Department=$userinfo["Department"]
										}
									catch {
										}
									}
								$permission = New-Object -TypeName PSObject -Property $properties
								$permission.SiteUrl =$siteUrl
								$permission.SiteTitle = $siteTitle
								$permission.ListTitle = $listTitle
								$permission.ObjectType = $list.BaseType.ToString()
								$permission.ObjectUrl = $folderUrl
								$permission.MemberType = $MemberType
								$permission.ParentGroup = "NA"
								$permission.GroupOwner = "NA"
								$permission.MemberName = $MemberName
								$permission.MemberLoginName = $MemberLoginName
								$permission.JobTitle = $JobTitle
								$permission.Department = $Department
								$permission.RoleDefinitionBindings = $RoleDefinitionBindings -join ","
								$arrPerms += $permission
								}
							}
					}
					
				#Check All Items
				$list.Items | %{
					$_.File.Url
					$fileUrl = $_.File.Url
					$file = $_.File
#					get-SPPerm $_.file
					if ($_.HasUniqueRoleAssignments) {
						$_.RoleAssignments | %{
							$RoleDefinitionBindings = ""
							$_.RoleDefinitionBindings | %{
								$RoleDefinitionBindings += $_.Name
								}
							$MemberName = $_.Member.Name
							$MemberLoginName = $_.Member.LoginName
							$MemberType = $_.Member.GetType().Name
							$JobTitle="NA"
							$Department="NA"
							if ($MemberType -eq "SPUser") {
								try {
									$userinfo = $UserInfoList.GetItemById($_.ID)
									$JobTitle=$userinfo["JobTitle"]
									$Department=$userinfo["Department"]
									}
								catch {
									}
								}
							$permission = New-Object -TypeName PSObject -Property $properties
							$permission.SiteUrl =$siteUrl
							$permission.SiteTitle = $siteTitle
							$permission.ListTitle = $listTitle
							$permission.ObjectType = $file.GetType().Name
							$permission.ObjectUrl = $fileUrl
							$permission.MemberType=$MemberType
							$permission.MemberName = $MemberName
							$permission.MemberLoginName = $MemberLoginName
							$permission.JobTitle = $JobTitle
							$permission.Department = $Department
							$permission.RoleDefinitionBindings = $RoleDefinitionBindings -join ","
							$arrPerms += $permission
							}
						}
					}
				}
			}
		}
	if (!$_.IsRootWeb) {
		$_.Dispose()
		}
	}
#Dispose root web
$RootWeb.Dispose()

#Stop-SPAssignment $spAssgn

$exportFilePath = Join-Path -Path $ExportFileDirectory -ChildPath $([string]::Concat($RootSiteTitle,"-Permissions.csv"))

$arrPerms | Select SiteUrl,SiteTitle,ObjectType,ObjectUrl,ListTitle,MemberName,MemberLoginName,MemberType,JobTitle,Department,ParentGroup,GroupOwner,RoleDefinitionBindings | Export-CSV -Path $exportFilePath -NoTypeInformation

}
else {
	Write-Host "Invalid directory path:" $ExportFileDirectory -ForegroundColor "Red"
	}