
 $server = "http://localhost"
 $username = "glen"
 $password = "password"
 $siteID =""


 $from_Address = "tableauServer@company.com"
 $smtpServer = "mailserver.company.com"
 $port = 25
       
 # Login to Server
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

$URL = "http://localhost/views/ExtractRefreshStatus/Last15Mins.csv?:refresh=yes"

$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "workgroup_session_id="+$authToken)
$CSVOutput = $webClient.DownloadString($Url) | ConvertFrom-Csv

foreach ($line in $CSVOutput)
 { 
     $email_Address = $line.Email
     $JobCreatedTime =  $line.'Created At'
     $JobCompletedTime =  $line.'Completed At'
     $JobName = $line.Title
     $EmailBody = $line.Notes
     $subject = "Extract: " + $JobName + " Completed at: " + $JobCompletedTime
     $Body = "<HTML><BODY>"+ $line.Notes + "</BODY></HTMl>"

     Send-MailMessage -From $from_Address -To $email_Address -SmtpServer $smtpServer -Subject $subject -Body $EmailBody -Port $port 
  }

# Sign Out of Server
$response = Invoke-RestMethod -Uri $server/api/2.5/auth/signout -Headers $headers -Method Post
