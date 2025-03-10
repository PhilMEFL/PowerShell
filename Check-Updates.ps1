Param(
	[Parameter(Mandatory=$false)][Int]$GracePeriod
	)

Function Check-NewUpdates {

<#
	.SYNOPSIS
	    Get list of available Windows updates.

	.DESCRIPTION
        Use Check-NewUpdates to determine if there are additional updates that have not been applied to a Microsoft Windows machine. 
		
	.PARAMETER Type
		Pre-search criteria. Finds updates of a specific type, such as 'Driver' and 'Software'. Default value contains all updates.


	.EXAMPLE
		Get list of available updates from Microsoft Update Server, no matter how recent the last check was.
	
		PS D:\Powershell> .\Check-Updates.ps1
            35 Days since last update.
            2 Critical Updates:
            KB2792100
            KB2797052
            6 Important Updates:
            KB2778344
            KB2789642
            KB2789645
            KB2790113
            KB2799494
            KB954430
            1 Moderate Updates:
            KB2790655
            4 Unknown Updates:
            KB890830
            KB915597
            KB971033
            KB973688

    .EXAMPLE
		Get list of available updates from Microsoft Update Server, if last check was outside of grace period.
	
        PS D:\Powershell> .\Check-Updates.ps1 50
            35 Days since last update. Within grace period

		PS D:\Powershell> .\Check-Updates.ps1 50
            35 Days since last update.
            2 Critical Updates:
            KB2792100
            KB2797052
            6 Important Updates:
            KB2778344
            KB2789642
            KB2789645
            KB2790113
            KB2799494
            KB954430
            1 Moderate Updates:
            KB2790655
            4 Unknown Updates:
            KB890830
            KB915597
            KB971033
            KB973688

	.NOTES
		Author: Spenser Reinhardt
        Company: Nagios Enterprises LLC
		Version: 1.0

	.LINK
		http://www.nagios.com

	#>

Param(
	[Parameter(Mandatory=$false)][Int]$GracePeriod
	)

## Start Main Script

$OSVersion = Check-OSVersion

If ( $GracePeriod -ne $null ) { #If GracePeriod is set
	$UpdateTime = Check-LastUpdate $GracePeriod
	
	If ($UpdateTime.IsOver -eq $true) { #If is outside of GP, check for updates and return
		$Updates = Check-Updates
		$Output = Create-Output $Updates
	}
	ElseIF ($UpdateTime.IsOver -eq $false) { #If within GP, return days since check with OK status
        $Output = @{}
        $Output.Output = "Within grace period."
        $Output.ExitCode = 0
	}
} #ends if GP is set
	
Else { # If no grace period has been set, check and return
	$UpdateTime = Check-LastUpdate 0
	$Updates = Check-Updates
	$Output = Create-Output $Updates
}

$days = $UpdateTime.Days
$OutputString = $Output.Output
Write-Output "$days Days since last update. $OutputString"
Exit $Output.ExitCode
}

# Function to check OS Version and return string with 7 or XP depending. Returns [string]
Function Check-OSVersion {
    
    $version = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
     
    switch ($($version.CurrentVersion).split(".")[0]){
        6 { [string]$Return = "7" }
        5 { [string]$Return = "XP" }
    } ## End of Switch to check versioning
    
    Return $Return

} ## End of Function

