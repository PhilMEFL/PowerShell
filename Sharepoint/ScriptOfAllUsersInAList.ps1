Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
$WebUrl = Read-Host 'Please input URL address of target web'
$Web = Get-SPWeb $WebUrl
$ListName = Read-Host 'Please input list/library name'
$List = $web.Lists[$ListName]
$lists.Title
$flag = $false
$count = 0

$Unique = $List.hasuniqueroleassignments 
if (($List.permissions -ne $null) -and ($Unique -eq "True")) 	{
	Write-Output "---------------------"
	Write-Output "Does not inherit permission"
	}
elseif ($Unique -ne "True") { 
	Write-Output "Inherits permissions from $Web" 
	}

foreach($roleAssignment in $List.RoleAssignments) {
	foreach($group in $web.SiteGroups) {
	if ($roleAssignment.member.name -eq $group) {
		foreach($roleDefinition in $roleAssignment.RoleDefinitionBindings) {
			if(($roleDefinition.Name -eq "Full Control") -or ($roleDefinition.Name -eq "Contribute") -or ($roleDefinition.Name -eq "Design") -or ($roleDefinition.Name -eq "Approve")) {
				$flag= "True"
				write-host "Group Name: "$roleAssignment.member.name "...."
				write-host -foregroundcolor red "Permission Name: "$roleDefinition.Name "..."
				foreach($user in $group.Users) {
					write-host -foregroundcolor green "Users In this group: "$user.Name"..."
					$count = $count+1
					}     
				}
			}
		}
	}
	if( $flag -eq "False") {
		foreach($roleDefinition in $roleAssignment.RoleDefinitionBindings) {
			if(($roleDefinition.Name -eq "Full Control") -or ($roleDefinition.Name -eq "Contribute") -or ($roleDefinition.Name -eq "Design") -or ($roleDefinition.Name -eq "Approve")) {
				write-host "Member Name: "$roleAssignment.member.name "...."
				write-host -foregroundcolor red "Permission Name: "$roleDefinition.Name "..."
				$count= $count+1
				}
			}
	}
	$flag= "False"        
} 
write-host "total user count in this list/library with edit permission is : " $count

Write-Host "----------------------" 
$web.dispose()