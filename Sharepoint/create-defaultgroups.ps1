Add-PSSnapin Microsoft.SharePoint.PowerShell

$web = Get-SPWeb http://cocsp02

if ($web.AssociatedVisitorGroup -eq $null) {
    Write-Host 'The Visitor Group does not exist. It will be created...' -ForegroundColor DarkYellow
    $currentLogin = $web.CurrentUser.LoginName

    if ($web.CurrentUser.IsSiteAdmin -eq $false){
        Write-Host ('The user '+$currentLogin+' needs to be a SiteCollection administrator, to create the default groups.') -ForegroundColor Red
        return
    }

    $web.CreateDefaultAssociatedGroups($currentLogin, $currentLogin, [System.String].Empty)
    Write-Host 'The default Groups have been created.' -ForegroundColor Green
} else {
    Write-Host 'The Visitor Group already exists.' -ForegroundColor Green
}