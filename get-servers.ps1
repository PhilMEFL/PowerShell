function get-servers {
	$strDC = 'OU=Domain Controllers,DC={0},DC={1}' -f $env:USERDNSDOMAIN.substring(0,$env:USERDNSDOMAIN.indexof('.')), $env:USERDNSDOMAIN.substring($env:USERDNSDOMAIN.indexof('.') + 1)

#    $strSRV = 'OU=Servers,DC={0},DC=intl' -f $env:USERDOMAIN
    
    $Srvs = get-adcomputer -Filter * -properties * -SearchBase $strDC
#	$Srvs += get-adcomputer -Filter * -properties * -SearchBase $strSRV

	$Srvs = $Srvs | where {(!($_.servicePrincipalName -match 'VirtualServer'))} | sort Name
	$Srvs
	}
cls
$SRVs = Get-ADComputer -LDAPFilter “(&(objectcategory=computer)(OperatingSystem=*server*))”  
$SRVs.Name
#(get-servers).Name