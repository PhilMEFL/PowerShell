Get-ADUser -Properties * -Filter {(Enabled -eq $false)} | %{
	if ($_.LastLogonDate) {
		"{0},{1}" -f $_.Name, $_.LastLogonDate.ToShortDateString()
		}
	else {
		"{0}" -f $_.Name
		}
	}