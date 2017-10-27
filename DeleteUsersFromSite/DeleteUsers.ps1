 $server = "http://localhost"
 $username = "glen"
 $password = "password"
 $siteID =""

 $CSVFile = Get-Content "C:\temp\UserList.csv"

 # Login to Server
 # generate body for sign in

 $signin_body = (’<tsRequest>
  <credentials name=“’ + $username + ’” password=“’+ $password + ’” >
   <site contentUrl="’ + $siteID +’"/>
  </credentials>
 </tsRequest>’)

 $Uri = "$server/api/2.7/auth/signin"
 $response = Invoke-RestMethod -Uri $uri -Body $signin_body -Method Post  

# get the auth token, site id and my user id
$authToken = $response.tsResponse.credentials.token
$siteID = $response.tsResponse.credentials.site.id

$headers = New-Object “System.Collections.Generic.Dictionary[[String],[String]]”
$headers.Add(“X-Tableau-Auth”, $authToken)
$authToken
$siteID

ForEach ($UserName in $CSVFile)
 {
   $UserName
   $response = Invoke-RestMethod -Uri $server/api/$api_ver/sites/$siteID/users?filter=name:eq:$UserName -Headers $headers -Method Get
   $UserID = $response.tsResponse.Users.User.id
   $response = Invoke-RestMethod -Uri $server/api/$api_ver/sites/$siteID/users/$UserID -Headers $headers -Method DELETE 
}

# Sign Out of Server
$response = Invoke-RestMethod -Uri $server/api/2.7/auth/signout -Headers $headers -Method Post
