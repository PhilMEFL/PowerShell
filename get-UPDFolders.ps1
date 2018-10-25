if ($args) {
	$UPDShare = $args[0]
	$fc = new-object -com scripting.filesystemobject
	$folder = $fc.getfolder($UPDShare)
#	$objUPD = New-Object System.Object
#	$Dataset.Tables | %{
#		$objQuery | Add-Member -Type noteProperty -Name ColNames -Value $_.Columns.caption
#		$objQuery | Add-Member -Type noteProperty -Name Values -Value $_.Rows
#		}
#	$objQuery
	"Username,SiD" > export.csv
	$folder.files | %{
#		$objUPD.Sid | Add-Member -Type noteProperty -Name SID -Value $_.Name
		$sid = $_.Name
		$sid = $sid.Substring(5,$sid.Length-10)
		if ($sid -ne "template") {
			$securityidentifier = new-object security.principal.securityidentifier $sid
			$user = ( $securityidentifier.translate( [security.principal.ntaccount] ) )
#			$objUPD | Add-Member -Type noteProperty -Name UserName -Value $user
			
			$user,$_.Name -join "," >> export.csv
			}
		}
#	$objUPD
	Import-Csv export.csv
	}
else {
	"Usage {0} folder" -f 'get-UPDFolders'
	}