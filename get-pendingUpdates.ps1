#Check all nominated servers for pending WSUS updates
#Version 1.0
#Date: 31-08-12
#Author:
 
$Banner = "
 
 ########  ######## ##    ## ########  #### ##    ##  ######        
 ##     ## ##       ###   ## ##     ##  ##  ###   ## ##    ##       
 ##     ## ##       ####  ## ##     ##  ##  ####  ## ##             
 ########  ######   ## ## ## ##     ##  ##  ## ## ## ##   ####      
 ##        ##       ##  #### ##     ##  ##  ##  #### ##    ##       
 ##        ##       ##   ### ##     ##  ##  ##   ### ##    ##       
 ##        ######## ##    ## ########  #### ##    ##  ###### 
 
 ##     ## ########  ########     ###    ######## ########  ######  
 ##     ## ##     ## ##     ##   ## ##      ##    ##       ##    ## 
 ##     ## ##     ## ##     ##  ##   ##     ##    ##       ##       
 ##     ## ########  ##     ## ##     ##    ##    ######    ######  
 ##     ## ##        ##     ## #########    ##    ##             ## 
 ##     ## ##        ##     ## ##     ##    ##    ##       ##    ## 
  #######  ##        ########  ##     ##    ##    ########  ######  
"
 
Function Junction {
 
BEGIN {
        Write-Host -ForegroundColor Yellow $Banner
        Write-Host ""
        Write-Host ""
        Write-Host -ForegroundColor Green " Please follow the prompts:".ToUpper()
        Write-Host ""
        $Choice = Read-Host " Select 1 for a single Server, select 2 for a batch of servers [1/2]"
}
 
PROCESS {
 
    if ($Choice -eq "1") { 
        #File to hold the names of server(s) to be queried, adjust this path / name to suit yourself
        $File = "C:\scripts\WSUS_Servers.txt"
        Read-Host " Please enter the computername you wish to query" | Out-File -FilePath $File
        $comp = gc $File 
        $results = gwmi -query "SELECT * FROM Win32_PingStatus WHERE Address = '$comp'"
        IF ($results.StatusCode -ne 0) {
                Write-Host ""
                Write-Host " Issue with supplied name, either the server is offline, or you have made a typo; Please check the input name.".ToUpper() -ForegroundColor Red
                Write-Host ""
                exit}
        }
    elseif ($Choice -eq "2") {
        #File to hold the names of server(s) to be queried, adjust this path / name to suit yourself
        $File = "C:\script\WSUS_Servers.txt"
        $batch = Read-Host " Please enter a local or UNC path, to the text file to query"
                $Response = Test-Path -Path $batch
                if ($Response -ne "True") { 
                    Write-Host ""
                    Write-Host " Check your typed file path input; the file is not present, please try again!".ToUpper() -ForegroundColor Red
                    Write-Host ""
                    exit} 
        Get-Content $batch | Out-File -FilePath $File
        }   
    else {
        Write-Host ""
        Write-Host " Try again, read the prompts you bonehead".ToUpper() -ForegroundColor Red
        Write-Host ""
        exit}
 
    $Servers = Get-Content $File
    Write-Host ""
 }
 
END {Get-PendingUpdates}
 
 }#end End scriptblock
 
