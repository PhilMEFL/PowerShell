# sample parameters
# ergobrusrvm145 "d:\Web applications\Intranet-Apps\DKVWebServices"

    <#
    .Synopsis
    Backups the current version of a web application before deploying a newer release

    .Description
    This scripts creates a zip file containing all files from the current version
	of a web application except the logs and stores it in the backup folder with 
	the conventional name yyyymmdd_<applicationname>.zip
	
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
    #>

cls
Import-Module pscx
if ($args.count -ne 2) {
	"Usage : backup-webapp <Server Name> <Application path>"
	}
else {
	$strSRV = $args[0]
	$strPath = $args[1]

	$strApp = $strPath.Substring($strPath.LastIndexOf('\') + 1)
	
	$strBackPath = "\\{0}\{1}$\backup deploy\{2}_{3}.zip" -f $strSRV, $strPath[0], $(get-date -format yyyyMMdd), $($strPath.Substring($strPath.LastIndexOf('\') + 1))

	Write-Zip -IncludeEmptyDirectories -path $(Get-ChildItem $strPath.Replace('d:','\\' + $strSRV + '\d$') -Exclude log,logs) -OutputPath $("\\{0}\{1}$\backup deploy\{2}_{3}.zip" -f $strSRV, $strPath[0], $(get-date -format yyyyMMdd), $strApp)
	}
