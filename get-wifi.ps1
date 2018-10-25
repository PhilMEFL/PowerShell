function get-SSIDPWD {
	[string](netsh wlan show profiles name=([string](netsh wlan show interface | sls “\sSSID”) | sls “\:.+”| %{$_.Matches} | %{$ssid = $_.Value -replace “\:\s+”; $ssid}) key=clear | sls “Key Content”) | sls “\:.+”| %{$_.Matches} | %{$pass= $_.Value -replace “\:\s”}; $ssid
	}

