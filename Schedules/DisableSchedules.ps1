#######################################################################################################
#     
#        PROGRAM: DisableSchedules.ps1
#
#    DESCRIPTION: Powershell script to disable Schedules on a Tableau server, using REST API
#                 Requires Tableau 10.1 onwards.
#
#     WRITTEN BY:  Glen Robinson (Interworks UK)
#
#
#######################################################################################################

$servername = "Server"
$user = "admin"
$pword = "password"

$api_ver = '2.4'

function TS-SignIn
{

 param(
 [string[]] $server,
 [string[]] $username,
 [string[]] $password,
 [validateset('http','https')][string[]] $protocol = 'http',
 [string[]] $siteID = ""
 )

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

 try
  {
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/auth/signin -Body $signin_body -Method Post
   # get the auth token, site id and my user id
   $global:authToken = $response.tsResponse.credentials.token
   $global:siteID = $response.tsResponse.credentials.site.id
   $global:myUserID = $response.tsResponse.credentials.user.id

   # set up header fields with auth token
   $global:headers = New-Object “System.Collections.Generic.Dictionary[[String],[String]]”
   # add X-Tableau-Auth header with our auth token
   $headers.Add(“X-Tableau-Auth”, $authToken)
   "Signed In Successfully to Server: "  + ${protocol}+"://"+$server
  }

  catch {"Unable to Sign-In to Tableau Server: " + ${protocol}+"://"+$server}
}


function TS-SignOut
{
 try
 {
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/auth/signout -Headers $headers -Method Post
  "Signed Out Successfully from: " + ${protocol}+ "://"+$server
 }
 catch {"Unable to Sign out from Tableau Server: " + ${protocol}+"://"+$server}
 
}

function TS-QuerySchedules
{
 try
 { 
  $PageSize = 100
  $PageNumber = 1
  $done = 'FALSE'

  While ($done -eq 'FALSE')
   {
    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/schedules?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
    $totalAvailable = $response.tsResponse.pagination.totalAvailable

    If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

    $PageNumber += 1
    $response.tsResponse.schedules.schedule
   }
  
 }
 catch{"Unable to Query Schedules"}
}

function TS-UpdateSchedule
{
param(
 [string[]] $ScheduleName = ""
 )

 try
 {
  $ID = TS-GetScheduleDetails -name $ScheduleName
  $ID

   $Schedule_request = "
        <tsRequest>
          <schedule
          state='Suspended'>
          
          </schedule>
        </tsRequest>
        "

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/schedules/$ID -Headers $headers -Method PUT -Body $Schedule_request
   $response.tsresponse.schedule
   
 }
 catch{"Unable to Query Extract Refresh Tasks"}
 
}

function TS-GetScheduleDetails
{
 param(
 [string[]] $Name = "",
 [string[]] $ID = ""
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
    if ($ID -eq $detail.ID){Return $detail.Name}
   }
 }
 
}


TS-SignIn -server $servername -username $user -password $pword
$Schedules = TS-QuerySchedules
Foreach ($schedule in $schedules){TS-UpdateSchedule $schedule.name}
TS-SignOut
