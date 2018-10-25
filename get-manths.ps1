$begin = [datetime]'05/01/2012'
$end   = [datetime]'09/30/2013'

$monthdiff = $end.month - $begin.month + (($end.Year - $begin.year) * 12)
$monthdiff.ToString() + ' months'
