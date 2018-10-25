Import-Module ActiveDirectory
Import-Module ServerManager
$ErrorActionPreference = "SilentlyContinue"


Function path-UNC ([string] $IIsServer, $path) {
	if ($path.StartsWith('\\')) {
		return $path
		}
	else {
		return "\\{0}\{1}" -f $IIsServer,$path.Replace(':','$')
		}
	}

Function Get-IIsServers {
	Param([String[]]$Servers = $Env:Computername)     

	$IIsServers = @()
	$Servers = Get-ADComputer -Filter 'OperatingSystem -Like "Windows Server*"'
	$Servers | %{
		trap [Exception] {
			continue
			}
		$Server = $_.Split(',')[0].SubString(3)
		$wmi = gwmi win32_service -filter "name='IISAdmin'" -comp $Server
		if ($wmi) {
			"Found server " + $Server | Out-Host
			$IIsServers += $Server
			}
		}
	$IIsServers
	}
		
cls
"Please wait while retrieving IIS servers"
Get-IIsServers | %{
	$IIsSettings = Get-WmiObject  IIsWebVirtualDirSetting -ComputerName $_ -namespace 'root\microsoftiisv2' -Authentication 6
	for ($i = 0; $i -lt $IIsSettings.Length; $i++) {
		get-childitem $(path-UNC $IIsServer $IIsSettings[$i].Path) -Recurse -include *.pdb,*.refresh | Remove-Item
		}
	}