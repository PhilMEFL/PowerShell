# Script:	Get-Remote-LocalAdmins.ps1
# Purpose:  This script can detect the members of a remote machine's local Admins group
# Author:   Paperclips (The Dark Lord)
# Email:	magiconion_M@hotmail.com
# Date:     Nov 2011
# Comments: 
# Notes:    
#			

function get-localadmin { 
param ($strcomputer) 
 
$admins = Gwmi win32_group –computer $strcomputer  
$admins = $admins |? {$_.groupcomponent –like '*"Administrators"'} 
 
$admins |% { 
$_.partcomponent –match “.+Domain\=(.+)\,Name\=(.+)$” > $nul 
$matches[1].trim('"') + “\” + $matches[2].trim('"') 
} 
}

get-localadmin dkvbrusrvm021