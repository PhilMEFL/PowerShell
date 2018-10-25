set-variable olAppointmentItem 1 -option constant | Out-Null
set-variable olFolderDeletedItems 3 -option constant | Out-Null
set-variable olFolderOutbox 4 -option constant | Out-Null
set-variable olFolderSentMail 5 -option constant | Out-Null
set-variable olFolderInbox 6 -option constant | Out-Null
set-variable olFolderCalendar 9 -option constant | Out-Null
set-variable olFolderContacts 10 -option constant | Out-Null
set-variable olFolderJournal 11 -option constant | Out-Null
set-variable olFolderNotes 12 -option constant | Out-Null
set-variable olFolderTasks 13 -option constant | Out-Null
set-variable olFolderDrafts 16 -option constant | Out-Null

$outlook = new-object -ComObject "Outlook.Application"

$calendar = $outlook.Session.GetDefaultFolder($olFolderCalendar) 
$i = 0

$test = 
function get-mailfolders {            
	$outlookfolders = @()            
	$outlook = New-Object -ComObject Outlook.Application            
	foreach ($folder in $outlook.Session.Folders){            
              
  		foreach($mailfolder in $folder.Folders ) { 
   			$olkf = New-Object PSObject -Property @{            
    		Path = $($mailfolder.FullFolderPath)            
    		EntryID = $($mailfolder.EntryID)            
    		StoreID = $($mailfolder.StoreID)            
   			}            
               
   		$outlookfolders += $olkf            
		}             
	}            
	$outlookfolders            
	}

get-mailfolders |             
where {$_.Path -like "*calendar*" -and $_.Path -notlike "*birthday*"}             
#foreach {            
#  $targetfolder = $outlook.Session.GetFolderFromID($_.EntryID, $_.StoreID)            
#              
#  $targetfolder.Items | foreach {            
#    if ($_.StartTime -lt $date){$_.Delete()}            
#  }             
#}
foreach ($item in $calendar.Items) {
	if (!($item.Subject)) {
		"{0} - {1} Subject: {2}" -f $i++,$item.Start,$item.Subject
  		$item.Delete()
		}
  } 
$i

