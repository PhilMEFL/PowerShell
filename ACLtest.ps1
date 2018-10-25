$folder = "C:\users"

$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"

$propagation = [system.security.accesscontrol.PropagationFlags]"None"

$acl = Get-Acl $folder

$accessrule = New-Object system.security.AccessControl.FileSystemAccessRule("Users", "FullControl", $inherit, $propagation, "Allow")

$acl.AddAccessRule($accessrule)

Set-Acl -aclobject $acl $folder

