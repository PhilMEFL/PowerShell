On Error Resume Next

Const Server="s-ap502"
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
dim regdescription
dim DriverList

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

WshShell.exec "cmd /c mkdir " & exportfolder & "\" & Server & "\data"
WshShell.exec "cmd /c del " & exportfolder & "\" & Server &  "\data\*.* /s /q"
	
portlst= fetchportlist(server)
	
for each port in portlst
	portinfo= portinfo & fetchportinfo (server, port) & chr(10)
next
wscript.echo portinfo
portinfo= split (portinfo, chr(10))

Set tf = fso.CreateTextFile(exportfolder & "\" & Server & "\data\itic-all-printers.csv", True)
Set tw = fso.CreateTextFile(exportfolder & "\" & Server & "\data\itic-all-printers.log", True)

printerlst = fetchprinterlist(server)
for each prn in printerlst
	if prn <>"" then 
		'wscript.echo prn
		info = fetchprinterinfo (server, prn)
		if info <> ""  then tf.WriteLine info & "," & prn
	end If
Next
	
tf.Close
tw.Close
	
Set tdrv = fso.CreateTextFile(exportfolder & "\" & Server & "\data\Info-drivers.txt", True)
tdrv.writeline DriverList
tdrv.close

cmd = "cmd /c " & Winzip & " -min -a -ex " & exportfolder & "\" & strComputer & "\Printer_" & Server & "_" & mytime & ".zip " & exportfolder & "\" & strComputer & "\data\*.* "
	'wscript.echo cmd
	'WshShell.exec cmd
	
Set ti =  Nothing
Set oReg=Nothing
Set colInstances = Nothing
Set objWMIService = Nothing
Set tw = Nothing
Set tf = Nothing



Set fso = Nothing
Set WshShell = Nothing

function fetchprinterlist(server)
	list = ""
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & Server & "\root\default:StdRegProv" )
	keyreg= "SYSTEM\CurrentControlSet\Control\Print\Printers"
	oReg.Enumkey HKEY_LOCAL_MACHINE, keyreg, subkeys
	for each key in subkeys
		list = list & key & ";"
	Next
	fetchprinterlist = split (list,";")
End Function

Function fetchprinterinfo (server, printer)
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & Server & "\root\default:StdRegProv" )
	keyreg= "SYSTEM\CurrentControlSet\Control\Print\Printers\" & printer
	oReg.EnumValues HKEY_LOCAL_MACHINE, keyreg, arrValueNames, arrValueTypes
	For I=0 To UBound(arrValueNames)
		Select Case arrValueTypes(I)
			Case REG_SZ
				oReg.GetStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_SZ & ";" & arrValue 
	        Case REG_EXPAND_SZ
	            oReg.GetExpandedStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_EXPAND_SZ & ";" & arrValue 

	        Case REG_BINARY
	            oReg.GetBinaryValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				x = 0
				for each mValue in arrValue
					arrValue(x) = cstr(mValue)
					x = x + 1
				Next
				arrValue = join (arrValue, ",")
				mydata = arrValueNames(I) & ";" & REG_BINARY & ";" & arrValue 

	        Case REG_DWORD
	            oReg.GetDwordValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_DWORD & ";" & arrValue 

	        Case REG_MULTI_SZ
	            oReg.GetMultiStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValues
				mydata = arrValueNames(I) & ";" & REG_MULTI_SZ & ";"
				reginfo = ""
				'Multiline separatore as #####
				For Each strValue In arrValues
					mydata = mydata & strValue & "#####"
				Next
				mydata = left (mydata,len(mydata) -5)
	    End Select 
		if arrValueNames(I) = "Description" then comment =cleanup(replace ( arrValue , "," , ";"))
		if arrValueNames(I) = "Location" then Location = cleanup(arrValue)
		if arrValueNames(I) = "Port" then port = arrValue
		if arrValueNames(I) = "Separator File" then sepfile = arrValue
		if arrValueNames(I) = "Printer Driver" then driver = arrValue
		if instr(DriverList,Driver)=0 then DriverList=DriverList & Driver & vbNewLine
	next
	Loc=""
	Loc2=""
	if Location <> "" and Comment <> "" then 
		Loc = split(Location,"/")
		if UBound(Loc) >2 then Loc2=Loc(2)
		if driver <> "" then
			newprintername = "P-" & GenerateName(comment,driver)
			newloc = newlocation(location,comment)
			newcomment=generatecomment(comment,newloc,driver) & " - OldName : " & printer
			if instr(ucase(driver),"LASERJET") then driver = "HP Universal Printing PCL 6 (v5.1)"
			if instr(ucase(driver),"LEXMARK") then driver = "Lexmark Universal XL"
			if instr(ucase(driver),"LEXMARK") and instr(comment,"T644") then driver = "Lexmark T644 PS3"
			if instr(ucase(driver),"NRG") or instr(ucase(driver),"RICOH") then driver = "PS Driver for Universal Print"
			fetchprinterinfo =  newprintername  & "," & newcomment & "," & newloc & "," & driver & "," & sepfile & "," & port & "," & _
				portIP(port) & "," & portTCP(port) & ",," & Loc2 & ",Yes"
			wscript.echo printer & "	" & newprintername & "	" & Driver
			tw.writeline printer & "	" & newprintername & "	" & Driver
		else
			fetchprinterinfo = ""
		End If
	End If
End function

Function generatecomment(mycomment,myloc,mydriver)
	'cleanup driver name
	thedriver=replace(ucase(mydriver),"PCL6","")
	thedriver=replace(ucase(thedriver),"PCL 6","")
	thedriver=replace(ucase(thedriver),"PCL 5","")
	thedriver=replace(ucase(thedriver),"PS3","")
	thedriver=replace(ucase(thedriver),"PS","")
	'thedriver=replace(ucase(thedriver),"XL","")
	theloc=mid(myloc,5)
	if instr(ucase(mycomment),"02DI") then
		inv = "INV:" & mid(ucase(mycomment),instr(ucase(mycomment),"02DI"))
	else
		inv = "INV:02DIxxxxxxxxxxx"
	end if
	generatecomment=thedriver & " - " & myloc  & " - " & inv
End Function

Function newlocation(myloc,mycomment1)
	myloc=split(myloc,"/")
	mycom=split(mycomment1,";")
	newlocation=ucase(myloc(0)) & "/" & ucase(myloc(1)) & "/" & ucase(myloc(2)) & "/" & ucase(myloc(3)) & "/" &  ucase(mycom(2))
End Function

Function GenerateName(myloc1,drv)
	prexist= TRUE
	X=0
	myloc=split(myloc1,";")
	do while prexist
		if X=0 then 
			prnum = ""
		else
			prnum = "." & X
		End if
		mygname=ucase(myloc(0)) & "." & ucase(myloc(1)) & "." & ucase(myloc(2)) &  FindFunction(drv) & prnum
		if instr(prnewlist,mygname & ";") then
			X = X + 1
		else
			prexist= FALSE
		End If
	Loop
	mygname=replace(mygname," ","")
	GenerateName=trim(mygname)
End Function

Function FindFunction(prdrv)
	myfunct = ".UNKNONW"
	if instr(ucase(prdrv),"LASERJET") or instr(ucase(prdriver),"HP UNIVERSAL PRINTING") then myfunct = ".HP"
	if instr(ucase(prdrv),"NRG") or instr(ucase(prdrv),"LANIER") or instr(ucase(prdrv),"RICOH") then myfunct = ".COPIER"
	if instr(ucase(prdrv),"XEROX") or instr(ucase(prdrv),"INKJET") or instr(ucase(prdrv),"NRG MP C2500") or instr(ucase(prdrv),"COLOR") then myfunct = ".COLOUR"
	'if instr(ucase(prdrv),"OFFICEJET") or instr(ucase(prdrv),"DESIGNJET") then myfunct = ".PLOTTER"
	'if instr(ucase(prdrv),"VARIOPRINT") then myfunct = ".OFFSET"
	if instr(ucase(prdrv),"LEXMARK") then myfunct = ".LEX"
	FindFunction=myfunct
End Function	

Function fetchportlist(server)
	list = ""
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & Server & "\root\default:StdRegProv" )
	keyreg= "SYSTEM\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports"
	oReg.Enumkey HKEY_LOCAL_MACHINE, keyreg, subkeys
	for each key in subkeys
		list = list & key & ";"
	Next
	fetchportlist = split (list,";")
