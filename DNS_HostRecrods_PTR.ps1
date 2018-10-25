cls
#Script to add DNS 'A' Records 'PTR' Records to DNS Servers
$dns = "ergobrusrvm127" # Your DNS Server Name
$Zone = "dkv.ergo-service.belgium.io.ergo" # Your Forward Lookup Zone Name
$ReverseZone = "10.in-addr.arpa" # Your ReverseLookup Zone Name Goes Here
$a = import-csv C:\Users\martin\Documents\avamarDNS.csv
$OutFile = "C:\Users\martin\Documents\avamarRVR.csv"

#Preparing the C:\Reverse.csv from C:\DNS.CSV for Adding PTR Records
$b = $a | Select-Object -expand IP
$c = $b | %{$_.Split(".")}
$d = $a | Select-Object -Expand Name
$e = $d | %{$_.Insert($_.length,"." + $Zone)}
Out-File $OutFile -Encoding ascii
for($i=0;$i -lt ($e.Length);$i++) {
	('"{0}.{1}.{2}","{3}"' -f $c[$i * 4 + 3],$c[$i * 4 + 2],$c[$i * 4 + 1],$e[$i]) | Out-File $OutFile -append -Encoding ascii
	}

$header = "IP","Name"
$f = Import-Csv $OutFile  -Header $header

#Adding 'A' Record to DNS Forward Lookup Zone
$a | %{dnscmd $dns /recordadd $Zone $($_.Name)A $($_.IP)}

#Adding 'PTR' Record to DNS Reverse Lookup Zone
$f | %{dnscmd $dns /recordadd $ReverseZone $($_.IP)PTR $($_.Name)}