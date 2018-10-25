Function Get-AllDomains
{
$Root = [ADSI]"LDAP://RootDSE"
$oForestConfig = $Root.Get("configurationNamingContext")
$oSearchRoot = [ADSI]("LDAP://CN=Partitions," + $oForestConfig)
$AdSearcher = [adsisearcher]"(&(objectcategory=crossref)(netbiosname=*))"
$AdSearcher.SearchRoot = $oSearchRoot
$domains = $AdSearcher.FindAll()
return $domains
}


Function Get-MPFromAD ($SiteCode)
{
    $domains = Get-AllDomains
    Foreach ($domain in $domains)
    {
        Try {
            $ADSysMgmtContainer = [ADSI]("LDAP://CN=System Management,CN=System," + "$($Domain.Properties.ncname[0])")
            $AdSearcher = [adsisearcher]"(&(Name=SMS-MP-$SiteCode-*)(objectClass=mSSMSManagementPoint))"
            $AdSearcher.SearchRoot = $ADSysMgmtContainer
            $ADManagementPoint = $AdSearcher.FindONE()
            $MP = $ADManagementPoint.Properties.mssmsmpname[0]
        } Catch {}
    }
    if ($MP) {
        Return $MP
        }
    else {
        'Nothing'
        }
}

Get-MPFromAD HUL