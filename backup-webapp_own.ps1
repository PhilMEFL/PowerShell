# sample parameters
# ergobrusrvm145 "d:\Web applications\Intranet-Apps\DKVWebServices"

    <#
    .Synopsis
    Backups the current version of a web application before deploying a newer release

    .Description
    This scripts creates a zip file containing all files from the current version
	of a web application except the logs and stores it in the backup folder with 
	the conventional name yyyymmdd<applicationname>.zip
	
    .Parameter Server
	
    Returns an object that represents the zip file. By
    default, this function does not generate any output.

    .Parameter Path
    
    Enter a path (optional) and name for the zip file that
    New-Zip creates. The file name should have a .zip file
    name extension.
        
    The file name is required. The default path is
    the current directory. 
    
    .Parameter Force
    
    Overwrites existing zip files if they exist
         
    .Example
    New-Zip Try.zip

    .Example
    New-Zip d:\ps-test\NewFiles.zip
           
    .Example
    New-Zip –path Try.zip –PassThru
     
    .Link
    Copy-ToZip
    #>

Function path-UNC ([string] $IIsServer, $path) {
	if ($path.StartsWith('\\')) {
		return $path
		}
	else {
		return "\\{0}\{1}" -f $IIsServer,$path.Replace(':','$')
		}
	}

Function New-Zip {
	<#
    .Synopsis
    Creates a new zip archive.

    .Description
    The New-Zip function creates a ZIP archive file (.zip)
    with no contents (no compressed files). To add files to
    the ZIP archive, use the Copy-ToZip function.

    .Parameter PassThru
    
    Returns an object that represents the zip file. By
    default, this function does not generate any output.

    .Parameter Path
    
    Enter a path (optional) and name for the zip file that
    New-Zip creates. The file name should have a .zip file
    name extension.
        
    The file name is required. The default path is
    the current directory. 
    
    .Parameter Force
    
    Overwrites existing zip files if they exist
         
    .Example
    New-Zip Try.zip

    .Example
    New-Zip d:\ps-test\NewFiles.zip
           
    .Example
    New-Zip –path Try.zip –PassThru
     
    .Link
    Copy-ToZip
    #>
    param(
    [Parameter(Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true)]
    [String]
    $Path,
    
    [Switch]
    $PassThru,
    
    [Switch]
    $Force
    )
    
    Process {
		if (Test-Path $path) {
            if (!($Force)) { 
				return
			}
		}
		Set-Content $path ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
		$item = Get-Item $path
		$item.IsReadOnly = $false	
		if ($passThru) {
			$item
			} 
    	}
	}

function Make-Zip {
    <#
    .Synopsis
    Compresses files and adds them to a ZIP file.
        
    .Description
    The Make-Zip function compresses files and
    adds the compressed files to a ZIP archive file. 

    If the ZIP file does not exist, this function
    creates it. You can also use this function to add
    compressed files to a ZIP file that you create by
    using the New-Zip function.
    
    .Parameter strFile             
    Enter the path (optional) and name of the file
    to compress.
              
    You can enter only one file with the File parameter.
    To submit multiple files, pipe the files to the
    Make-Zip function.

    This parameter is required. The default path is
    is the current directory.

    .Parameter ZipFile
    
    Enter the path (optional) and file name of the 
    ZIP file to which the files are copied. The ZIP
    file should have a .zip file name extension.
    If the specified ZIP file does not exist, Make-Zip
    creates it.

    This parameter is required. The default path
    is the current directory.        
    
    .Parameter HideProgress
     
    Hides the progress bar that Make-Zip displays by default
    
    .Parameter Force
    
    Copies read-only files to the ZIP archive file.        
      
    .Example
    Make-Zip –file Report.docx –zipfile Manager.zip

    .Example
    Make-Zip –file $home\documents\Report.docx –zipfile C:\Zip\Manager.zip -force

    .Example
    Make-Zip Report.docx Manager.zip –hideProgress

    .Example 
    dir .\*.xml | Make-Zip –zipfile XMLFiles.zip

    .Link
    New-Zip
    #>

    param(
    [Parameter(
		Mandatory = $true,
        Position = 0,
        ValueFromPipelineByPropertyName = $true)]
    [Alias('FullName')]
    [String]$strFile,

    [Parameter(
		Mandatory = $true,
		Position = 1)]
    [String]$ZipFile,
    
    [Switch]$HideProgress,

    [Switch]$Force
    )
    
	Begin {
		$perc = 1
		$intWait = 100
		$ShellApplication = New-Object -ComObject Shell.Application
		if (Test-Path $ZipFile) {
			rm $ZipFile
        	}
		New-Zip $ZipFile	
		$ZipPackage =$ShellApplication.Namespace($ZipFile)
		}
	
	Process {
		$fsiFile = Get-Item $strFile
# Count item in folder		
		if ($fsiFile.Attributes -eq 'Directory') {
			$intItems = (Get-ChildItem $fsiFile -Recurse | ?{!($_.PSIsContainer)}).Count
			if ($intItems) {
				$intItems + 2 # Directory files counts 2 entries
				}
			else {
				New-Item -path $fsiFile -Name 'dummy.txt' -ItemType 'file'
				}
			$intDelay = $intItems * $intWait
			}
		else {
			$intItems = 1
			$intDelay =  10000
			}
		if (!($fsiFile)) {
			return
			}        
		if (!($hideProgress)) {
			$perc += $intItems
			Write-Progress "Copying to $ZipFile" $fsiFile.FullName -PercentComplete (($perc / $intTotItems) * 100)
        	}
		$Flags = 0
		if ($force) {
			$flags = 16 -bor 1024 -bor 64 -bor 512
			} 

		Write-Verbose $fsiFile.Fullname
		if ($intItems) {
			$ZipPackage.CopyHere($fsiFile.Fullname, $flags)
			}
		else {
			$ZipPackage.CopyHere($fsiFile.Fullname, $flags)
			Get-ChildItem $fsiFile.FullName | Remove-Item -Force
			foreach ($item in $ZipPackage.items()) {
				$item.Size
				$tata = 'toto'
				}
			}
		Start-Sleep -Milliseconds ($intDelay)
		}
	}
	
cls
if ($args.count -ne 2) {
	"Usage : backup-webapp <Server Name> <Application path>"
	}
else {
	$strSRV = $args[0]
	$strPath = $args[1]

	$strApp = $strPath.Substring($strPath.LastIndexOf('\') + 1)
	
	$strBackPath = "\\{0}\{1}$\backup deploy\{2}_{3}.zip" -f $strSRV, $strPath[0], $(get-date -format yyyyMMdd), $strApp
#	$zipBackup = New-Zip -Path $strBackPath -PassThru -Force

#	$intTotItems = (Get-ChildItem $("\\{0}\{1}" -f $strSRV, $strPath.Replace(':','$')) -Recurse -Exclude log,logs | ?{!($_.PSIsContainer)}).Count
	
	Write-Zip -Level 9 -IncludeEmptyDirectories -path $(Get-ChildItem $strPath.Replace('d:','\\' + $strSRV + '\d$') -Exclude log,logs) -OutputPath $("\\{0}\{1}$\backup deploy\{2}_{3}.zip" -f $strSRV, $strPath[0], $(get-date -format yyyyMMdd), $strApp)
	}
