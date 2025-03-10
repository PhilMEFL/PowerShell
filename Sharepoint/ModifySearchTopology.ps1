Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue

#Admin Database 
$ssa = Get-SPEnterpriseSearchServiceApplication 'Search Service Application'
Set-SPEnterpriseSearchServiceApplication –Identity $ssa –FailoverDatabaseServer copsp01

#Crawl Database 
$CrawlDatabase0 = ([array]($ssa | Get-SPEnterpriseSearchCrawlDatabase))[0] 
Set-SPEnterpriseSearchCrawlDatabase -Identity $CrawlDatabase0 -SearchApplication $ssa -FailoverDatabaseServer '<failoverServerAlias\instance>'

#Links Database 
$LinksDatabase0 = ([array]($ssa | Get-SPEnterpriseSearchLinksDatabase))[0] 
Set-SPEnterpriseSearchLinksDatabase -Identity $LinksDatabase0 -SearchApplication $ssa -FailoverDatabaseServer '<failoverServerAlias\instance>'

#Analytics database 
$AnalyticsDB = Get-SPDatabase –Identity SharePointStore
$AnalyticsDB.AddFailOverInstance(“failover alias\instance”) 
$AnalyticsDB.Update()
