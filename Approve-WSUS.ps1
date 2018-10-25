#import-module poshWSUS

cls
function get-NextSunday {
	$Date = Get-Date
	$targetDay = [int][dayofweek]::Sunday
	
	$intToday = if([int]$Date.DayOfWeek -le [int][dayofweek]::Sunday ){
		[int]$Date.DayOfWeek 
		}
	else { 
		[int]$Date.DayOfWeek - 7
		}
	($date.AddDays($targetDay - $intToday)).toShortDateString()
	}

function send-notification ($arrMsg, $to, $from) {
	$strDomain = Get-ADDomain
	switch ($strDomain.Name.toUpper()) {
		'GPCO' {
			$smtpSrv = 'mail.gpco.be'
			}
		'GPCOCAT' {
			$smtpSrv = 'cocwa01'
			}
		}
	$subject = "Windows Updates installation for {0} scheduled for Sunday {1}" -f $strDomain.Name.toUpper(), (get-NextSunday)

#	$arrMsg | %{
#		$_.Name
        try {
		    Send-MailMessage -To $to -From $from -Subject $subject -body $arrMsg -SmtpServer $smtpSrv
 #-UseSsl $true
            Start-Sleep -s 5
            }
        catch {
			'Error sending mail'
            }
#		}
	}

[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
#Define the actions available for approving a patch
$all = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::All
$install = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Install
$NotApproved = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::NotApproved
$Uninstall = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Uninstall
$hshInstall = @{}
$arrOutFile = @()

#E-mail Configuration
if ($env:USERDOMAIN -eq 'GPCO') {
	$WsusServer = 'COPWA01'
	'Change.Release@gpco.be'
    $Recipients = 'philippe.martin@gpco.be'
	$FromAddress = 'Notifications@gpco.be'
	$logFileLocation = '\\copfps01.gpco.local\it_ops\Operations\WSUS updates\Approvals'
	}
else {
	$WsusServer = 'COCWA01'
	$SMTPServer = 'COCWA01'
    $Recipients = 'philippe.martin@gpcocat.local'
	$FromAddress = 'Notifications@gpcocat.local'
	$logFileLocation = '\\COCWA01\UpdatesInstall'
    }




$logFileLocation = "{0}\{1}\" -f $logFileLocation, (Get-Date -UFormat "%d-%m-%Y")

# Retrieve the date of the last approval - Thsi cannot be automated because there is no communication between CAT and Prod
do {
	$dtLasttApproval = Read-Host 'Enter the last approbation date:'
	if (($dtLasttApproval -as [DateTime]) -ne $null) {
		$dtLasttApproval = [DateTime]::Parse($dtLasttApproval)
		$blOK = $true
		}
	else {
		'You did not enter a valid date!'
		$blOK = $false
		}
	}
until ($blOK)
	
if (!(test-path $logFileLocation)) {
    new-item -ItemType Directory -path $logFileLocation
    }

$strOutFile = "{0}Approvals.txt" -f $logFileLocation
if (!(test-path $strOutFile)) {
    New-Item $strOutFile -ItemType file  # | Out-Null
    }

$UseSSL = $false
$PortNumber = 8530
$TrialRun = $false

#Connect to the WSUS 3.0 interface.
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($WsusServer, $UseSSL, $PortNumber) 

$wsusGrps = $wsus.GetComputerTargetGroups()
$wsusGrps | %{
    $hshInstall[$_.Name] = $install
    }

# get updates
$wsUpdates = $wsus.GetUpdates()

# decline update for Itanium based computers
$arrOutFile += 'Decline updates for Itanium based computers' 
$wsUpdates | ?{-not $_.IsDeclined -and $_.Title -match "ia64|itanium"} | %{
	$_.decline()
	$arrOutFile += "{0} declined" -f $_.Title
	}

$wsUpdates | ? {(!($_.isApproved) -and !($_.IsDeclined)) -and ($_.ArrivalDate -le $dtLasttApproval)} | %{
    $upd = $_
    if ($upd.Title -match 'SQL') {
#		$HshInstall[$upd.Title] = $NotApproved
		}
	elseif ($_.Title -match 'Sharepoint') {
		$HshInstall[$upd.Title] = $NotApproved
		}
	elseif ($_.Title -match 'WSUS') {
		$HshInstall[$upd.Title] = $NotApproved
    	}

	$arrOutFile += $upd.Title
    $WsusGrps | %{
		if ($upd.HasLicenseAgreement) {
			$upd.AcceptLicenseAgreement()
			}
		$upd.Approve($hshInstall[$_.name],$_) | Out-Null
        $arrOutFile += "approved for {2} on {1} group" -f $upd.Title, $_.Name, $hshInstall[$_.Name] >> $strOutFile
		Start-Sleep -s 5
        $upd.IsApproved
		}
	}

$arrOutFile = Get-Content($strOutFile)
send-notification $arrOutFile $Recipients $FromAddress
