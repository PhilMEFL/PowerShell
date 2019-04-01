function read-XML ($xml) {
    $objXML = @()
    $xml.ChildNodes | %{
        if (!$_.NextSibling) {
                read-XML $_
                }
            else {
                if ($_.haschildnodes) {
                $xmlTmp = $_.ChildNodes
                if ($_.Name -ne 'element') {
                    $xmlTmp = $_.ParentNode.ChildNodes
                    } 
                $obj = '' | select ($xmlTmp|  Get-Member -MemberType Property).Name
                ($obj | Get-Member -MemberType NoteProperty).Name | %{
                    $obj.$_ = $xmlTmp.$_
                    }
                if ($obj.gtoupId -eq 56) {
                    $toto
                    }
                $objXML += $obj
                }
            }
        }
       $objXML
	   }


                            
                          