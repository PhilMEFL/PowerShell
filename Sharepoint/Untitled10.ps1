if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {

Add-PSSnapin "Microsoft.SharePoint.PowerShell"

}

$properties=@{SiteUrl='';SiteTitle='';ListTitle='';ObjectType='';ObjectUrl='';ParentGroup='';GroupOwner='';MemberType='';MemberName='';MemberLoginName='';JobTitle='';Department='';RoleDefinitionBindings='';};

$Permissions=@();

$UserInfoList="";

$RootWeb="";

$SiteCollectionUrl = Read-Host "Enter a Site Collection Url";

$ExportFileDirectory = Read-Host "Enter the Directory Path to create permissions export file";

if(Test-Path $ExportFileDirectory){

$spAssgn = Start-SPAssignment;

Get-SPSite $SiteCollectionUrl -AssignmentCollection $spAssgn|Get-SPWeb -limit ALL -AssignmentCollection $spAssgn|%{

$web = $_;

#Root Web of the Site Collection

if($web.IsRootWeb -eq $True){

$RootSiteTitle = $web.Title;

$RootWeb = $web;

$UserInfoList = $RootWeb.GetList([string]::concat($web.Url,"/_catalogs/users"));

}

$siteUrl = $web.Url;

$siteRelativeUrl = $web.ServerRelativeUrl;

Write-Host $siteUrl -Foregroundcolor "Red";

$siteTitle = $web.Title;

#Get Site Level Permissions if it's unique

if($web.HasUniqueRoleAssignments -eq $True){

$web.RoleAssignments|%{

$RoleDefinitionBindings=@();

$_.RoleDefinitionBindings|%{

$RoleDefinitionBindings += $_.Name;

}

$MemberName = $_.Member.Name;

$MemberLoginName = $_.Member.LoginName;

$MemberType = $_.Member.GetType().Name;

$GroupOwner = $_.Member.Owner.Name;

if($MemberType -eq "SPGroup"){

$JobTitle="NA";

$Department="NA";

$permission = New-Object -TypeName PSObject -Property $properties;

$permission.SiteUrl =$siteUrl;

$permission.SiteTitle = $siteTitle;

$permission.ListTitle = "NA";

$permission.ObjectType = "Site";

$permission.ObjectUrl = $siteRelativeUrl;

$permission.MemberType = $MemberType;

$permission.ParentGroup = $MemberName;

$permission.GroupOwner = $GroupOwner;

$permission.MemberName = $MemberName;

$permission.MemberLoginName = $MemberLoginName;

$permission.JobTitle = $JobTitle;

$permission.Department = $Department;

$permission.RoleDefinitionBindings = $RoleDefinitionBindings -join ",";

$Permissions +=$permission;

#Expand Groups

$web.Groups[$MemberName].Users|%{

$JobTitle="NA";

$Department="NA";

try{

$userinfo = $UserInfoList.GetItemById($_.ID);

$JobTitle=$userinfo["JobTitle"];

$Department=$userinfo["Department"];

}

catch{

}

$permission = New-Object -TypeName PSObject -Property $properties;

$permission.SiteUrl =$siteUrl;

$permission.SiteTitle = $siteTitle;

$permission.ListTitle = "NA";

$permission.ObjectType = "Site";

$permission.ObjectUrl = $siteRelativeUrl;

$permission.MemberType = "SPGroupMember";

$permission.ParentGroup = $MemberName;

$permission.GroupOwner = $GroupOwner;

$permission.MemberName = $_.DisplayName;

$permission.MemberLoginName = $_.UserLogin;

$permission.JobTitle = $JobTitle;

$permission.Department = $Department;

$permission.RoleDefinitionBindings = $RoleDefinitionBindings -join ",";

$Permissions +=$permission;

}

}

elseif($MemberType -eq "SPUser"){

$JobTitle="NA";

$Department="NA";

try{

$userinfo = $UserInfoList.GetItemById($_.ID);

$JobTitle=$userinfo["JobTitle"];

$Department=$userinfo["Department"];

}

catch{

}

$permission = New-Object -TypeName PSObject -Property $properties;

$permission.SiteUrl =$siteUrl;

$permission.SiteTitle = $siteTitle;

$permission.ListTitle = "NA";

$permission.ObjectType = "Site";

$permission.MemberType = $MemberType;

$permission.ObjectUrl = $siteRelativeUrl;

$permission.ParentGroup = "NA";

$permission.GroupOwner = "NA";

$permission.MemberName = $MemberName;

$permission.MemberLoginName = $MemberLoginName;

$permission.JobTitle = $JobTitle;

$permission.Department = $Department;

$permission.RoleDefinitionBindings = $RoleDefinitionBindings -join ",";

$Permissions +=$permission;

}

}

}

#Get all Uniquely secured objects

$uniqueObjects = $web.GetWebsAndListsWithUniquePermissions();

#Get uniquely secured Lists pertaining to the current site

$uniqueObjects|?{$_.WebId -eq $web.Id -and $_.Type -eq "List"}|%{

$listUrl = ($_.Url);

$list = $web.GetList($listUrl);

#Exclude internal system lists and check if it has unique permissions

if($list.Hidden -ne $True){

Write-Host $list.Title -Foregroundcolor "Yellow";

$listTitle = $list.Title;

#Check List Permissions

if($list.HasUniqueRoleAssignments -eq $True){

$list.RoleAssignments|%{

$RoleDefinitionBindings="";

$_.RoleDefinitionBindings|%{

$RoleDefinitionBindings += $_.Name;

}

$MemberName = $_.Member.Name;

$MemberLoginName = $_.Member.LoginName;

$MemberType = $_.Member.GetType().Name;

$JobTitle="NA";

$Department="NA";

if($MemberType -eq "SPUser"){

try{

$userinfo = $UserInfoList.GetItemById($_.ID);

$JobTitle=$userinfo["JobTitle"];

$Department=$userinfo["Department"];

}

catch{

}

}

$permission = New-Object -TypeName PSObject -Property $properties;

$permission.SiteUrl =$siteUrl;

$permission.SiteTitle = $siteTitle;

$permission.ListTitle = $listTitle;

$permission.ObjectType = $list.BaseType.ToString();

$permission.ObjectUrl = $listUrl;

$permission.ParentGroup = "NA";

$permission.GroupOwner = "NA";

$permission.MemberType=$MemberType;

$permission.MemberName = $MemberName;

$permission.MemberLoginName = $MemberLoginName;

$permission.JobTitle = $JobTitle;

$permission.Department = $Department;

$permission.RoleDefinitionBindings = $RoleDefinitionBindings -join ",";

$Permissions +=$permission;

}

}

if($list.BaseType -eq "DocumentLibrary"){

#Check All Folders

$list.Folders|%{

$folderUrl = $_.Url;

if($_.HasUniqueRoleAssignments -eq $True){

$_.RoleAssignments|%{

$RoleDefinitionBindings="";

#Get Permission Level against the Permission

$_.RoleDefinitionBindings|%{

$RoleDefinitionBindings += $_.Name;

}

$MemberName = $_.Member.Name;

$MemberLoginName = $_.Member.LoginName;

$MemberType = $_.Member.GetType().Name;

$JobTitle="NA";

$Department="NA";

if($MemberType -eq "SPUser"){

try{

$userinfo = $UserInfoList.GetItemById($_.ID);

$JobTitle=$userinfo["JobTitle"];

$Department=$userinfo["Department"];

}

catch{

}

}

$permission = New-Object -TypeName PSObject -Property $properties;

$permission.SiteUrl =$siteUrl;

$permission.SiteTitle = $siteTitle;

$permission.ListTitle = $listTitle;

$permission.ObjectType = $list.BaseType.ToString();

$permission.ObjectUrl = $folderUrl;

$permission.MemberType = $MemberType;

$permission.ParentGroup = "NA";

$permission.GroupOwner = "NA";

$permission.MemberName = $MemberName;

$permission.MemberLoginName = $MemberLoginName;

$permission.JobTitle = $JobTitle;

$permission.Department = $Department;

$permission.RoleDefinitionBindings = $RoleDefinitionBindings -join ",";

$Permissions +=$permission;

}

}

}

#Check All Items

$list.Items|%{

$fileUrl = $_.File.Url;

$file=$_.File;

if($_.HasUniqueRoleAssignments -eq $True){

$_.RoleAssignments|%{

$RoleDefinitionBindings="";

$_.RoleDefinitionBindings|%{

$RoleDefinitionBindings += $_.Name;

}

$MemberName = $_.Member.Name;

$MemberLoginName = $_.Member.LoginName;

$MemberType = $_.Member.GetType().Name;

$JobTitle="NA";

$Department="NA";

if($MemberType -eq "SPUser"){

try{

$userinfo = $UserInfoList.GetItemById($_.ID);

$JobTitle=$userinfo["JobTitle"];

$Department=$userinfo["Department"];

}

catch{

}

}

$permission = New-Object -TypeName PSObject -Property $properties;

$permission.SiteUrl =$siteUrl;

$permission.SiteTitle = $siteTitle;

$permission.ListTitle = $listTitle;

$permission.ObjectType = $file.GetType().Name;

$permission.ObjectUrl = $fileUrl;

$permission.MemberType=$MemberType;

$permission.MemberName = $MemberName;

$permission.MemberLoginName = $MemberLoginName;

$permission.JobTitle = $JobTitle;

$permission.Department = $Department;

$permission.RoleDefinitionBindings = $RoleDefinitionBindings -join ",";

$Permissions +=$permission;

}

}

}

}

}

}

if($_.IsRootWeb -ne $True){

$_.Dispose();

}

}

#Dispose root web

$RootWeb.Dispose();

Stop-SPAssignment $spAssgn;

$exportFilePath = Join-Path -Path $ExportFileDirectory -ChildPath $([string]::Concat($RootSiteTitle,"-Permissions.csv"));

$Permissions|Select SiteUrl,SiteTitle,ObjectType,ObjectUrl,ListTitle,MemberName,MemberLoginName,MemberType,JobTitle,Department,ParentGroup,GroupOwner,RoleDefinitionBindings|Export-CSV -Path $exportFilePath -NoTypeInformation;

}

else{

Write-Host "Invalid directory path:" $ExportFileDirectory -ForegroundColor "Red";

}