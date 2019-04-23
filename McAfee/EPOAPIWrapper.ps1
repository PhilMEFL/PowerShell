Add-Type -TypeDefinition @"
using System;
using System.Net;

public class myWebClient : WebClient {
  public int Timeout { get; set; }

  public myWebClient(Uri address) {
    this.Timeout = 600000;
  }

  protected override WebRequest GetWebRequest(Uri address) {
    var objWebRequest = base.GetWebRequest(address);
    objWebRequest.Timeout = this.Timeout;
    return objWebRequest;
  }
}
"@

function Invoke-EpoCommand {
  [CmdletBinding()]
  param(
    [Parameter(
      Mandatory=$true
    )]
    [string]
    $Command,

    [hashtable]
    $Parameters = @{}
  )

  $url = $script:EpoBaseUrl + $Command + "?"
  foreach ($key in $Parameters.Keys) {
    $url += $key + "=" + $Parameters.$key + "&"
  }
  $url += ":output=json"

  $response = $script:EpoWebClient.DownloadString($url)

  if ($response -cnotlike "OK:*") {
    $script:LastEpoError = [PSCustomObject]@{
      URL      = $url
      Response = $response
    }

    return $false
  }

  return $response.Substring(3).Trim() | ConvertFrom-Json
}

Invoke-EpoCommand system.find @{
  searchText = "LON-SVR1"
}
