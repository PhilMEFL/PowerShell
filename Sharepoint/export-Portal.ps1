cls
$RootSite = 'https://portal.gpco.be'
$ExportPath = '\\copfps01\d$\COPS01Data'
$Webs = Get-SPWeb -Site $RootSite #-Filter { $_.Template -like "*" } -Limit ALL
$Result = @()
#Get-SPSite $rootsite | Get-SPWeb | %{
#Get-SPWeb $RootSite | %{
Get-SPWebApplication | Get-SPSite | %{
	$spSite = $_
    $_.AllWebs | %{
		$_.Name
		if ($_.IsRootWeb) {
			$SPRootWeb = $_
			}
		if ($_.ParentWeb) {
			if ($_.ParentWebId -ne $SPLastWeb.Id) {
				$strWeb = "{0}/{1}/{2}" -f $SPRootWeb.Url, $_.ParentWeb, $_.Name
				}
			else {
				$strWeb += "/{0}" -f $_.Name
				}			
			}
		else {
			$strWeb = $_.Url
			}
		""
		$strWeb
		$_.lists | % {
			$_.ParentWeb
			if ($_.ParentWeb.Url -ne 'http://copsp01/dms/lnb') {
				if (!$_.Hidden) {
				$_.GetType().Name
					if ($_.GetType().Name -eq 'SPList') {
						$strSite = "/Lists/{0}" -f $_.Title
						}
					else {
						$strSite = "{0}" -f $_.RootFolder.Name
						}
					$strSite
#					"{0}\{1}\{2}" -f $ExportPath, $strWeb, $_.Title
					$ExpDest = "{0}\{1}\{2}" -f $ExportPath, $_.parentWeb, $_.Title
					New-Item -Path $ExpDest -ItemType Directory -Force | Out-Null
					$ExpFile = "{0}\{1}.cmp" -f $expDest, $_.Title
					$strList = "/{0}{1}" -f $strType, $_.Title
					"export-spWeb -Identity $strWeb -ItemUrl $strSite"
					export-spWeb -Identity $strWeb -ItemUrl $strSite -path $expFile -IncludeVersions all -IncludeUserSecurity -Force
					$tata = 'toto'
					}
				}
			}
		$SPLastWeb = $_
        }
	}
#	$tata = 'toto'
#	}
#Example one - exporting a list that exists in the root site collection:
#Export-SPWeb -Identity http://content.contoso.cloud -ItemUrl /lists/testlist -Path "c:\export\export1.cmp"
#Example two - exporting a list from a site collection that is not root:
#Export-SPWeb -Identity http://content.contoso.cloud/sites/site-collection2/ -ItemUrl lists/testlist2 -Path "c:\export\export2.cmp"
#Example three - exporting a list that exists in a sub site, in a site collection that is not root:
#Export-SPWeb -Identity http://content.contoso.cloud/sites/site-collection2/sub1/ -ItemUrl lists/testlist3 -Path "c:\export\export3.cmp"	