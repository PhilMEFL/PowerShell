On Error Resume Next

Const Serverlist="S-ci-prtbxl"
Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly       = &h20
Const ForWriting = 2
'Const exportfolder="\\net1\CI\Common\ITIC_PRINT\scripts\export_data"
Const exportfolder="\\s-ci-mgtj01\LSA\_Scripts\martiqh\printer\export_data"
const HKEY_LOCAL_MACHINE = &H80000002
const REG_SZ = 1
const REG_EXPAND_SZ = 2
const REG_BINARY = 3
const REG_DWORD = 4
const REG_MULTI_SZ = 7
WinZip = chr(34) & "C:\Program Files\WinZip\Winzip32.exe" & chr(34)


Dim portinfo
Dim fso, tf

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

list=split(Serverlist,";")
for each strComputer in list

	WshShell.exec "cmd /c mkdir " & exportfolder & "\" & strComputer & "\data"
	WshShell.exec "cmd /c del " & exportfolder & "\" & strComputer &  "\data\*.* /s /q"

	Set objWMIService = GetObject( "winmgmts://" & strComputer & "/root/CIMV2" )
	Set colInstances = objWMIService.ExecQuery( "SELECT * FROM Win32_TCPIPPrinterPort", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly )
	portinfo=""
	For Each objInstance In colInstances
			IPadress = objInstance.HostAddress
			portname = objInstance.Name
			portnum = objInstance.PortNumber
			portinfo = portinfo & portname & ";" & IPadress & ";" & portnum & Chr(10)
	Next
	Set colInstances = Nothing
	Set objWMIService = Nothing
	portinfo= split (portinfo, Chr(10))

	
	Set tf = fso.CreateTextFile(exportfolder & "\" & strComputer & "\data\itic-all-printers.csv", True)
	Set tw = fso.CreateTextFile(exportfolder & "\" & strComputer & "\data\itic-all-printers.log", True)



	Set objWMIService = GetObject( "winmgmts://" & strComputer & "/root/CIMV2" )
	Set colInstances = objWMIService.ExecQuery( "SELECT * FROM Win32_Printer", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly )

	
	Driverlist=""
	For Each objInstance In colInstances
				printername = objInstance.Name
				prtlist=prtlist & printername & ";"
				wscript.echo "\\" & strComputer & "\" &printername
				Comment = replace (cleanup(objInstance.Comment),",", " - ")
				Location = cleanup(objInstance.Location)
				'If Left(Location,1) = "/" Then Location = Right (Location ,Len(Location)-1) 'Correction for echo printers
				Driver = cleanup(objInstance.DriverName)
				if instr(DriverList,Driver)=0 Then 
					DriverList=DriverList & Driver & vbNewLine
				End if
				portname = cleanup(objInstance.Portname)
				If InStr(printername,portname) = 0 Then 
					tw.WriteLine "Warning !!! The portname of " & printername &" is incorrect : " & portname
				End if
				Separator = cleanup(objInstance.SeparatorFile)
				Loc=""
				Loc2=""
				if Location <> "" then 
					Loc = split(Location,"/")
					if UBound(Loc) >2 Then 
						Loc2=Loc(2)
					End if
				End If
				CVS = printername & "," & Comment & "," & Location & "," & Driver
				
				CVS2 = "," & Separator & "," & portname & "," & portIP(portname) & "," & portTCP(portname) & ",," & Loc2 & ",Yes"
				tf.WriteLine CVS & CVS2 & "," & printername
				PrinterDriverData
				Printerdefault
	Next		

	tf.Close
	tw.Close
	
	Set tdrv = fso.CreateTextFile(exportfolder & "\" & strComputer & "\data\Info-drivers.txt", True)
	tdrv.writeline DriverList
	tdrv.close
	
	Set ti = fso.CreateTextFile(exportfolder & "\" & strComputer & "\data\Info-printers.txt", True)
	Set objWMIService = GetObject( "winmgmts://" & strComputer & "/root/CIMV2" )
	Set colInstances = objWMIService.ExecQuery( "SELECT * FROM Win32_PrinterConfiguration", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly )
	
	For Each objInstance In colInstances
		Color=objInstance.Color
		Duplex=objInstance.Duplex
		Name=objInstance.Name
		ti.writeline Name & ";" & Duplex & ";" & Color
	Next
	ti.Close
	
	
	cmd = "cmd /c " & Winzip & " -min -a -ex " & exportfolder & "\" & strComputer & "\Printer_" & strComputer & "_" & mytime & ".zip " & exportfolder & "\" & strComputer & "\data\*.* "
	'wscript.echo cmd
	WshShell.exec cmd
	
	Set ti =  Nothing
	Set oReg=Nothing
	Set colInstances = Nothing
	Set objWMIService = Nothing
	Set tw = Nothing
	Set tf = Nothing

Next

Set fso = Nothing
Set WshShell = Nothing


Function cleanup (myString)
		if myString <> "" then
			myString= replace (myString, Chr(10),"")
			myString= replace (myString, Chr(13),"")
			myString= Trim (myString)
		End If
		cleanup=myString
End Function


Sub Printerdefault
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv" )
	keyreg= "SYSTEM\CurrentControlSet\Control\Print\Printers\" & printername
	Set td = fso.CreateTextFile(exportfolder & "\" & strComputer & "\data\" & printername & ".default", True)
	oReg.EnumValues HKEY_LOCAL_MACHINE, keyreg, arrValueNames, arrValueTypes
	For I=0 To UBound(arrValueNames)
		Select Case arrValueTypes(I)
	        Case REG_SZ
	            'oReg.GetBinaryValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				oReg.GetStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_SZ & ";" & arrValue 
				td.writeLine mydata
	        Case REG_EXPAND_SZ
	            oReg.GetExpandedStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_EXPAND_SZ & ";" & arrValue 
				td.writeLine mydata
	        Case REG_BINARY
	            oReg.GetBinaryValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				x = 0
				for each mValue in arrValue
					arrValue(x) = cstr(mValue)
					x = x + 1
				Next
				arrValue = join (arrValue, ",")
				mydata = arrValueNames(I) & ";" & REG_BINARY & ";" & arrValue 
				td.writeLine mydata	
	        Case REG_DWORD
	            oReg.GetDwordValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_DWORD & ";" & arrValue 
				td.writeLine mydata
	        Case REG_MULTI_SZ
	            oReg.GetMultiStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_MULTI_SZ & ";"
				'Multiline separatore as #####
				For Each strValue In arrValues
					mydata = mydata & strValue & "#####"
				Next
				mydata = left (mydata,len(mydata) -5)
				td.writeLine mydata
	    End Select 
	Next	
	
	
	td.close
	Set td = Nothing
End Sub

Sub PrinterDriverData
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv" )
	keyreg= "SYSTEM\CurrentControlSet\Control\Print\Printers\" & printername & "\PrinterDriverData"
	Set td = fso.CreateTextFile(exportfolder & "\" & strComputer & "\data\" & printername & ".dat", True)
	oReg.EnumValues HKEY_LOCAL_MACHINE, keyreg, arrValueNames, arrValueTypes
	For I=0 To UBound(arrValueNames)
		Select Case arrValueTypes(I)
	        Case REG_SZ
	            'oReg.GetBinaryValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				oReg.GetStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_SZ & ";" & arrValue 
				td.writeLine mydata
	        Case REG_EXPAND_SZ
	            oReg.GetExpandedStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_EXPAND_SZ & ";" & arrValue 
				td.writeLine mydata
	        Case REG_BINARY
	            oReg.GetBinaryValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				x = 0
				for each mValue in arrValue
					arrValue(x) = cstr(mValue)
					x = x + 1
				Next
				arrValue = join (arrValue, ",")
				mydata = arrValueNames(I) & ";" & REG_BINARY & ";" & arrValue 
				td.writeLine mydata	
	        Case REG_DWORD
	            oReg.GetDwordValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_DWORD & ";" & arrValue 
				td.writeLine mydata
	        Case REG_MULTI_SZ
	            oReg.GetMultiStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_MULTI_SZ & ";"
				'Multiline separatore as #####
				For Each strValue In arrValues
					mydata = mydata & strValue & "#####"
				Next
				mydata = left (mydata,len(mydata) -5)
				td.writeLine mydata
	    End Select 
	Next	
	
	
	td.close
	Set td = Nothing
End Sub



Function portIP(portname)
	For each portline In portinfo
		If InStr(portline,portname) Then 
			portline = split (portline,";")
			portIP=portline(1)
		End If
	Next

End Function

Function portTCP(portname)
	For each portline in portinfo
		If InStr(portline,portname) Then 
			portline = split (portline,";")
			portTCP=portline(2)
		End If
	Next

End Function
			
			
Function PrinterCVS(printername)
	prname=split(printername,"-")
	Part1=prname(0) & "-" & prname(1) & "," & Left(prname(2),1) & "," & CStr( CInt(Right(prname(2),5)))
	
	Part2=""
	i=0
	For each prtemp in prname
			If i > 2 Then
				Part2=Part2 & prtemp & "-"
			End If
	i = i + 1
	Next
	If Part2 <> "" Then Part2=Left (Part2,Len(Part2)-1)
	PrinterCVS=Part1 & "," & Part2
End Function

Function mytime
	myday= Right("0" & Day(Now),2)
	mymonth= Right("0" & Month(Now),2)
	myyear= Year(Now)
	myhour= Right("0" & Hour(Now),2)
	myminute= Right("0" & Minute(Now),2)
	mysecond= Right("0" & Second(Now),2)
	mytime=myday & "-" & mymonth & "-" & myyear & "_" & myhour & "h" & myminute & "m" & mysecond & "s"
End Function