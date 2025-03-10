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
    
    .Parameter File             
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
    [String]$File,

    [Parameter(
		Mandatory = $true,
		Position = 1)]
    [String]$ZipFile,
    
    [Switch]$HideProgress,

    [Switch]$Force
    )
    
	Begin {
		$ShellApplication = New-Object -ComObject Shell.Application
		if (!(Test-Path $ZipFile)) {
			New-Zip $ZipFile
        	}
		$ZipPackage =$ShellApplication.Namespace($ZipFile)
		}
	
	Process {
		$File | Out-Host
		$RealFile = Get-Item $File
		if (!$RealFile) {
			return
			}        
		if (!$hideProgress) {
			$perc += 5 
			if ($perc -gt 100) {
				$perc = 0 
				} 
			Write-Progress "Copying to $ZipFile" $RealFile.FullName -PercentComplete $perc
        	}
		$Flags = 0
		if ($force) {
			$flags = 16 -bor 1024 -bor 64 -bor 512
			} 
		Write-Verbose $realFile.Fullname
		$ZipPackage.CopyHere($realFile.Fullname, $flags)
		Start-Sleep -Milliseconds 500
		}
	}