Function Get-PendingUpdates {
 
 BEGIN {
    Write-Host ""
    Write-Host " Commencing collection of pending updates"
    Write-Host ""
    Write-Host " Creating report collection"
    $report = @()    
    }
 PROCESS {
    ForEach ($c in $Servers) {
        $uptime = [management.managementdatetimeconverter]::todatetime((gwmi win32_operatingsystem -comp $c).lastbootuptime)
        $Days = ([datetime]::now -$uptime).Days
        $Hours = ([datetime]::now -$uptime).Hours
        $Minutes = ([datetime]::now -$uptime).Minutes
        Write-Host ""
        Write-Host " Computer: " -NoNewline 
        Write-Host "$($c)".ToUpper() -ForegroundColor Green
        Write-Host " Uptime: " -NoNewline
        Write-Host "$Days days, $Hours hours, $Minutes minutes" -ForegroundColor Cyan
        If (Test-Connection -ComputerName $c -Count 1 -Quiet) {
            Try {
            #Create Session COM object
                Write-Host " Creating COM object for WSUS Session"
                $updatesession =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$c))
 
                #Configure Session COM Object
                Write-Host " Creating COM object for WSUS update Search"
                $updatesearcher = $updatesession.CreateUpdateSearcher()
 
                #Configure Searcher object to look for Updates awaiting installation
                Write-Host " Searching for WSUS updates on client"
                $searchresult = $updatesearcher.Search("IsInstalled=0")    
 
                #Verify if Updates need installed
                Write-Host " Verifing that updates are available to install"
                If ($searchresult.Updates.Count -gt 0) {
                    #Updates are waiting to be installed
                    Write-Host " Found $($searchresult.Updates.Count) update\s!" -ForegroundColor Yellow
                    #Cache the count to make the For loop run faster
                    $count = $searchresult.Updates.Count
 
                    #Begin iterating through Updates available for installation
                    Write-Host " Iterating through list of updates"
                    For ($i=0; $i -lt $Count; $i++) {
                        #Create object holding update
                        $update = $searchresult.Updates.Item($i)
 
                        #Verify that update has been downloaded
                        Write-Host " Checking to see that update has been downloaded"
                        If ($update.IsDownLoaded -eq "True") { 
                            Write-Host " Auditing updates"  
                            Write-Host " Creating report"
                            $temp = "" | Select Computer, Title, KB,IsDownloaded,Notes
                            $temp.Computer = $c
                            $temp.Title = ($update.Title -split('\('))[0]
                            $temp.KB = (($update.title -split('\('))[1] -split('\)'))[0]
                            $temp.IsDownloaded = "True"
                            $temp.Notes = "NA"
                            $report += $temp               
                            }
                        Else {
                            Write-Host " Update has not been downloaded yet!"
                            Write-Host " Creating report"
                            $temp = "" | Select Computer, Title, KB,IsDownloaded,Notes
                            $temp.Computer = $c
                            $temp.Title = ($update.Title -split('\('))[0]
                            $temp.KB = (($update.title -split('\('))[1] -split('\)'))[0]
                            $temp.IsDownloaded = "False"
                            $temp.Notes = "NA"                        
                            $report += $temp
                            }
                        }
                    }
                Else {
                    #Create Temp collection for report
                    Write-Host " Creating report"
                    $temp = "" | Select Computer, Title, KB,IsDownloaded,Notes
                    $temp.Computer = $c
                    $temp.Title = "NA"
                    $temp.KB = "NA"
                    $temp.IsDownloaded = "NA"
                    $temp.Notes = "NA"                
                    $report += $temp
                    }              
                }
            Catch {
                Write-Host " $($Error[0])".ToUpper() -ForegroundColor Red
                Write-Host " Creating report".ToUpper() -ForegroundColor Red
                #Create Temp collection for report
                $temp = "" | Select Computer, Title, KB,IsDownloaded,Notes
                $temp.Computer = $c
                $temp.Title = "ERROR"
                $temp.KB = "ERROR"
                $temp.IsDownloaded = "ERROR"
                $temp.Notes = "$($Error[0])"            
                $report += $temp  
                }
            }
        Else {
            #Nothing to install at this time
            Write-Host " $($c): Offline".ToUpper() -ForegroundColor Red
 
            #Create Temp collection for report
            $temp = "" | Select Computer, Title, KB,IsDownloaded,Notes
            $temp.Computer = $c
            $temp.Title = "OFFLINE"
            $temp.KB = "OFFLINE"
            $temp.IsDownloaded = "OFFLINE"
            $temp.Notes = "OFFLINE"            
            $report += $temp            
            }
        } 
    }
 END {
    #writes output to screen, in a formatted autosized table
    Write-Host ""
    Write-Host " REPORT COMBINED COLLECTIONS:" -ForegroundColor Green
    Write-Host ""
    Write-Output $report | ft -auto
    #Adjust the out-file output path / file name to suit yourself
    Write-Output $report | ft -auto | Out-File C:\Script\WSUS_PendingUpdates_Results.txt
    }    
}
#Commence Function
Junction