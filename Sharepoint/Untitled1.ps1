
$spWeb.Title = "PowerShell" 
$spWeb.TreeViewEnabled = "True" 
$spWeb.Update() 


import-spWeb -identity http://cocsp02 -Path '\\cocsp01\D$\COPSP01\sp01.cmp'
