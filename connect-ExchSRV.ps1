$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://seuscexc03.shurgard.intl/PowerShell/  -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session -DisableNameChecking

