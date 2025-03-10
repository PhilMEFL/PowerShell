# Variables
$siteUrl = 'http://cocsp02'
$groupName = 'IGT Members'
$groupDescription = "Members of this group can contribute to the Finance site."

# Load the SharePoint PowerShell snap-in
Write-Host "Loading SharePoint PowerShell snap-in..." 
Add-PSSnapin "Microsoft.SharePoint.PowerShell"
Write-Host "Done"
Write-Host

Write-Host "Creating site members group..."
$web = Get-SPWeb $siteUrl
$web.SiteGroups.Add($groupName, $web.CurrentUser, $web.CurrentUser, $groupDescription)
$membersGroup = $web.SiteGroups[$groupName]
$web.AssociatedMembersGroup = $membersGroup

Write-Host "Granting contribute permissions to group..."
$membersGroupAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($membersGroup)
$membersRoleDef = $web.RoleDefinitions["Contribute"]
$membersGroupAssignment.RoleDefinitionBindings.Add($membersRoleDef)
$web.RoleAssignments.Add($membersGroupAssignment)
$membersGroup.Update()

Write-Host "Adding members of Managers OU to the SharePoint group..."
$adUsers = Get-ADUser -Filter * -Searchbase "OU=Managers,DC=contoso,DC=net"
foreach($adUser in $adUsers)
{
   Write-Host "...adding user $(adUser.UserPrincipalName) ..." -ForegroundColor Gray
   $user = $web.EnsureUser($adUser.UserPrincipalName)
   $membersGroup.AddUser($user)
}
$web.Update()
$web.Dispose()

Write-Host "Finished." -ForegroundColor Green
