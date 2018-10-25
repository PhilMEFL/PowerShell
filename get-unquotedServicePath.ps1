cls
$Srvs = get-adcomputer -Filter * -properties * -SearchBase "OU=Domain Controllers,DC=gpco,DC=local"
$Srvs += get-adcomputer -Filter * -properties * -SearchBase "OU=CO_Servers,DC=gpco,DC=local"

$Srvs = $Srvs | where {(!($_.servicePrincipalName -match 'VirtualServer'))} | sort Name 
$Srvs | %{
	$srv = $_.Name
	"Unquoted service path on {0}" -f $srv
	Get-WmiObject -ComputerName $srv Win32_Service | Where {  $_.PathName -notlike "`"*`"*" } | %{
		$svcPath = $_.pathName.split(' ')
		if (!(Test-Path $svcPath[0].ToLower().Replace('c:\','\\' + $srv + '\c$\'))) {
			$svcPath[0]
			'wrong'
			}
		}
	$tata = 'toto'
	}

## Find all Program Files paths without quotes
#$a = Get-WmiObject -Class Win32_Service -Property PathName | Where { $_.PathName -like "*Program Files*" -and $_.PathName -notlike "`"*`"*" }
#foreach ($i in $a)
#{
#    $i.PathName = $('"' + $i.PathName + '"')
#    (Get-WmiObject -Class Win32_Service).Put()
#    Write-Output $("Fixed " + $i.PathName)
#}

#GET-SVCpath.ps1
function GET-SVCpath {
[cmdletbinding()]
	Param ( #Define a Mandatory name input
	[Parameter(
	ValueFromPipeline=$true,
	ValueFromPipelinebyPropertyName=$true, 
	Position=0)]
	[Alias('Computer', 'ComputerName', 'Server', '__ServerName')]
		[string[]]$name = $ENV:Computername,
	[Parameter(Position=1)]
		[string]$progress = "Yes"
	) #End Param
 
Process
{ #Process Each object on Pipeline
	ForEach ($computer in $name)
	{ #ForEach for singular or arrayed input on the shell
	  #Try to get SVC Paths from $computer
	Write-Progress "Done" "Done" -Completed #clear progress bars inherited from the pipeline
	if ($progress -eq "Yes"){ Write-Progress -Id 1 -Activity "Getting keys for $computer" -Status "Connecting..."}
	$result = REG QUERY "\\$computer\HKLM\SYSTEM\CurrentControlSet\Services" /v ImagePath /s 2>&1
	#Error output from this command doesn't catch, so we need to test for it...
	if ($result[0] -like "*ERROR*" -or $result[0] -like "*Denied*")
		{ #Only evals true when return from reg is exception
		if ($progress -eq "Yes"){ Write-Progress -Id 1 -Activity "Getting keys for $computer" -Status "Connection Failed"}
		$obj = New-Object -TypeName PSObject
		$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $computer
		$obj | Add-Member -MemberType NoteProperty -Name Status -Value "REG Failed"
		$obj | Add-Member -MemberType NoteProperty -Name Key -Value "Unavailable"
		$obj | Add-Member -MemberType NoteProperty -Name ImagePath -Value "Unavailable"
		[array]$collection += $obj
		}	
	else
		{
		#Clean up the format of the results array
		if ($progress -eq "Yes"){ Write-Progress -Id 1 -Activity "Getting keys for $computer" -Status "Connected"}
		$result = $result[0..($result.length -2)] #remove last (blank line and REG Summary)
		$result = $result | ? {$_ -ne ""} #Removes Blank Lines
		$count = 0
		While ($count -lt $result.length)
			{
 			if ($progress -eq "Yes"){ Write-Progress -Id 2 -Activity "Processing keys..." -Status "Formatting $computer\$($result[$count])"}
			$obj = New-Object -Typename PSObject
			$obj | Add-Member -Membertype NoteProperty -Name ComputerName -Value $computer
			$obj | Add-Member -MemberType NoteProperty -Name Status -Value "Retrieved"
			$obj | Add-Member -MemberType NoteProperty -Name Key -Value $result[$count]
			$pathvalue = $($result[$count+1]).Split("", 11) #split ImagePath return
			$pathvalue = $pathvalue[10].Trim(" ") #Trim out white space, left with just value data
			$obj | Add-Member -MemberType NoteProperty -Name ImagePath -Value $pathvalue
 
			[array]$collection += $obj
 
			$count = $count + 2
			} #End While
		} #End Else
	if ($progress -eq "Yes"){Write-Progress -Id 2 "Done" "Done" -Completed}
	Write-Output $collection
	$collection = $null #reset collection
	} #End ForEach
	if ($progress -eq "Yes"){Write-Progress -Id 1 "Done" "Done" -Completed}
 
} #End Process
}
#GET-SVCpath COEPBKP01