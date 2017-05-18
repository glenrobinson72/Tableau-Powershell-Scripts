
 $server = "http://localhost"
 $username = "glen"
 $password = "password"
 $siteID =""


 # Login to Server using REST API method
 # generate body for sign in
 $signin_body = (’<tsRequest>
  <credentials name=“’ + $username + ’” password=“’+ $password + ’” >
   <site contentUrl="’ + $siteID +’"/>
  </credentials>
 </tsRequest>’)

$Uri = "$server/api/2.5/auth/signin"
   $response = Invoke-RestMethod -Uri $uri -Body $signin_body -Method Post  

   # get the auth token, site id and my user id
   $authToken = $response.tsResponse.credentials.token
   $headers = New-Object “System.Collections.Generic.Dictionary[[String],[String]]”
   $headers.Add(“X-Tableau-Auth”, $authToken)
   $authToken

# File to download (including Refresh Data, and Filter)
$URL = "http://localhost/views/Superstore/Product.pdf:?refresh=yes&Region=South"

$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "workgroup_session_id="+$authToken)
#$webClient.DownloadString($Url)
$destination = "C:\temp\test.pdf"
$webClient.DownloadFile($URL, $destination)

# Sign Out of Server using REST API
$response = Invoke-RestMethod -Uri $server/api/2.5/auth/signout -Headers $headers -Method Post
