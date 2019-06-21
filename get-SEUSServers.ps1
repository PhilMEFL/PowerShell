$OSIs64BitArch = ([System.Environment]::Is64BitOperatingSystem)
$OSArchString = if ( $OSIs64BitArch ) {"x64"} else {"x86"}
$OSIsServerVersion = if ([Int]3 -eq [Int](Get-WmiObject -Class Win32_OperatingSystem).ProductType) {$True} else {$False}
$OSVerObjectCurrent = [System.Environment]::OSVersion.Version
if ($OSVerObjectCurrent -ge (New-Object -TypeName System.Version -ArgumentList "6.1.0.0")) {
    if ($OSVerObjectCurrent -ge (New-Object -TypeName System.Version -ArgumentList "6.2.0.0")) {
        if ($OSVerObjectCurrent -ge (New-Object -TypeName System.Version -ArgumentList "6.3.0.0")) {
            if ($OSVerObjectCurrent -ge (New-Object -TypeName System.Version -ArgumentList "10.0.0.0")) {
                if ( $OSIsServerVersion ) {
                    Write-Output ('Windows Server 2016 ' + $OSArchString + " ... OR Above")
                } else {
                    Write-Output ('Windows 10 ' + $OSArchString + " ... OR Above")
                }
            } else {
                if ( $OSIsServerVersion ) {
                    Write-Output ('Windows Server 2012 R2 ' + $OSArchString)
                } else {
                    Write-Output ('Windows 8.1 ' + $OSArchString)
                }
            }
        } else {
            if ( $OSIsServerVersion ) {
                Write-Output ('Windows Server 2012 ' + $OSArchString)
            } else {
                Write-Output ('Windows 8 ' + $OSArchString)
            }
        }
    } else {
        if ( $OSIsServerVersion ) {
            Write-Output ('Windows Server 2008 R2 ' + $OSArchString)
        } else {
            Write-Output ('Windows 7 OR Windows 7-7601 SP1' + $OSArchString)
        }
    }
} else {
    Write-Output ('This version of Windows is not supported.')
}
