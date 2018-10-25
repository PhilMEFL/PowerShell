function Get-WifiNetwork {
	end {
		netsh wlan sh profiles | % -process {
			if ($_ -match 'current') {
				$_.Substring($_.LastIndexOf(':') + 2)
				}
			else {
				if ($_ -match '^\s+(.*)\s+:\s+(.*)\s*$') {
					$current[$matches[1].trim()] = $matches[2].trim()
					}
				}
			} -begin { $networks = @() } -end { $networks|% { new-object psobject -property $_ } }
		}
	}