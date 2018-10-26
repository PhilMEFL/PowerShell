$ExportPath = "\\copsp01N\c$\Temp"
Get-SPWeb -site 'https://portal.gpco.be' -Limit ALL | %{ 
	$_.url
	"{0}.cmp" -f $_.title
	$_.Url.replace('https://', '').replace("_", "_").replace('/', '_') + '.cmp'
	$filename = "{0}\{1}" -f $ExportPath, $_.Title
	Export-SPWeb $_.Url -path $filename
	}
	
