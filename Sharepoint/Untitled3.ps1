#$siteCollection = $gc | New-SPSite -Url ($webAppConfig.Url + $siteCollectionConfig.Url) -ContentDatabase $db -Description $siteCollectionConfig.Description -Language $siteCollectionConfig.LCID-Name $siteCollectionConfig.Name -Template $siteCollectionConfig.Template -OwnerAlias $siteCollectionConfig.OwnerLogin -OwnerEmail $siteCollectionConfig.OwnerEmail

$siteCollection = Get-SPWeb -Site http://cocsp02

if($siteCollection -ne $null)
{
Write-Host "Site collection $($siteCollectionConfig.Url) created" -foregroundcolor green
$primaryOwner = $siteCollectionConfig.OwnerLogin
$secondaryOwner = ""
 
Write-Host "Removing any existing visitors group for Site collection $($siteCollectionConfig.Url)" -foregroundcolor blue
#This is here to fix the situation where a visitors group has already been assigned
$siteCollection.RootWeb.AssociatedVisitorGroup = $null;
$siteCollection.RootWeb.Update();Write-Host "Creating Owners group for Site collection $($siteCollectionConfig.Url)" -foregroundcolor blue
$siteCollection.RootWeb.CreateDefaultAssociatedGroups($primaryOwner, $secondaryOwner, $siteCollection.Title)
$siteCollection.RootWeb.Update();
}
else
{
Write-Host "Site collection $($siteCollectionConfig.Url) failed" -foregroundcolor red
}