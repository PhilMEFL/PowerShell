cls

function getACLS ([string]$path, [int]$max, [int]$current) {

    $dirs = Get-ChildItem -Path $path | Where { $_.psIsContainer }
    $acls = Get-Acl -Path $path
    $security = @()

    foreach ($acl in $acls.Access) {
        $security += ($acl.IdentityReference, $acl.FileSystemRights)
    	}   
#	$security | Out-Host

    if ($current -lt $max) {
        if ($dirs) {
            foreach ($dir in $dirs) {
                $newPath = $dir.FullName
                $security
                getACLS $newPath $max ($current+1)
            }   
        }
    } elseif ($current -eq $max ) {
        Write-Host $max
        return $security
    }
}

$results = getACLS "C:\TempIn" 2 0