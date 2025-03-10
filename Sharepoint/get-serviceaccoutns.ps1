﻿Add-PSSnapin Microsoft.SharePoint.Powershell

[System.Collections.ArrayList]$ServiceAccounts = @()

#Get all accounts registered as managed accounts
 Write-Host "Retrieving SharePoint Managed Accounts" -ForegroundColor Green
 $temp = Get-SPManagedAccount
 foreach ($item in $temp)
 {
 $item.Username
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.Username
 $ServiceAccounts += $temps
 }

#Get Application Pool Accounts
 Write-Host ""
 Write-Host "Retrieving SharePoint Application Pool Accounts" -ForegroundColor Green
 $temp = Get-SPWebApplication -IncludeCentralAdministration | select -expand applicationpool | Select name , username
 foreach ($item in $temp)
 {
 $item.Username
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.Username
 $ServiceAccounts += $temps
 }

$temp = Get-SPServiceApplicationPool
 foreach ($item in $temp)
 {
 $item.ProcessAccountName
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.ProcessAccountName
 $ServiceAccounts += $temps
 }

#Get all accounts running service applications
 Write-Host ""
 Write-Host "Retrieving SharePoint Service Application Accounts" -ForegroundColor Green
 $temp = Get-SPServiceApplication | select -expand applicationpool -EA 0
 foreach ($item in $temp)
 {
 $item.ProcessAccountName
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.ProcessAccountName
 $ServiceAccounts += $temps
 }

#Get User Profile sync account
 Write-Host ""
 Write-Host "Retrieving SharePoint User Profile Sync Account" -ForegroundColor Green
 $caWebApp = [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]::Local
 $configManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager( $(Get-SPServiceContext $caWebApp.Sites[0].Url))
 #$temp = $configManager | select -expand connectionmanager | select AccountUserName
 $temp = $configManager | select -expand connectionmanager | select ProcessAccountName
 foreach ($item in $temp)
 {
 $item.AccountUsername
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.AccountUsername
 $ServiceAccounts += $temps
 }

#Get Service Instance accounts (Services on server)
 Write-Host ""
 Write-Host "Retrieving SharePoint Service Instance Accounts" -ForegroundColor Green
 $temp = Get-SPServiceInstance | select -expand service | % { if ( $_.ProcessIdentity -and $_.ProcessIdentity.GetType() -eq "String") { $_.ProcessIdentity } elseif ( $_.ProcessIdentity ) { $_.ProcessIdentity.UserName }}
 foreach ($item in $temp)
 {
 $item
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item
 $ServiceAccounts += $temps
 }

#Get Services accounts
 Write-Host ""
 Write-Host "Retrieving Accounts Running SharePoint Services" -ForegroundColor Green
 $temp = Get-WmiObject -Query "select * from win32_service where name LIKE 'SP%v4'" | select name, startname
 foreach ($item in $temp)
 {
 $item.Startname
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.startname
 $ServiceAccounts += $temps
 }

$temp = Get-WmiObject -Query "select * from win32_service where name LIKE '%15'" | select name, startname
 foreach ($item in $temp)
 {
 $item.Startname
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.startname
 $ServiceAccounts += $temps
 }

$temp = Get-WmiObject -Query "select * from win32_service where name LIKE 'FIM%'" | select name, startname
 foreach ($item in $temp)
 {
 $item.Startname
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.startname
 $ServiceAccounts += $temps
 }

#Get Object Cache accounts
 Write-Host ""
 Write-Host "Retrieving SharePoint Object Cache Accounts" -ForegroundColor Green
 $temp = Get-SPWebApplication| % {$_.Properties["portalsuperuseraccount"]}
 foreach ($item in $temp)
 {
 $item
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item
 $ServiceAccounts += $temps
 }

$temp = Get-SPWebApplication| % {$_.Properties["portalsuperreaderaccount"]}
 foreach ($item in $temp)
 {
 $item
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item
 $ServiceAccounts += $temps
 }

