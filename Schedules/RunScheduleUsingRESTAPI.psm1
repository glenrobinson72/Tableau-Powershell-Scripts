param(
   [string[]] $server,
   [string[]] $username,
   [string[]] $password,
   [validateset('http','https')][string[]] $protocol = 'http',
   [string[]] $siteID = "",
   [string[]] $ScheduleName
 )

function TS-GetScheduleDetails
{
 param(
 [string[]] $Name = ""
 )
 
$PageSize = 100
$PageNumber = 1
$done = 'FALSE'

While ($done -eq 'FALSE')
 {
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/schedules?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get

  $totalAvailable = $response.tsResponse.pagination.totalAvailable

  If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

  $PageNumber += 1

  foreach ($detail in $response.tsResponse.schedules.schedule)
   { 
    if ($Name -eq $detail.name){Return $detail.ID}
   }
 }
 
}


 $api_ver = '2.8'

 $global:server = $server
 $global:protocol = $protocol
 $global:username = $username
 $global:password = $password

 # generate body for sign in
 $signin_body = (’<tsRequest>
  <credentials name=“’ + $username + ’” password=“’+ $password + ’” >
   <site contentUrl="’ + $siteID +’"/>
  </credentials>
 </tsRequest>’)

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/auth/signin -Body $signin_body -Method Post
   # get the auth token, site id and my user id
   $authToken = $response.tsResponse.credentials.token
   $siteID = $response.tsResponse.credentials.site.id
   $myUserID = $response.tsResponse.credentials.user.id

   # set up header fields with auth token
   $headers = New-Object “System.Collections.Generic.Dictionary[[String],[String]]”
   # add X-Tableau-Auth header with our auth tokents-
   $headers.Add(“X-Tableau-Auth”, $authToken)

#Get Schedule ID 

$ScheduleID = TS-GetScheduleDetails -Name $ScheduleName
$ScheduleID

#Get Tasks assigned to this schedule and run them8

  $PageSize = 100
  $PageNumber = 1
  $done = 'FALSE'

  While ($done -eq 'FALSE')
   {
    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/schedules/$ScheduleID/extracts?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
    $totalAvailable = $response.tsResponse.pagination.totalAvailable

    If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

    $PageNumber += 1

    ForEach ($detail in $response.tsResponse.extracts.extract)
     { 
       $TaskID = $detail.ID
       $body = "<tsRequest></tsRequest>"
       $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/tasks/extractRefreshes/$TaskID/runNow -Headers $headers -Method POST -Body $body -ContentType "text/xml"
       $response.tsresponse.job
      
     }
   }
  
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/auth/signout -Headers $headers -Method Post
  "Signed Out Successfully from: " + ${protocol}+ "://"+$server
