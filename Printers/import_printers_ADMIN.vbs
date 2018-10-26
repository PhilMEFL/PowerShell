On Error Resume Next
CONST FORCEMODE="NO"

CONST exclude_driver = "HP DeskJet 1120C;Oce VarioPrint 2110 PS;HP LaserJet 1200 Series PCL 6;HP LaserJet 8150 PCL 6;HP Officejet Pro K550 Series;HP Business Inkjet 2200/2250;RISO RZ 9 Series;HP Color LaserJet 4550 PCL 6HP DesignJet 1055CM by HP;HP Color LaserJet 8550 PCL 5C;HP 2500C Series;HP Color LaserJet 9500 PCL 6;HP DeskJet 1220C Printer;HP Color LaserJet 5550 PCL 6;HP Designjet T1100ps 44in HPGL2;HP Deskjet 9800 Series;HP Designjet Z6100 60in Photo HPGL2;LANIER LD145 PCL 6;Oce VarioPrint 2100 PS;HP Business Inkjet 2800 PS"


Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly       = &h20
Const ForReading = 1, ForWriting = 2, ForAppending = 8
'Const exportfolder="z:\ITIC_PRINT\scripts\export_data"
Const exportfolder="\\net1\CI\Common\ITIC_PRINT\scripts\export_data"
const HKEY_LOCAL_MACHINE = &H80000002
const REG_SZ = 1
const REG_EXPAND_SZ = 2
const REG_BINARY = 3
const REG_DWORD = 4
const REG_MULTI_SZ = 7
'Const SETPRINTER="\\net1\ci\Common\utilities\setprinter.exe "
Const SETPRINTER="setprinter.exe "
'CONST PRINTMIG = "\\net1\CI\Common\utilities\PrintMig\printmig.exe "
CONST PRINTMIG = "e:\PrintMig\printmig.exe "

CONST GENERIC_PATH = "\\net1\CI\Common\ITIC_PRINT\scripts\GENERIC\"
CONST HPC2280="P-HPC2280-GENERIC"
CONST HPC2280RV="P-HPC2280-GENERIC-R-V"
CONST HPC2300="P-HPC2300-GENERIC"
CONST HPC2300RV="P-HPC2300-GENERIC-R-V"
CONST HP="P-HP-GENERIC"
CONST HPRV="P-HP-GENERIC-R-V"
CONST LEX644="P-LEX644-GENERIC"
CONST LEX644RV="P-LEX644-GENERIC-R-V"
CONST LEX="P-LEX-GENERIC"
CONST LEXRV="P-LEX-GENERIC-R-V"

Set objShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

If WScript.Arguments.UnNamed.Count = 1 Then
	Server = WScript.Arguments.UnNamed(0)
Else
	Server = objshell.ExpandEnvironmentStrings("%COMPUTERNAME%")
End if

wscript.echo Server

Listprn = List_printer (server)

wscript.echo exportfolder & "\" & Server & "\data\itic-all-printers.csv"
Set ts = fso.OpenTextFile(exportfolder & "\" & Server & "\data\itic-all-printers.csv", ForReading)
Do Until ts.AtEndOfStream
		alldata = alldata & ts.readline & chr(10)
Loop
ts.close
Set ts = nothing

all = split(alldata,chr(10))
HP_Unreach=""

'Set ts = fso.OpenTextFile(exportfolder & "\" & server & "\data\DIGIT-list.txt", ForWriting,true)
Set ts = fso.OpenTextFile(exportfolder & "\" & Server & "\data\ADMIN-list.txt", ForWriting,true)
for each data in all
	If InStr(LCase(data),"test") = 0 and data <> "" Then
		line = data
		data = split (data,",")
		printername = data(0)
		wscript.echo printername
		Comment = data(1)
		Location = data(2)
		driver = data(3)
		portname = data(0) 
		ipadress = data(6)
		porttcp = data(7)
		oldname = data(11)
		
'# printer,comment,location,driver,sepfile,portname,ip,portcp,,,yes,oldname
		if instr (ucase(exclude_driver),ucase(driver))=0 then 
			ts.writeline oldname & "," & printername
			'if instr(ucase(Comment),"ADMIN") then 
			create_printer(Server)
		End If
	End If
Next
ts.close


'netstop "spooler",server
wscript.sleep 5000
'netstart "spooler",server
wscript.sleep 60000


wscript.echo Failed

Set objShell = nothing
Set fso = nothing


sub netstart (service,server)
	Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & server & "\root\cimv2")
	Set colServiceList = objWMIService.ExecQuery  ("Select * from Win32_Service where Name='" & service & "'")
	For Each objService in colServiceList
		errReturn = objService.StartService()
	Next
	Wscript.Sleep 20000
		
	Set colServiceList = objWMIService.ExecQuery("Associators of " & "{Win32_Service.Name='" & service & "'} Where " & "AssocClass=Win32_DependentService " & "Role=Dependent" )
	For Each objService in colServiceList
		objService.StartService()
	Next
	Set colServiceList = nothing
	Set objWMIService = nothing
End Sub

Sub netstop (service,server)
	Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & server & "\root\cimv2")
	Set colServiceList = objWMIService.ExecQuery("Associators of " & "{Win32_Service.Name='" & service & "'} Where " & "AssocClass=Win32_DependentService " & "Role=Antecedent" )
	For Each objService in colServiceList
		objService.StopService()
	Next
	
	Wscript.Sleep 20000

	Set colServiceList = objWMIService.ExecQuery ("Select * from Win32_Service where Name='" & service & "'")
	For Each objService in colServiceList
		errReturn = objService.StopService()
	Next
	Set colServiceList = nothing
	Set objWMIService = nothing
