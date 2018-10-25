##################################################################################
#
#
#  Script name: Get-ComputerOnline.ps1
#  Author:      goude@powershell.nu
#  Homepage:    www.powershell.nu
#
#
##################################################################################

param ([string]$Computer, [string]$List, [switch]$help, [switch]$Windows7)

function GetHelp() {


$HelpText = @"

DESCRIPTION

NAME: Get-ComputerOnline.ps1
Gets Information about Clients that are
in your network and returns the information
to a HashTable Array

PARAMETERS: 
-Computer    Sharepoint Url (Optional)
-List        Exports the Information to a Csv file (Optional)
-Windows7    Use this switch if run the script on Vista Or Win 7 (optional)
-help        Prints the HelpFile (Optional)

SYNTAX:
./Get-ComputerOnline.ps1 -Computer Laptop1

Checks if the Computer is on the Network and returns
Computername and IPAddress.

./Get-ComputerOnline.ps1 -List "C:\Folder\MyComputerList.txt"

Loops through each Client in the List and checks
if the Computers are on the Network and returns
Computername and IPAddress

./Get-ComputerOnline.ps1 -Computer Laptop1 -Windows7

Checks if the Computer is on the Network and returns
Computername and IPAddress for Windows 7 Computers,
If they use IPV4

./Get-ComputerOnline.ps1 -List "C:\Folder\MyComputerList.txt" -Windows7

Loops through each Client in the List and checks
if the Computers are on the Network and returns
Computername and IPAddress for Windows 7 Computers,
If they Use IPV4

./Get-ComputerOnline.ps1 -help

Displays the help topic for the script

"@
$HelpText

}

function Collect-Information($Computer, $List, [switch]$Windows7) {

	if($Windows7) {

		if($List) {
			$GetList = Get-Content $List
			$GetList | ForEach {
				Get-IP $_ -Windows7
			}
		} else {
			Get-IP $Computer -Windows7
		}
	} else {

		if($List) {
			$GetList = Get-Content $List
			$GetList | ForEach {
				Get-IP $_
			}
		} else {
			Get-IP $Computer
		}
	}
}

function Get-IP([string]$Computer, [switch]$Windows7) {

	$ClientObject = @{}

	if($Windows7) {
		$Ping = ping -4 $Computer
	} else {
		$Ping = ping $Computer
	}

	if($Ping -match "Reply from") {

		$IP = ($Ping | Select-String "Reply from")[0].ToString()
		$IPAddress = [regex]::Match($IP,"[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")

		# Add Information to a Hasthtable Array

		$ClientObject.Add("Computer",$Computer)
		$ClientObject.Add("IPAddress",$IPAddress)
		$ClientObject.Add("Online","Yes")

	} else {

		# Add Information to a Hasthtable Array

		$ClientObject.Add("Computer",$Computer)
		$ClientObject.Add("IPAddress","Not Found")
		$ClientObject.Add("Online","No")
	}
	$ClientObject
}

if ($help) { GetHelp }

if ($Computer -AND $List) { 
	Write-Host "Please Specify a Client OR a List containing Clients"; 
	GetHelp 
	Continue
}

if ($Windows7) { 
	if ($Computer) { Collect-Information -Computer $Computer -Windows7 }
	if ($List) { Collect-Information -List $List -Windows7 }
} else {
	if ($Computer) { Collect-Information -Computer $Computer }
	if ($List) { Collect-Information -List $List }
}