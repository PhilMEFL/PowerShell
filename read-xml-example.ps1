[System.Xml.XmlDocument] $xdLists = new-object System.Xml.XmlDocument
[System.Xml.XmlDocument] $xdMig = new-object System.Xml.XmlDocument
$listfile = "C:\Users\pmartin\Documents\WindowsPowershell\Shares.xml"
$xdLists.load($listfile)

$xdNodes= $xdLists.selectnodes("Servers/Server")
$migCols = $xdLists.selectnodes("//MigrationColumns/Columns/Column")

#LOOP 1-----------------------------------------
foreach($xnode in $xdNodes)
{
	$xeShares = $xnode.get_Item('Shares')
	if ($xeShares.HasChildNodes) {
		$xeShares.Name
		$xeShares.Permissions.Count
		}
    Write-Host $xnode.Attributes.GetNamedItem("MigrationFile").Value
    $destLists = $xnode.Attributes.GetNamedItem("Name").Value
    $migfiles = $xnode.Attributes.GetNamedItem("MigrationFile").Value


    Write-Host $destLists

    #Check if the xml file to read from exists

    if($migFiles -ne $null)
    {
            $xdMig.Load($migfiles)

            $spSite = Get-SPSite "http://sp2010:100" 
            $spWeb = $spSite.OpenWeb()

            $list = $spWeb.Lists[$destLists]

            foreach($nCol in $migCols)
            {
                $destListCol =  $nCol.Attributes.GetNamedItem("DestList").Value
                $sourcCol =  $nCol.Attributes.GetNamedItem("SourceCol").Value

#               Write-Host $col " - " $list.Title

                if($destListCol -eq $list.Title)
                {
                    Write-Host $destListCol " - " $list.Title " - Source Column: " $sourcCol  -ForegroundColor Green
                    Write-Host

                    # ----------------------- time to search the exported lists --------------------
                    Write-Host "Search the exported list for the right column" -ForegroundColor  DarkYellow

                    if($xdMig.DocumentElement -ne $null)
                        {
                            $xnList = $xdMig.DocumentElement.ChildNodes

                    #           LOOP 2----------------------------------------
                            Write-Host $xnList.Count " items found" -ForegroundColor Red
                            foreach($xn in $xnList)
                            {
                                Write-Host $xn.Name -ForegroundColor Red

                                $nList = $xdMig.SelectNodes("//"+$xn.Name)
                                $lItem = $list.Items.Add()

                                foreach($n in $migCols)
                                  {

                                    if($n.Attributes -ne $null)
                                    {
                                        $sourceCol = $n.Attributes.GetNamedItem("SourceCol").Value
                                        $destCol = $n.Attributes.GetNamedItem("DestCol").Value
                                        $destList = $n.Attributes.GetNamedItem("DestList").Value

                                        Write-Host "Dest Col: " $destCol  "-  Sour Col: " $xn[$sourceCol].Name 
                                        Write-Host $destList -ForegroundColor Red

                                        if($list.Title -eq $destList)
                                        {
                                            if($xn[$sourceCol] -ne $null )
                                            {
                                                if($list.Fields[$destCol] -ne $null)
                                                {
                                                    $lItem[$destCol] = $xn[$sourceCol].InnerText    
                                                }

                                            }else
                                            {
                                                Write-Host   $sourceCol " was not matched" -ForegroundColor Yellow
                                            }
                                        }
                                     }
                                  }
                                  $lItem.Update()
                                  Write-Host "-----------------------------------"
                            }

                        }
                }
            }
    }
}