#Get default Search crawler account
 Write-Host ""
 Write-Host "Retrieving SharePoint Search Crawler Account(s)" -ForegroundColor Green
 $temp = New-Object Microsoft.Office.Server.Search.Administration.content $(Get-SPEnterpriseSearchServiceApplication) | Select DefaultGatheringAccount
 foreach ($item in $temp)
 {
 $item.DefaultGatheringAccount
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.DefaultGatheringAccount
 $ServiceAccounts += $temps
 }
 #Get all search crawler accounts from crawl rules
 $rules = Get-SPEnterpriseSearchCrawlRule -SearchApplication (Get-SPEnterpriseSearchServiceApplication)
 foreach($rule in $rules)
 {
 $item.AccountName
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $rule.AccountName
 $ServiceAccounts += $temps
 }

#Get Unattended Accounts
 Write-Host ""
 Write-Host "Retrieving Unattended Service Application ID Account(s)" -ForegroundColor Green
 $UnattendedAccounts = @()
 if(Get-SPVisioServiceApplication)
 {
 $svcapp = Get-SPServiceApplication | Where {$_.TypeName -like "*Visio*"}
 $Visio = ($svcapp | Get-SPVisioExternalData).UnattendedServiceAccountApplicationID
 $UnattendedAccounts += $Visio
 }
 if(Get-SPExcelServiceApplication)
 {
 $Excel = (Get-SPExcelServiceApplication).UnattendedAccountApplicationID
 $UnattendedAccounts += $Excel
 }
 if(Get-SPPerformancePointServiceApplication)
 {
 $PerformancePoint = (Get-SPPerformancePointSecureDataValues -ServiceApplication $svcApp.Id).DataSourceUnattendedServiceAccount
 $UnattendedAccounts += $PerformancePoint
 }
 if(Get-PowerPivotServiceApplication)
 {
 $PowerPivot = (Get-PowerPivotServiceApplication).UnattendedAccount
 $UnattendedAccounts += $PowerPivot
 }

$serviceCntx = Get-SPServiceContext -Site (Get-SPWebApplication -includecentraladministration | where {$_.IsAdministrationWebApplication} | Select-Object -ExpandProperty Url)
 $sssProvider = New-Object Microsoft.Office.SecureStoreService.Server.SecureStoreProvider
 $sssProvider.Context = $serviceCntx
 $marshal = [System.Runtime.InteropServices.Marshal]

$applications = $sssProvider.GetTargetApplications()
 foreach ($application in $applications | Where {$UnattendedAccounts -contains $_.Name})
 {
 $sssCreds = $sssProvider.GetCredentials($application.Name)
 foreach ($sssCred in $sssCreds | Where {$_.CredentialType -eq "WindowsUserName" -or $_.CredentialType -eq "UserName"})
 {
 $ptr = $marshal::SecureStringToBSTR($sssCred.Credential)
 $str = $marshal::PtrToStringBSTR($ptr)
 $str + " (" + $application.Name + ")"
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $str
 $ServiceAccounts += $temps
 }
 }

#Display Results
 Write-Host ""
 Write-Host "All Service Accounts" -ForegroundColor Cyan
 $ServiceAccounts | Select UserName -Unique | Sort-Object Username | Format-Table

#Get All Farm administrators
 [System.Collections.ArrayList]$FarmAdministrators = @()
 $temp = Get-SPWebApplication -IncludeCentralAdministration | ? IsAdministrationWebApplication | Select -Expand Sites | ? ServerRelativeUrl -eq "/" | Get-SPWeb | Select -Expand SiteGroups | ? Name -eq "Farm Administrators" | Select -expand Users
 foreach ($item in $temp)
 {
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.UserLogin
 $FarmAdministrators += $temps
 }

foreach ($item in $temp)
 {
 $temps = @()
 $temps = "" | Select UserName
 $temps.UserName = $item.DisplayName
 $FarmAdministrators += $temps
 }
 
#Convert SIDs to UserNames
 $convert = $FarmAdministrators | Where {$_.UserName -Like "*|s-*"}
 foreach($user in $convert)
 {
 $UserName = $user.UserName
 $objSID = New-Object System.Security.Principal.SecurityIdentifier ($UserName.Substring($UserName.IndexOf("|") + 1,$UserName.Length - $UserName.IndexOf("|") - 1))
 $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
 $FarmAdministrators.Remove($user)
 $FarmAdministrators.Add($objUser.Value) >null
 }
 Write-Host ""
 Write-Host ""
 Write-Host "All Farm Administrator Accounts" -ForegroundColor Cyan
 $FarmAdministrators | Select UserName -Unique | Sort-Object Username | Format-Table
