# Upgrade-SPContentDatabase COCSP02_SP_Config
Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue
 $SSA = Get-SPEnterpriseSearchServiceApplication
 $SSA.Delete()