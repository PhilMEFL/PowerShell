function Get-ADComputers{
	trap [Exception] {
#		trapped "AD:$Filter:" $($_.Exception.Message)
		}

	$searcher = new-object DirectoryServices.DirectorySearcher([ADSI]"")    #Leaving the ADSI statement empty = attach to your root domain 
	$searcher.filter = "(&(objectClass=computer)(operatingSystem=Windows*))"
	$searcher.CacheResults = $true
	$searcher.SearchScope = “Subtree”
	$searcher.PageSize = 1000
	$accounts = $searcher.FindAll()

	if ($accounts.Count -gt 0) {
		foreach($account in $accounts){     
			$cn = $account.Properties["cn"][0]
			#$useraccountcontrol = $account.Properties["userAccountControl"][0];      # didn't work
            $fixme = [adsi]$account.Path
			
            # Property that contains the last password change in long integer format
            $pwdLastSet = $account.Properties["pwdlastset"]

            # Convert the long integer to normal DateTime format
            $lastchange = [datetime]::FromFileTimeUTC($pwdLastSet[0])

            # Determine the timespan between the two dates
            $datediff = new-TimeSpan $lastchange $(Get-Date)

            # Create an output object for table formatting
            $obj = new-Object PSObject

            # Add member properties with their name and value pair
            $obj | Add-Member NoteProperty cn($account.Properties["cn"][0])
			$obj | Add-Member NoteProperty distinguishedName($fixme.distinguishedName.Item(0))
			$obj | Add-Member NoteProperty operatingSystem($fixme.operatingSystem.Item(0))
#			$obj | Add-Member NoteProperty operatingSystemServicePack($fixme.operatingSystemServicePack.Item(0))
            $obj | Add-Member NoteProperty userAccountControl($fixme.userAccountControl.Item(0))
            $obj | Add-Member NoteProperty pwdLastSet($lastchange)
            $obj | Add-Member NoteProperty DaysSinceChange($datediff.Days)
            $obj
        }
    }
}

#foreach($comp in Get-ADComputers) {
#	if ($comp.cn -match 'COH') {
#		$comp
#		}
#	}

Get-ADComputers | select $_.distinguishedName

#where ($_.distinguishedName -contains 'CO_Computers')
'script completed'
