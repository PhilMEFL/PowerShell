$Source = "C:\"
$Dest = "D:\COHPMARTIN"

Get-ChildItem $Source -Recurse | % {
	$_.FullName
	$filDest = $Dest + $_.FullName.Substring($_.FullName.IndexOf(':') + 1)
	Copy-Item $_.fullName $filDest -Force
	}								
