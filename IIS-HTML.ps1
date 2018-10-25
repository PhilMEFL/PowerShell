$server = 'ergobrusrvm144'
#Read-Host Enter server name...

if (!(test-connection -computername $server -quiet)) { 
	Write-Host $server is not pingable, does not exist, or timed out. Please try a different server.
	}
else  {
	$command = {
		add-pssnapin WebAdministration

		function get-iiswp([string]$name="*") {
			$list = get-process w3wp -ea SilentlyContinue
			if ($error) {
				Write-Host There are no IIS worker processes currently running. Error Message: $error
				}
			else {
				foreach($p in $list) {
					$filter = "Handle='" + $p.Id + "'"
                	$wmip = get-WmiObject Win32_Process -filter $filter 
					if($wmip.CommandLine -match "-ap `"(.+)`"") {
						$appName = $matches[1]
						$p | add-member NoteProperty AppPoolName $appName
						}
				} 
			$list | where { $_.AppPoolName -like $name }
			}
		}
	
		get-iiswp | select-object -property * 
		}
		invoke-command -computername $server -scriptblock $command | ConvertTo-HTML ID, @{Label="AppPoolName";Expression={ '&lt;a href="http://powershell.com/requests.ps1x?PID=$($_.PID)&amp;AppPoolName=$($_.AppPoolName)"&gt;$($_.AppPoolName)&lt;/a&gt;' }, @{Label="CPU(s)";Expression={if ($_.CPU -ne $()) {$_.CPU.ToString("N")}}}, @{Label="Virtual Memory";Expression={[int]($_.VM/1MB)}}, @{Label="Physical Memory";Expression={[int]($_.WS/1024)}} | Out-file test.html
		} 
	
	}
#@{Label="AppPoolName";Expression={ '&lt;a href="http://powershell.com/requests.ps1x?PID=$($_.PID)&amp;AppPoolName=$($_.AppPoolName)"&gt;$($_.AppPoolName)&lt;/a&gt;' }}