End Function

Function fetchportinfo (server, port)
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & Server & "\root\default:StdRegProv" )
	keyreg= "SYSTEM\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports\" & port
	oReg.EnumValues HKEY_LOCAL_MACHINE, keyreg, arrValueNames, arrValueTypes
	For I=0 To UBound(arrValueNames)
		Select Case arrValueTypes(I)
			Case REG_SZ
				oReg.GetStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_SZ & ";" & arrValue 
	        Case REG_EXPAND_SZ
	            oReg.GetExpandedStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_EXPAND_SZ & ";" & arrValue 

	        Case REG_BINARY
	            oReg.GetBinaryValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				x = 0
				for each mValue in arrValue
					arrValue(x) = cstr(mValue)
					x = x + 1
				Next
				arrValue = join (arrValue, ",")
				mydata = arrValueNames(I) & ";" & REG_BINARY & ";" & arrValue 

	        Case REG_DWORD
	            oReg.GetDwordValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_DWORD & ";" & arrValue 

	        Case REG_MULTI_SZ
	            oReg.GetMultiStringValue HKEY_LOCAL_MACHINE, keyreg,arrValueNames(I) ,arrValue
				mydata = arrValueNames(I) & ";" & REG_MULTI_SZ & ";"
				reginfo = ""
				'Multiline separatore as #####
				For Each strValue In arrValues
					mydata = mydata & strValue & "#####"
				Next
				mydata = left (mydata,len(mydata) -5)
	    End Select 
		if arrValueNames(I) = "IPAddress" then ip = arrValue 
		if arrValueNames(I) = "PortNumber" then tcpp = arrValue
	next
	fetchportinfo = port & ";" & ip & ";" & tcp
End function


Function cleanup (myString)
		if myString <> "" then
			myString= replace (myString, Chr(10),"")
			myString= replace (myString, Chr(13),"")
			myString= Trim (myString)
		End If
		cleanup=myString
End Function


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
			if portline(2) = "" then 
				portTCP = "9100"
				else
				portTCP=portline(2)
			End if
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