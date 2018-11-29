param($Step="A")
# -------------------------------------
# Imports
# -------------------------------------
$script = $myInvocation.MyCommand.Definition
$scriptPath = Split-Path -parent $script
. (Join-Path $scriptpath functions.ps1)


Clear-Any-Restart

if (Should-Run-Step "A") 
{
	Write-Host "A"
	Wait-For-Keypress "The test script will continue after a reboot, press any key to reboot..." 
	Restart-And-Resume $script "B"
}

if (Should-Run-Step "B") 
{
	Write-Host "B"
}

if (Should-Run-Step "C") 
{
	Write-Host "C"
}

Wait-For-Keypress "Test script Complete, press any key to exit script..."