# Checks for updates using winupdate api, returns hashtable with all listed updates not including hidden ones. Returns [Array](KBImportance)KB and [Int](KBImportance)Number
Function Check-Updates {
	
	$Return = @{}
	[string]$Return.CriticalKB = ""
	[Int]$Return.CriticalNumber = 0
	[string]$Return.ImportantKB = ""
	[Int]$Return.ImportantNumber = 0
	[string]$Return.ModerateKB = ""
	[Int]$Return.ModerateNumber = 0
	[string]$Return.LowKB = ""
	[Int]$Return.LowNumber = 0
    [string]$Return.UnknownKB = ""
	[Int]$Return.UnknownNumber = 0
	
	$Updates = $( New-Object -ComObject Microsoft.Update.Session ).CreateUpdateSearcher().Search("IsAssigned=1 and IsHidden=0 and IsInstalled=0").Updates
	
	$Updates | Where {$_.MsrcSeverity -eq "Critical" } |  ForEach-Object { $_.KbArticleIDs } | Sort -Unique | ForEach-Object { 
			$Return.CriticalNumber++
			$Return.CriticalKB += "KB"+$_+"\n"
			}
			
	$Updates | Where {$_.MsrcSeverity -eq "Important" } |  ForEach-Object { $_.KbArticleIDs } | Sort -Unique | ForEach-Object {
			$Return.ImportantNumber++
			$Return.ImportantKB += "KB"+$_+"\n"
			}
		
	$Updates | Where {$_.MsrcSeverity -eq "Moderate" } |  ForEach-Object { $_.KbArticleIDs } | Sort -Unique | ForEach-Object { 
			$Return.ModerateNumber++
			$Return.ModerateKB += "KB"+$_+"\n"
			}
			
	$Updates | Where {$_.MsrcSeverity -eq "Low" } |  ForEach-Object { $_.KbArticleIDs } | Sort -Unique | ForEach-Object {
			$Return.LowNumber++
			$Return.LowKB += "KB"+$_+"\n"
			}

    $Updates | Where-Object {!$_.MsrcSeverity} |  ForEach-Object { $_.KbArticleIDs } | Sort -Unique | ForEach-Object {
			$Return.UnknownNumber++
			$Return.UnknownKB += "KB"+$_+"\n"
			}
	
	Return $Return
} # Ends Function

# Checks if last update installed was within Grace Period, Returns [Int]Days and [Boolean]IsOver
Function Check-LastUpdate {

	Param([Parameter(Mandatory=$true)][Int]$GracePeriod)
	
	$Return = @{}
	
	#Gets DateTime Object with last update installed
	if ($(Check-OSVersion) -eq "7") {
		$WMIData = Get-WmiObject -Class Win32_QuickFixEngineering 
		}
	Else { 
		$WMIData = $null
		}
	
    If ( $WMIData -eq $null ) { ## No data for installed on, run update check, might be issue with os version too
        $Return.Days = 0
        $Return.IsOver = $true
    	}
    Else { ## has data and should be processed
        [DateTime]$Date = $( $WMIData | Sort InstalledOn -Descending -Unique | Select InstalledOn -First 1 ).InstalledOn
        $Return.Days =  $( $(Get-Date) - $Date).Days
    	If ( $Return.Days -gt $GracePeriod ) { #if true has been longer than grace period
    		
    		$Return.IsOver = $true
    	}
    	Else { #if within Grace Period
    	
    		$Return.IsOver = $false
    	}
    }
    
	Return $Return
}

