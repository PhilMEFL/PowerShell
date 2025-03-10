Import-Module ActiveDirectory
$groupname = 'LNBdynGroup'
$users = Get-ADUser -Filter * -SearchBase 'OU=LNB Users,OU=CAT_Users,DC=gpcocat,DC=local'
foreach($user in $users) {
	Add-ADGroupMember -Identity $groupname -Member $user.samaccountname -ErrorAction SilentlyContinue
	}
$members = Get-ADGroupMember -Identity $groupname
foreach($member in $members) {
	if ($member.distinguishedname -notlike '*OU=LNB Users,OU=CAT_Users,DC=gpcocat,DC=local*') {
		Remove-ADGroupMember -Identity $groupname -Member $member.samaccountname
		}
	}