<#
.SYNOPSIS
	This script displays the printers on a given computer
.DESCRIPTION
	This script first has to load system.printing, then it    
	gets the printers (queues). NB: The queues are returned    
	in a collection, not an array.
.NOTES    
	File Name  : Get-PrintQueue.ps1 
	Author     : Thomas Lee - tfl@psp.co.uk 
	Requires   : PowerShell Version 2.0
.LINK    
	This script posted to:
http://www.pshscripts.blogspot.com    
	MSDN Sample posted at:
http://msdn.microsoft.com/en-us/library/ms552937.aspx
.EXAMPLE    
	PS c:\foo:\> E:\PowerShellScriptLib\System.Printing\Get-Printqueue.ps1    
	Print Queues on: \\Cookham8    Printer Name                                   Shared as    ------------                                   ---------
	\\Cookham8\SnagIt 9                            
	\\Cookham8\Phaser PS                           Phaser PS
	\\Cookham8\Microsoft XPS Document Writer       
.PARAMETER    [String] $Computer
#>

param ($computer = "s-ci-prt02")

# create an object
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Printing")
$PrintServer = new-object -TypeName system.printing.printserver "\\$computer"

# Get the print server's queues
$PrintQueues = $PrintServer.GetPrintQueues()
"Print Queues on: $Computer"
"{0,-45}  {1}" -f "Printer Name", "Shared as"
"{0,-45}  {1}" -f "------------", "---------"
foreach ($queue in $printqueues) {
	"{0,-45}  {1}" -f $queue.fullname, $queue.sharename
<#	$duplexCaps = $queue.GetPrintCapabilities().DuplexingCapability    
	$duplexCaps
	if ($duplexCaps.Contains([System.Printing.Duplexing]::TwoSidedLongEdge)) {        
		$queue.DefaultPrintTicket.Duplexing = [System.Printing.Duplexing]::TwoSidedLongEdge		
		$queue.commit()	
		$queue
		}
#>	$tata = 'toto'
	}