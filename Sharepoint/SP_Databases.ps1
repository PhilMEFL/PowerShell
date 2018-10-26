Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue

get-spdatabase | %{ 
$_
}