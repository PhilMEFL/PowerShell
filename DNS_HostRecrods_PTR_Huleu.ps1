cls
#Script to add DNS 'A' Records 'PTR' Records to DNS Servers
$dns = "srv" # Your DNS Server Name
$Zone = "huleu.local" # Your Forward Lookup Zone Name
$ReverseZone = "192.168.1.x" # Your ReverseLookup Zone Name Goes Here
$a = import-csv C:\Users\pma\Documents\avamarkDNS.csv

#Preparing the C:\Reverse.csv from C:\DNS.CSV for Adding PTR Records
$b = $a | Select-Object -expand IP
#$c = $b | %{$_.Split(".") | Select-Object -Exclude 1}
$c = $b | %{$_.Split(".")}
# | $_[3] + "." + $_[2] + "." +$_[1]
$c

$d = $a | Select-Object -Expand Name
$e = $d | %{$_.Insert($_.length,"." + $Zone)}
for($i = 0;$i -lt ($e.Length); $i++) {
	('"{0}.{1}.{2}","{3}"' -f $c[$i * 4 + 3],$c[$i * 4 + 2],$c[$i * 4 + 1],$e[$i]) | Out-File C:\Users\pma\Documents\avamarkRVR.csv -Append -Encoding ascii
	}

$header = "IP","Name"
$f = Import-Csv C:\Users\pma\Documents\avamarkRVR.csv  -Header $header

#Adding 'A' Record to DNS Forward Lookup Zone
$a | %{dnscmd $dns /recordadd $Zone $($_.Name)A $($_.IP)}

#Adding 'PTR' Record to DNS Reverse Lookup Zone
$f | %{dnscmd $dns /recordadd $ReverseZone $($_.IP)PTR $($_.Name)}