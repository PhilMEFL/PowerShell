Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue

cls

Get-SPServiceApplication | %{
	$_.DisplayName + " - " + $_.TypeName
	$_
	}