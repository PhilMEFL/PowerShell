Import-Module ActiveDirectory
Import-Csv "C:\Users\pmartin\documents\OT users to acceptance environment 20150202.csv" | ForEach-Object {
    $intPos = $_.Name.indexof(' ')
	$strUserPrcpl = ($_.Name[0] + $_.Name.substring($intPos) -replace('[^a-zA-Z]','')).toLower() + "@gpcocat.local"
    'Name: ' + $_.Name
	'SurName: ' + $_.Name.Split(' ')[0]
	'GivenName: ' + $_.Name.Substring($_.Name.indexOf(' ') + 1)
	'Path: ' + 'OU=CAT_Users,DC=gpcocat,DC=local'
	'SamAcc: ' + $strUserPrcpl.Substring(0,$strUserPrcpl.IndexOf('@'))
	'UserPrincipalName: ' +  $strUserPrcpl
	'AccountPassword: ' + (ConvertTo-SecureString 'Welcome2015' -AsPlainText -Force)
	New-ADUser -Name $_.Name `
               -DisplayName $_.Name`
               -GivenName $_.Name.Split(' ')[0] `
               -SurName $_.Name.Split(' ')[1] `
               -Description $_.Description `
               -Path 'OU=CAT_Users,DC=gpcocat,DC=local' `
               -SamAccountName $strUserPrcpl.Substring(0,$strUserPrcpl.IndexOf('@')) `
               -UserPrincipalName $strUserPrcpl `
               -AccountPassword (ConvertTo-SecureString 'Welcome2015' -AsPlainText -Force) `
               -ChangePasswordAtLogon $true `
               -Enabled $true
	Add-ADGroupMember "Domain Admins" $_."samAccountName";
	}
