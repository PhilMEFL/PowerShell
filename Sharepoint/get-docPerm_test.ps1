cls
Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue

$myweb =  Get-SPWeb "http://cocsp02/dms/operations" 
$myweb

$mylist = $myweb.Lists | ?{$_.Title -like 'Operations Management'}

$mylist.RoleAssignments | %{
	$_
	"Document Name is: {0} and the persmissions are: {1}<" -f $_.Title, $_.RoleAssignements
	}

foreach ($item in $mylist.Items ) {
	$item | %{
		$_.name
		$_.level
			$_ | %{
				$_
				}
			}
		
    "Document Name is: "+$item.Name + " and the persmissions are: " + $item.RoleAssignements + "|"
	"#######################################################"
	}