End Sub


Sub create_printer (Server)
	'Wscript.echo "Creating port " & portname & " on " & Server & " ..."
	Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & Server & "\root\cimv2")
	objWMIService.Security_.Privileges.AddAsString "SeLoadDriverPrivilege", True
	Set objNewPort = objWMIService.Get("Win32_TCPIPPrinterPort").SpawnInstance_
	objNewPort.Name = printername
	objNewPort.Protocol = 1
	objNewPort.HostAddress = ipadress
	if porttcp="515" then porttcp="9100"
	objNewPort.PortNumber = porttcp
	if instr(ucase(printername),"-HP-") or instr(ucase(printername),"-HPC-") or instr(ucase(printername),"-LEX-") then objNewPort.PortNumber = 9100
	objNewPort.SNMPEnabled = True
	objNewPort.Put_
	'Wscript.echo "Creating Printer " & printername & " on " & Server & " " & Now &" ..."
	'wscript.echo driver
		
	if instr(ucase(driver),"HP") or instr(ucase(driver),"LEXMARK") then
		'create with printmig
		
		'HP universal
		if instr(ucase(driver),"LASERJET")  then printmig_file= HPRV
		if instr(ucase(driver),ucase("HP Universal Printing"))  then printmig_file= HPRV
		
		'HP Business Inkjet 2300 PCL 5c
		if instr(ucase(driver),ucase("HP Business Inkjet 2300")) then printmig_file= HPC2300RV
		
		'HP Business Inkjet 2280 PCL 5C
		if instr(ucase(driver),ucase("HP Business Inkjet 2280")) then printmig_file= HPC2280RV
		
		'Lexmark universal
		if instr(ucase(driver),"LEX") then printmig_file = LEXRV
		
		'Lexmark T644
		if instr(ucase(driver),"LEX") and instr(ucase(Comment),"T644") then printmig_file= LEX644RV
		
		'creating the generic printer
		
		if FORCEMODE = "YES"  or instr(Listprn,printername & ";") = 0 then 
			
			'delete if the printer already exists in force mode
			if FORCEMODE = "YES" then 
				queue = Chr(34) & "\\" &  server & "\" & printername & Chr(34)
				'cmd = "RUNDLL32 PRINTUI.DLL,PrintUIEntry /dl /c" & "\\" &  Server & " /n " &  queue 
				objshell.run cmd,1,true
			end if
			
			'creating the generic printer
			cmd = PRINTMIG & " -i -r " & GENERIC_PATH & printmig_file & ".cab \\" & server
			'wscript.echo cmd
			objshell.run cmd,2,true
			
			'rename the printer
			cmd = "c:\windows\system32\cscript c:\windows\system32\prncnfg.vbs -x -s " & server & " -p " & printmig_file & " -z " & printername
			objshell.run cmd,1,true
		End If
		'updating parameters
		printui server,printername,"PrintProcessor","Winprint"
		printui server,printername,"Location",Location
		printui server,printername,"Comment",Comment
		printui server,printername,"Sharename",printername
		printui server,printername,"Attributes","Shared"
		printui server,printername,"PortName",portname
		wscript.sleep 500
				
	else
		if instr(ucase(Comment),"NRG MP 4500") then driver = "NRG MP 4500 PCL 6"
		if instr(ucase(Comment),"NRG MP 2000") then driver = "NRG MP 2000 PCL 6"
		if instr(ucase(Comment),"NRG MP C250") then driver = "NRG MP C2500 PCL 6"
		if instr(ucase(Comment),"NRG MP 5000") then driver = "NRG MP 5000 PCL 6"
		if instr(ucase(Comment),"NRG MP 7500") then driver = "NRG MP 7500 PCL 6"
		if instr(ucase(Comment),"RICOH AFICIO MP C2800") then driver = "RICOH Aficio MP C2800 PCL 6"
		Set objNewPrinter = objWMIService.Get("Win32_Printer").SpawnInstance_
		objNewPrinter.Name = printername
		objNewPrinter.DeviceID = printername
		objNewPrinter.Location = Location
		objNewPrinter.Network = "False"
		objNewPrinter.Shared = "True"
		objNewPrinter.Sharename = printername
		objNewPrinter.Comment = Comment
		objNewPrinter.SeparatorFile = PrinterSeparator
		objNewPrinter.PrintProcessor="WinPrint"
		objNewPrinter.DriverName = driver
		objNewPrinter.PortName = portname
		on error resume next
		err.clear
		objNewPrinter.Put_
		if err.number <> 0 then
			wscript.echo err.num & err.description
			Failed = Failed & line & chr(10)
			wscript.echo "Failed to create " & printername
			wscript.echo err.number & err.description
			wscript.echo line
		End if
		on error goto 0
	End If
	
	Set_A4 (Server)
	Set_duplex (Server)
	
	Set objNewPrinter = nothing
	Set objNewPort = nothing
	Set objWMIService = nothing
