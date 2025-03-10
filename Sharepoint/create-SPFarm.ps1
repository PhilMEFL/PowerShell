New-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa -Name "DisableLoopbackCheck"  -value "1" -PropertyType dword

New-SPConfigurationDatabase `
    –DatabaseName 'COCSP02_SP_Config' `
    –DatabaseServer 'COCSP02\SHAREPOINT' `
    –AdministrationContentDatabaseName 'COCSP02_SP_Sites_AdminContent' `
    –Passphrase (ConvertTo-SecureString 'SharePoint_2017_P@ssPhr@se' –AsPlaintext –Force) `
    –FarmCredentials (Get-Credential)

Install-SPHelpCollection -All

Initialize-SPResourceSecurity

Install-SPService

Install-SPFeature –AllExistingFeatures

New-SPCentralAdministration -Port 9999  -WindowsAuthProvider 'NTLM'

Install-SPApplicationContent

psconfig.exe -cmd adminvs -unprovision 

psconfig.exe -cmd adminvs -provision -port 9999 -windowsauthprovider onlyusentlm 