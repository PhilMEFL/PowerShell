$arrDB = @('Secure_Store_Service_DB_e83030bc74a54186a4592970622f883a',
'Search_Service_Application_AnalyticsReportingStoreDB_8278b343b2514375a0e539ec1aabb649',
'Bdc_Service_DB_fdfdb262b3f04818bcdaac5630f8f6aa',
'SharePoint_Config',
'Search_Service_Application_CrawlStoreDB_1fe7fd4290174571a3f486d39d628eae',
'AppMng_Service_DB_fa0d3123e719447e93bad948e40717c7',
'SharePoint_AdminContent_d5909768-1b57-432f-9c4d-dd3cb7430932',
'Search_Service_Application_DB_bc8e35dcbabd43f2b46cbf71b75a330c',
'WSS_UsageApplication',
'Search_Service_Application_LinksStoreDB_a3b17fc8163441f49221e52f1a7f062f')

$arrDB | %{
    Upgrade-SPContentDatabase $_
    }