End Sub

sub printui(server,printername,what,text)
	queue = Chr(34) & "\\" &  server & "\" & printername & Chr(34)
	rundll32 = "RUNDLL32 PRINTUI.DLL,PrintUIEntry /Xs /c" & "\\" &  Server & " /n " &  queue 
	prtinfo = " " & what & " " & Chr(34) & text & Chr(34)
	cmd = rundll32 & prtinfo
	objshell.run cmd,1,true
End Sub
	
sub renameprinter (server,oldprintername,newprintername)
	'wmi connection
	set oLocator = CreateObject("WbemScripting.SWbemLocator")
	set oService = oLocator.ConnectServer(Server, strNameSpace, "", "")
	oService.Security_.impersonationlevel = 3
	oService.Security_.Privileges.AddAsString "SeLoadDriverPrivilege"
	
	'rename
	set oPrinter = oService.Get("Win32_Printer.Name='" & oldprintername & "'")
	oPrinter.RenamePrinter(newprintername)
	
	set oPrinter = nothing
	set oService = nothing
	set oLocator = nothing
End Sub

sub Set_duplex (Server)
		'Set Duplex Mode
		cmd = SETPRINTER & "\\" & Server & "\" & printername & " 8 " & chr(34) & "pdevmode=dmduplex=2" & chr(34)
		ObjShell.Run cmd,0,true
End sub

sub Set_1side (Server)
		'Set Duplex Mode
		cmd = SETPRINTER & "\\" & Server & "\" & printername & " 8 " & chr(34) & "pdevmode=dmduplex=1" & chr(34)
		ObjShell.Run cmd,0,true
End sub

sub Set_A4 (Server)
		'Set Paper A4
		cmd = SETPRINTER & "\\" & Server & "\" & printername & " 8 " & chr(34) & "pdevmode=dmPaperSize=9, dmPaperLength=2970, dmPaperWidth=2100, dmFormName=A4" & chr(34)
		ObjShell.Run cmd,0,true
End sub

Function List_printer (server)
	Set objWMIService = GetObject( "winmgmts://" & server & "/root/CIMV2" )
	Set colInstances = objWMIService.ExecQuery( "SELECT * FROM Win32_Printer", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly )
	For Each objInstance In colInstances
		printerlst = printerlst & objInstance.Name & ";"
	Next
	List_printer = printerlst			
End Function				
				
				
				
				