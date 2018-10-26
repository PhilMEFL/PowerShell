[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null

function GetSPFieldDetailsForAllLists($SiteCollectionURL)
{
    $site = new-object Microsoft.SharePoint.SPSite($SiteCollectionURL) #Change site URL#
    $web = $site.openweb() 
    
    foreach ($list in $web.Lists) #Get all list in web
    {
        foreach ($view in $list.Views) #Get all views in lists
        {
            $spView = $web.GetViewFromUrl($view.Url) #Grab views URL
            Write-Host "List Name: " $list.Title  ##Print List title
            Write-Host "------------------------------------------------------"
            Write-Host "Field Name | Field Title " -ForegroundColor DarkGreen
            Write-Host "------------------------------------------------------"
            foreach ($spField in $spView.ViewFields) #Loop through all view URLs and get Fields (columns)
            {
                foreach ($field in $list.Fields) #Get all fields in lists
                {
                    if($spField -eq $field.Title) #if field in lists equals field in views
                        {
                            Write-Host $spField " | " $field.Type -ForegroundColor Green #Write out each field (column)                        
                        }
                }
            }

            Write-Host "------------------------------------------------------"
            Write-Host " "
        }
    }
    $web.Dispose()
    $site.Dispose()
}


function GetSPFieldDetailsForList($SiteCollectionURL, $listName)
{
    $site = new-object Microsoft.SharePoint.SPSite($SiteCollectionURL) #Change site URL#
    $web = $site.openweb() 
    $list = $web.Lists[$listName] #Get Field Details for specified list
    
    foreach ($view in $list.Views) #Get all views in lists
    {
        $spView = $web.GetViewFromUrl($view.Url) #Grab views URL
        Write-Host "List Name: " $list.Title  ##Print List title
        Write-Host "------------------------------------------------------"
        Write-Host "Field Name | Field Title "
        Write-Host "------------------------------------------------------"
        foreach ($spField in $spView.ViewFields) #Loop through all view URLs and get Fields (columns)
        {
            foreach ($field in $list.Fields) #Get all fields in lists
            {
                if($spField -eq $field.Title) #if field in lists equals field in views
                {
                    Write-Host $spField " | " $field.Type -ForegroundColor Green #Write out each field (column)                        
                }
            }
        }

        Write-Host "------------------------------------------------------"
        Write-Host " "
    }    

    $web.Dispose()
    $site.Dispose()
}


