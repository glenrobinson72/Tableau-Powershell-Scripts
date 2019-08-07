add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
   }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12


$global:api_ver = '0.5'

function TSM-Login
{

 param(
 [string[]] $server,
 [string[]] $username,
 [string[]] $password
 )
    $login_body = ('{ "authentication": {"name": "'+ $username +'", "password": "'+$password +'"  } }')
    $global:URL_prefix = "https://"+$server + ":8850/api/"+$api_ver +"/"
    $URL = $URL_prefix + "login"

   $response = Invoke-WebRequest -Uri $URL -Body $login_body -Method Post -ContentType "application/json" -SessionVariable session
   "Login: "+ $response.StatusCode
   $global:session = $session
   $global:server = $server
   
}

function TSM-Logout
{

   # Logout
  $URL = $URL_prefix + "logout"
  $response = Invoke-WebRequest -Uri $URL  -Method Post -WebSession $session
  "Logout: "  + $response.StatusCode
  }

function TSM-Listnodes
{
   #list nodes
   $URL = $URL_prefix + "nodes"
   $response = Invoke-WebRequest -Uri $URL -Method Get -WebSession $session
   $r = $response.Content | ConvertFrom-Json

   $r.clusterstatus.nodes.services

}

function TSM-Topologies
{
   #list topologies
   $URL = $URL_prefix + "topologies"
   $response = Invoke-WebRequest -Uri $URL -Method Get -WebSession $session
   $r = $response.Content | ConvertFrom-Json

   $r.links.items

}




function TSM-Backup
{
 param(
 [string[]] $FileName = "backup"
 )

   #run backup 
    $URL = $URL_prefix + "backupFixedFile/?writePath="+$fileName

    $response = Invoke-WebRequest -Uri $URL -Method POST -WebSession $session
   $response

 }

 
function TSM-GetJobs
{

 # Get job info
 $URL = $URL_prefix + "asyncJobs/latest"
       $response = Invoke-WebRequest -Uri $URL -Method GET -WebSession $session
       $response
       "Latest"

$r = $response.Content | ConvertFrom-Json
$r.asyncjob

$r.asyncjob.Status
$createdAt = (([datetime]'1/1/1970').AddMilliseconds($r.asyncjob.createdAt)).DateTime
$createdAt

}

function TSM-Licensing
{

#Licensing
    $URL = $URL_prefix + "licensing"
       $response = Invoke-WebRequest -Uri $URL -Method GET -WebSession $session
     $r = $response.Content | ConvertFrom-Json
     $r.links.items
}

function TSM-ServerInfo
{

#Server Information
    $URL = $URL_prefix + "serverInfo"
       $response = Invoke-WebRequest -Uri $URL -Method GET -WebSession $session
     $r = $response.Content | ConvertFrom-Json
     $r.serverinfo
}

function TSM-SupportInfo
{

#Support Information
    $URL = $URL_prefix + "supportInfo"
       $response = Invoke-WebRequest -Uri $URL -Method GET -WebSession $session
     $r = $response.Content | ConvertFrom-Json
     $r.supportinfo
}

function TSM-Restart
{


#restart

    $URL = $URL_prefix + "restart"
       $response = Invoke-WebRequest -Uri $URL -Method POST -WebSession $session
      $response
}


function TSM-Status
{

    $URL = $URL_prefix + "status"
       $response = Invoke-WebRequest -Uri $URL -Method GET -WebSession $session

$r = $response.Content | ConvertFrom-Json
Write-host "STATUS:" $r.clusterstatus.rollupStatus
 $r.clusterstatus.nodes.services

}

function TSM-Start
{


#Start

    $URL = $URL_prefix + "enable"
       $response = Invoke-WebRequest -Uri $URL -Method POST -WebSession $session
      $response
}

function TSM-Stop
{


#Stop

    $URL = $URL_prefix + "disable"
       $response = Invoke-WebRequest -Uri $URL -Method POST -WebSession $session
      $response
}


