Function Get-PrinterName ([string]$HostName) {
	Begin {}
	Process {
		Write-Host "HostName: "$_
		$FileName = "C:\PrinterBatch\" + $_ + ".bat"
		$file = New-Item -type file $FileName
		$Printers = Get-WmiObject `-Class Win32_Printer`-ComputerName $_ `-ErrorAction SilentlyContinue
		ForEach ($Printer in $Printers){ 
			if ($Printer.Name -match 'osu_mc'){
				Add-Content -Path $FileName `-value "rundll32 printui.dll,PrintUIEntry /in /q /n"
				Add-Content -Path $FileName `-value $Printer.Name
				}
			}
		}
		}
Get-Content 'C:\HostNames.txt' | Get-PrinterName