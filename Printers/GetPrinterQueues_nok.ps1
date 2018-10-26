Add-Type -AssemblyName System.Printing
$permissions = [System.Printing.PrintSystemDesiredAccess]::AdministrateServer
$queueperms = [System.Printing.PrintSystemDesiredAccess]::AdministratePrinter
# $server = new-object System.Printing.PrintServer -ArgumentList "\\s-ci-prt03,$($permissions)"
$server = new-object System.Printing.PrintServer "\\s-ci-prt03"
$queues = $server.GetPrintQueues(@([System.Printing.EnumeratedPrintQueueTypes]::Shared))
#$queues = $server.GetPrintQueues()

foreach ($q in $queues) { 
	$print = Get-WmiObject -Query "select * from Win32_Printer where name = '$($q.Name)'" -ComputerName $args

	"$($q.Name) - $($print.Name) : $($print.DriverName)"
	#Get edit Permissions on the Queue    
	$q2 = new-object System.Printing.PrintQueue -argumentList $server,$q.Name,1,$queueperms        
#	$q2 = new-object System.Printing.PrintQueue
	if (!(($print.DriverName -eq 'HP Universal Printing PCL 6 (v5.1)') -or
		($print.DriverName -eq 'Lexmark Universal PS3'))) {
			$duplexCaps = $q2.GetPrintCapabilities().DuplexingCapability  
			if ($duplexCaps.Contains([System.Printing.Duplexing]::TwoSidedLongEdge)) {        
				$q2.DefaultPrintTicket.Duplexing = [System.Printing.Duplexing]::TwoSidedLongEdge		
				$q2.commit()	
				}
			}
	$toto = 'tata'
	}