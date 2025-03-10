Function Get-gpcoFolder($strLoc, [datetime] $dt) {

	$strTmp = "{0}\{1:yyyy}\{2:MM}" -f $strLoc,$dt,$dt
	if (!(Test-path($strTmp))) {
		New-Item $strTmp -type Directory -force  #| out-Null
		}
	$strTmp
	}

function get-lastDayMonth {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [datetime[]]$Date = (Get-Date)
    )
    PROCESS {
		$LastDay = [System.DateTime]::DaysInMonth($Date.Year, $Date.Month)
		[datetime]"$($Date.Month), $LastDay, $($Date.Year), 23:59:59.999"
		}
	}

function get-NextSunday {
    $dtNow = Get-Date

    while ($dtNow.DayOfWeek -ne 'Sunday') {
        $dtNow = $dtNow.AddDays(1)
        }
    $dtNow
    }
 
function get-servers {
	$strDC = "OU=Domain Controllers,DC={0},DC=local" -f $env:USERDOMAIN
    if ($env:USERDOMAIN -eq 'GPCOCAT') {
        $strSRV = "OU=CAT_Servers,DC={0},DC=local" -f $env:USERDOMAIN
        $strSrv
        }
     else {
	    $strSRV = "OU=CO_Servers,DC={0},DC=local" -f $env:USERDOMAIN
        }
	$Srvs = get-adcomputer -Filter * -properties * -SearchBase $strDC
	$Srvs += get-adcomputer -Filter * -properties * -SearchBase $strSRV

	$Srvs = $Srvs | where {(!($_.servicePrincipalName -match 'VirtualServer'))} | sort Name
	$Srvs
	}

Function format-DiskSize() {
	[cmdletbinding()]
		Param ([long]$Type)

	If ($Type -ge 1TB) {
		[string]::Format("{0:0.00} TB", $Type / 1TB)
		}
	ElseIf ($Type -ge 1GB) {
		[string]::Format("{0:0.00} GB", $Type / 1GB)
		}
	ElseIf ($Type -ge 1MB) {
		[string]::Format("{0:0.00} MB", $Type / 1MB)
		}
	ElseIf (
		$Type -ge 1KB) {[string]::Format("{0:0.00} KB", $Type / 1KB)
		}
	ElseIf ($Type -gt 0) {
		[string]::Format("{0:0.00} Bytes", $Type)
		}
	Else {
		""
		}
	} # End of function

function send-Mail ($SMTPServer, $from, $to, $subject, $body) {
	$smtp = New-Object Net.Mail.SmtpClient($SMTPServer)
	$mail = New-Object System.Net.Mail.MailMessage
	$mail.from = $from
    $to | %{
	    $mail.to.add($_)
        }
	$mail.subject = $subject
	$mail.Body = $body

    $mail
	try {
		$smtp.Send($mail)
		}
	catch {
		$smtp
		}
	$body = ''
	}

function Invoke-SQL {
    param(
        [string] $dataSource = ".\SQLEXPRESS",
        [string] $database = "MasterData",
        [string] $sqlCommand = $(throw "Please specify a query.")
      )

	$connectionString = "Data Source={0}; Integrated Security=SSPI; Initial Catalog={1}" -f $dataSource, $Database

    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()

	$SQLcommand | Out-Host

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $SQLcommand
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null

    $connection.Close()
    $dataSet.Tables
}

Export-ModuleMember -Function 'format-*'
Export-ModuleMember -Function 'get-*'
Export-ModuleMember -Function 'send-*'
Export-ModuleMember -Function 'invoke-*'
