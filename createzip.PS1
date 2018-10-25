

function Create-myZIP {
	param($path, [switch]$includeSubdir, $root = '')


	begin {
		Write-Progress "Creating ZIP" "initializing $path"
		[System.Reflection.Assembly]::LoadFile("$home\ICSharpCode.SharpZipLib.dll") | Out-Null
		$item = New-Item $path -type File -force
		$archive = New-Object ICSharpCode.SharpZipLib.Zip.ZipOutputStream(($item.OpenWrite()))
		if ($root.length -gt 1  )  {$root = Split-Path -noQualifier $root }
	}

	process {
		if ($_.psIsContainer -ne $true) {
			Write-Progress "Adding File to ZIP '$path':" "$($_.FullName)"
			if ($includeSubDir) {
				$name = Split-Path -noQualifier $_.fullname
				if ($name.startswith($root)) { 
					$name = $name.subString($root.length)
				} 
				$name = $name.subString(1)
			} else { 
				$name = $_.Name
			}

			$file = New-Object icsharpcode.SharpZipLib.Zip.ZipEntry $name
			$archive.PutNextEntry($file)
			[byte[]]$content = Get-Content $_.FullName -encoding Byte -readCount 4GB
			if ($content.Length -gt 0) {
				$archive.write($content, 0, $content.length)
			}
		}
	}

	end {
		Write-Progress "Creating ZIP" "Done."
		$archive.close()
	}
}

# create flat archive with only scripts from top level folder:
dir $home\*.ps1 | Create-myZIP "$home\aFlat.zip" 

# create hierarchical zip with subfolders, setting relative root to $home:
dir $home\Documents -recurse | Create-myZIP "$home\aAll.zip" -includeSubDir -root $home\Documents

