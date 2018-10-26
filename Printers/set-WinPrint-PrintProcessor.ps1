if ($args.count -lt 1) {
	"usage : $($MyInvocation.MyCommand) <print_server>"
	}
else {
# check parameters
	$server = $args[0]
	
	$regHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(“LOCALMACHINE”,$server)

# Update specific driver
	$printers = Get-WmiObject -Query "select * from Win32_Printer where PrintProcessor <> 'WinPrint'" -ComputerName $server

	if ($printers.count -gt 0) {
		foreach ($printer in $printers) {
			$regKey = $regHKLM.OpenSubKey(“System\CurrentControlSet\Control\Print\Printers\$($Printer.Name)”,$true)
			$RegKey.SetValue('Print Processor','WinPrint')
			}
		}
}