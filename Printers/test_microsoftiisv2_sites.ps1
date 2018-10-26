cls
function path-UNC ([string] $IIsServer, $path) {
	if ($path.StartsWith('\\')) {
		return $path
		}
	else {
		return "\\{0}\{1}" -f $IIsServer,$path.Replace(':','$')
		}
	}

$IIsServer = "ERGOBRUSRVM143"
$IIsSettings = Get-WmiObject  IIsWebVirtualDirSetting -ComputerName $IIsServer -namespace 'root\microsoftiisv2' -Authentication 6 

foreach ($iisapp in $IIsSettings) {
	get-childitem $(path-UNC $IIsServer $iisapp.Path) -Recurse -include *.pdb,*.refresh
	#| Remove-Item
	}

