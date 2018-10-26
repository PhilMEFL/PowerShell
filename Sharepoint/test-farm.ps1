[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
$farm=[Microsoft.SharePoint.Administration.SPFarm]::Local
foreach ($solution in $farm.Solutions) 
        {
            if ($solution.Deployed){
               Write-Host($solution.DisplayName)
               $solution.DisplayName >> c:\temp\test.txt 
            }          
        }