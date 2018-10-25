########################################################################
# Disable-Enable User Account Control
# This script checks the registries of all systems in a text file and checks their UAC status.  It can be set to Disable UAC (setting of 0) or Enable UAC (setting of 1).  The user will need to manually alter the script and choose the desired setting.  Afterwards, the systems will be rebooted.
#########################################################################

########################################################################
# Initialize variables and set paths
########################################################################
clear-host
$ADDomain = Get-ADDomain
# Get only Servers
$Systems = Get-ADComputer -LDAPFilter '(OperatingSystem=*Server*)' -Properties * | sort Name
$WriteUAC = $true
$UACValue = "EnableLUA"
$UACoff = 0
$UACon = 1
$UACpath = "Software\Microsoft\Windows\CurrentVersion\policies\system"

########################################################################
# Loop through the input file for all computers, open the remote
# HKLM hive using .NET, open the subkey to the UAC setting, and
# get the Enable UAC value.
########################################################################

foreach($system in $systems) {
	$OpenRegistry =[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$system.DistinguishedName)
	$UACsubkey = $OpenRegistry.OpenSubKey($UACpath,$WriteUAC)
	$UACsubkey.ToString()
	$UACstate  = $UACsubkey.GetValue($UACvalue)

	Write-Host "The UAC on $system is currently set to $UACstate."

########################################################################
# Disable UAC (EnableLUA setting of 0)
########################################################################

	if ($UACstate -eq 1) {
		Write-Host "Turning the UAC off..."
		$UACsubkey.SetValue($UACvalue, $UACoff)
		$UACstate = $UACsubkey.GetValue($UACvalue)
		Write-Host "The UAC on $system is now set to $UACstate.  The system will now be restarted."
#		(Get-WmiObject -Class Win32_OperatingSystem -ComputerName $system).Win32Shutdown(6)
		}
	else {
		Write-Host "The UAC State of $system is already off."
		}

######################################################################## 
# Enable UAC (EnableLUA setting of 1)
#########################################################################


# If($UACstate -eq 0)

# {

# Write-Host "Turning the UAC on..."

# $UACsubkey.SetValue($UACvalue, $UACon)

# $UACstate = $UACsubkey.GetValue($UACvalue)

# Write-Host "The UAC on $system is now set to $UACstate.  The system will now be restarted."

# (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $system).Win32Shutdown(6)

# }

# Else 

# {

# Write-Host "The UAC State of $system is already on."

# }

}