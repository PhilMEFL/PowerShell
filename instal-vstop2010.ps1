$servers = 'COHFLEX2','COHKSTEENSMA', 'COHBWILLEMAERS','COHDDESMET','COHNOCKET'
$sb = {'\\copfps01\Software Repository\Microsoft\vstor_redist.exe'}
$servers | %{
	$_
	Test-WSMan $_
#	$sess = New-PSSession $_
	invoke-command -ComputerName $_  -ScriptBlock $sb
	}

