function isAdmin {
	$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()  
	$principal = new-object System.Security.Principal.WindowsPrincipal($identity)  
	$admin = [System.Security.Principal.WindowsBuiltInRole]::Administrator  
	$principal.IsInRole($admin)  
	}

isAdmin

$userToFind = $args[0] 
$administratorsAccount = Get-WmiObject Win32_Group -filter "LocalAccount=True AND SID='S-1-5-32-544'" 
$administratorQuery = "GroupComponent = `"Win32_Group.Domain='" + $administratorsAccount.Domain + "',NAME='" + $administratorsAccount.Name + "'`"" 
$user = Get-WmiObject Win32_GroupUser -filter $administratorQuery | select PartComponent |where {$_ -match $userToFind} 
$user 
