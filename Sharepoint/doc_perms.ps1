$siteURL = new-object Microsoft.SharePoint.SPSite("https://portallnb.gpcocat.be/dms/operations")

$siteURL.rootweb
$web = $siteURL.rootweb

#Getting the required document library
$web.Lists["Bid"]
$libraryName = $web.Lists["Bid"]
$rootFolder = $libraryName.RootFolder

#Iterating through the required documents sets
foreach ($docsetFolder in $rootFolder.SubFolders) {
    #check document sets/folders of content type = "TestDocSet"
    if ($docsetFolder.Item.ContentType.Name -eq "TestDocSet") {
    write-host -f Yellow `t $docsetFolder.Name

    #Iterating through the files within the document sets
    foreach ($document in $docsetFolder.Files) {
        if (!$document.HasUniqueRoleAssignments) {
            write-host -f Cyan `t "  " $document.Name
            write-host -f Red `t "     ..permissions inheritance detected. Process skipped"
            }
        }
    }
}

$web.Dispose()
$siteURL.Dispose()
