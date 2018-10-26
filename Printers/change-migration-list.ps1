$NewFile = '\\net1\ci\Common\ITIC_PRINT\Lists\DIGIT-itic.csv.test'
$file = Get-Content '\\net1\ci\Common\ITIC_PRINT\Lists\DIGIT-itic.csv.new'
foreach ($line in $file) {
	if ($line.contains('HP')) {
		$line = $line.Replace('s-ci-prt06','s-ci-prt07').Replace('s-ci-prt02','s-ci-prt06')
		}
	$line | Out-File $NewFile -Append
	}