# Creates write-ouput text for returning data to nagios, Returns [int]ExitCode and [string]Output
Function Create-Output {
	Param ( [Parameter(Mandatory=$true)]$Updates )
	
	$Return = @{}
	[Int]$Return.ExitCode = 3 # Sets to unknown by default
	[String]$Return.Output = "Output creation failed, something is not working!"
	
	If ( $Updates.CriticalNumber -gt 0 ) { # If any Critical updates, writes output line and sets exit code to 2(critical)
		$Return.ExitCode = 2
		$Return.Output = "`n"+$Updates.CriticalNumber+" Critical Updates:"
		
		$Return.Output += "`n"+$Updates.CriticalKB.Replace("\n","`n")
		

		If ($Updates.ImportantNumber -gt 0)	{$Return.Output += ""+$Updates.ImportantNumber+" Important Updates:`n"
											 $Return.Output += $Updates.ImportantKB.Replace("\n","`n")
		    								}		
		If ($Updates.ModerateNumber -gt 0) 	{$Return.Output += ""+$Updates.ModerateNumber+" Moderate Updates:`n"
											 $Return.Output += $Updates.ModerateKB.Replace("\n","`n")
											}		
		If ($Updates.LowNumber -gt 0) 		{$Return.Output += ""+$Updates.LowNumber+" Low Updates:`n"
											 $Return.Output += $Updates.LowKB.Replace("\n","`n")
											}
        If ($Updates.UnknownNumber -gt 0)	{$Return.Output += ""+$Updates.UnknownNumber+" Unknown Updates:`n"
											 $Return.Output += $Updates.UnknownKB.Replace("\n","`n")
											}

	} #Ends Critical If
	
	ElseIf ( $Updates.ImportantNumber -gt 0 ) { # If any Important updates, writes output line and sets exit code to 2(critical)
		$Return.ExitCode = 2
		$Return.Output = "`n"+$Updates.ImportantNumber+" Important Updates:"
		
		$Return.Output += "`n"+$Updates.ImportantKB.Replace("\n","`n")
		
		If ($Updates.ModerateNumber -gt 0) 	{$Return.Output += ""+$Updates.ModerateNumber+" Moderate Updates:`n"
											 $Return.Output += $Updates.ModerateKB.Replace("\n","`n")
											}		
		If ($Updates.LowNumber -gt 0) 		{$Return.Output += ""+$Updates.LowNumber+" Low Updates:`n"
											 $Return.Output += $Updates.LowKB.Replace("\n","`n")
											}
        If ($Updates.UnknownNumber -gt 0)	{$Return.Output += ""+$Updates.UnknownNumber+" Unknown Updates:`n"
											 $Return.Output += $Updates.UnknownKB.Replace("\n","`n")
											}
	} #Ends Important If

	ElseIf ( $Updates.ModerateNumber -gt 0 ) { # If any Moderate updates, writes output line and sets exit code to 1(Warning)
			$Return.ExitCode = 1
			$Return.Output = "`n"+$Updates.ModerateNumber+" Moderate Updates:"
			
			$Return.Output += "`n"+$Updates.ModerateKB.Replace("\n","`n")
			
			If ($Updates.LowNumber -gt 0) 		{$Return.Output += ""+$Updates.LowNumber+" Low Updates:`n"
												 $Return.Output += $Updates.LowKB.Replace("\n","`n")
											}
            If ($Updates.UnknownNumber -gt 0) 	{$Return.Output += ""+$Updates.UnknownNumber+" Unknown Updates:`n"
												 $Return.Output += $Updates.UnknownKB.Replace("\n","`n")
											}
		} #Ends Moderate If
	
	ElseIf ( $Updates.LowNumber -gt 0 ) { # If any Low updates, writes output line and sets exit code to 1(Warning)
		    $Return.ExitCode = 1
		    $Return.Output = "`n"+$Updates.LowNumber+" Low Updates:"
		
		    $Return.Output += "`n"+$Updates.LowKB.Replace("\n","`n")
            If ($Updates.UnknownNumber -gt 0) 	{$Return.Output += ""+$Updates.UnknownNumber+" Unknown Updates:`n"
												 $Return.Output += $Updates.UnknownKB.Replace("\n","`n")
											}
            
		
	} #Ends Low If
    
    ElseIf ($Updates.UnknownNumber -gt 0) { # If number of unknown severity updates are available sets exit to 1(warning)
        $Return.ExitCode = 1
		$Return.Output = "`n"+$Updates.UnknownNumber+" Unknown Updates:"
		
		$Return.Output += "`n"+$Updates.UnknownKB.Replace("\n","`n")
    }

	ElseIf ( ($Updates.CriticalNumber -eq 0) -and ($Updates.ImportantNumber -eq 0) -and ($Updates.ModerateNumber -eq 0) -and ($Updates.LowNumber -eq 0) -and ($Updates.UnknownNumber -eq 0) ) { #If no updates, writes output and sets exit 0(OK)
		$Return.ExitCode = 0
		$Return.Output = "There are no updates to be done."
	}
	
	Return $Return
}

Check-NewUpdates