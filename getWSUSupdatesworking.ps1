cls
$WUServer = get-item HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate

$Computername = 'cocwa01'
$UseSSL = $False
$Port = 8530

[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
$Wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($Computername,$UseSSL,$Port)
 
#Updates per TargetGroup
$wsus.GetComputerTargetGroups() | ForEach {
    $Group = $_.Name
    $_.GetTotalSummary() | ForEach {
        [pscustomobject]@{
            TargetGroup = $Group
            Needed = ($_.NotInstalledCount + $_.DownloadedCount)
            "Installed/NotApplicable" = ($_.NotApplicableCount + $_.InstalledCount)
            NoStatus = $_.UnknownCount
            PendingReboot = $_.InstalledPendingRebootCount
        }
    }
}
'Downloaded, Not installed'
$TargetGroup = 'Servers'
$updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$updateScope.IncludedInstallationStates = 'Downloaded','NotInstalled'
($wsus.GetComputerTargetGroups() | Where {$_.Name -eq $TargetGroup}).GetComputerTargets() | ForEach {
        $Computername = $_.fulldomainname
		$goulala = $_.GetUpdateInstallationInfoPerUpdate($updateScope)
		$goulala.count
        $_.GetUpdateInstallationInfoPerUpdate($updateScope) | ForEach {
            $update = $_.GetUpdate()
            [pscustomobject]@{
                Computername = $Computername
                TargetGroup = $TargetGroup
                UpdateTitle = $Update.Title 
                IsApproved = $update.IsApproved
            }
    }
}


 
$TargetGroup = 'Servers'
$updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$updateScope.IncludedInstallationStates = 'InstalledPendingReboot'
$computerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$computerScope.IncludedInstallationStates = 'InstalledPendingReboot'
($wsus.GetComputerTargetGroups() | Where {
    $_.Name -eq $TargetGroup 
}).GetComputerTargets($computerScope) | ForEach {
        $Computername = $_.fulldomainname
        $_.GetUpdateInstallationInfoPerUpdate($updateScope) | ForEach {
            $update = $_.GetUpdate()
            [pscustomobject]@{
                Computername = $Computername
                TargetGroup = $TargetGroup
                UpdateTitle = $Update.Title 
                IsApproved = $update.IsApproved
            }
    }
} 
 
