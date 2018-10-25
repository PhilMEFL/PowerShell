# Looks returns all of the .NET types currently loaded by PowerShell

function Get-Type() {
	[AppDomain]::CurrentDomain.GetAssemblies() | % {
		$_.GetTypes() 
		}
	} 

Get-Type | Where-Object { $_.IsSubclassOf([Windows.Controls.Control])}
