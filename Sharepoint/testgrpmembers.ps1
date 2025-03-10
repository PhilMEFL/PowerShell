if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin Microsoft.SharePoint.PowerShell
    }

#function global:Get-SPSite($url) {
#	return new-Object Microsoft.SharePoint.SPSite($url)
#	}

function global:Get-SPWeb($url) {
	$site= New-Object Microsoft.SharePoint.SPSite($url)
#    if ($site -ne $null) {    
	if ($site) {
		$web=$site.OpenWeb();       
		}
	$web
	}

 
cls
$URL="https://portallnb.gpcocat.be/"
$strOutfile = "c:\UsersandGroupsRpt.txt"

$site = Get-SPSite $URL
#Write the Header to "Tab Separated Text File"
"Site Name`t  URL `t Group Name `t User Account `t User Name `t E-Mail" #| out-file $strOutFile

#Iterate through all Webs
$site.AllWebs | %{
	#Write the Header to "Tab Separated Text File"
#	"$($web.title) `t $($web.URL) `t  `t  `t `t " #| out-file $strOutFile -append
	"$($_.title)`t $($_.URL)" #| out-file $strOutFile -append
		
	#Get all Groups and Iterate through    
#	foreach ($group in $Web.groups) 
	$_.groups | %{
		"`t  `t $($_.Name)" #| out-file $strOutFile -append
		#Iterate through Each User in the group
		$_.users | %{
			#Exclude Built-in User Accounts
			$_.LoginName
			if (($_.LoginName.ToLower() -ne "nt authority\authenticated users") -and ($_.LoginName.ToLower() -ne "sharepoint\system") -and ($_.LoginName.ToLower() -ne "nt authority\local service")) {
				"`t  `t  `t  $($_.LoginName)  `t  $($_.name) `t  $($user.Email)" #| out-file $strOutFile -append
				}
			} 
		}
	}

    write-host "Report Generated at $strOutFile"


