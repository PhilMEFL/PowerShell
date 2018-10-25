#* FileName: Invoke-WindowsUpdate.ps1
#*================================================================
#* Script Name: [Invoke-WindowsUpdate]
#* Created: [12/10/07]
#* Author: Steven Murawski
#* Company:
#* Email: steve@acoupleofadmins.com
#* Web: http://www.acoupleofadmins.com
#* Reqrmnts:
#* Keywords:
#*===============================================================
#* Purpose: This script will force a computer to check for updates from
#* Microsoft Update or a local WSUS Server. This script is the
#* PowerShell version of the batch file found at Patchaholic - The WSUS Blog
#* http://msmvps.com/blogs/athif/pages/66375.aspx
#*===============================================================

Write-Host “This PowerShell script will Force the Update Detection from the AU client:”
Write-Host “1. Stops the Automatic Updates Service (wuauserv)”
Write-Host “2. Deletes the LastWaitTimeout registry key (if it exists)”
Write-Host “3. Deletes the DetectionStartTime registry key (if it exists)”
Write-Host “4. Deletes the NextDetectionTime registry key (if it exists)”
Write-Host “5. Restart the Automatic Updates Service (wuauserv)”
Write-Host “6. Force the detection”
Read-Host “Press enter to continue”

# Stop the local Windows Update Service
Stop-Service wuauserv

# Set the location of registry key
$AutoUpdate = “HKLM:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update”

# PowerShell allows you to navigate the registry like a drive
# The various registry hives are like drives, the keys are like files
# and their values are shown as properties.

# The switch statement below checks to see if any of the values below are set and deletes them
# if they are present.
switch (Get-ItemProperty $AutoUpdate)
{
{$_.LastWaitTimeout} {Remove-ItemProperty -Path $AutoUpdate -name LastWaitTimeout}
{$_.DetectionStartTime} {Remove-ItemProperty -Path $AutoUpdate -name DetectionStartTime}
{$_.NextDetectionTime} {Remove-ItemProperty -Path $AutoUpdate -name NextDetectionTime}
}

