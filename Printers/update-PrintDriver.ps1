if ($args.count -lt 3) {
	"usage : $($MyInvocation.MyCommand) <print_server> <old_driver> <new_driver>"
	}
else {
# check parameters
	$server = $args[0]
	$oldDriver = $args[1]
	$newDriver = $args[2]
	
	$regHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(“LOCALMACHINE”,$server)

# Update specific driver
	$printers = Get-WmiObject -Query "select * from Win32_Printer where DriverName = '$($oldDriver)'" -ComputerName $server

	if ($printers.count -gt 0) {
		foreach ($printer in $printers) {
			$printer.DriverName = $newDriver
			$printer.Put() | Out-Null
			}
		}
}