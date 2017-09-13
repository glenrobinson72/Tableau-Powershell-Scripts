##############################################
#    
#   Module: Tableau-REST.psm1
#   Description: Tableau REST API through Powershell
#   Version: 1.7
#   Author: Glen Robinson (glen.robinson@interworks.co.uk)
#
#
###############################################

$global:api_ver = '2.4'

################## SIGN IN AND SIGN OUT ################################

function TS-ServerInfo
{
 try
  {
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/serverinfo -Method Get
   $api_Ver = $response.tsResponse.ServerInfo.restApiVersion
   $ProductVersion = $response.tsResponse.ServerInfo.ProductVersion.build
   "API Version: " + $api_Ver
   "Tableau Version: " + $ProductVersion
   $global:api_ver = $api_Ver
  }
  catch  
   {
     $global:api_ver = '2.2'
   }
}


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
 TS-ServerInfo

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
   # add X-Tableau-Auth header with our auth tokents-
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
 catch 
  {"Unable to Sign out from Tableau Server: " + ${protocol}+"://"+$server}
}


############################## Project Tasks


function TS-QueryProjects
{
 try
 {
 $api_ver
   $PageSize = 100
   $PageNumber = 1
   $done = 'FALSE'

   While ($done -eq 'FALSE')
   {
     $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
     $totalAvailable = $response.tsResponse.pagination.totalAvailable

     If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

     $PageNumber += 1

     $response.tsResponse.Projects.Project

   }
 } 
 catch {"Unable to query Projects"}
}

function TS-CreateProject
{
 param(
  [string[]] $ProjectName = "",
  [string[]] $Description = "",
  [validateset('ManagedByOwner','LockedToProject')][string[]] $ContentPermissions = "LockedToProject"
  )

 try
 {
  $request_body = ('<tsRequest><project name="' + $ProjectName +'" description="'+ $Description + '" contentPermissions="' +$ContentPermissions +'"/></tsRequest>')
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects -Headers $headers -Method POST -Body $request_body
  $response.tsResponse.project
 } 
 catch {"Unable to create Project: " + $ProjectName}
}

function TS-UpdateProject
{
 param(
  [string[]] $ProjectName,
  [string[]] $NewProjectName = "",
  [string[]] $Description = "",
  [validateset('ManagedByOwner','LockedToProject')][string[]] $ContentPermissions = ""
 )
 try
 {
  $ProjectID= TS-GetProjectDetails -projectname $ProjectName

  if ($NewProjectName -ne '') {$projectname_body = ' name ="'+ $NewProjectname +'"'} else {$projectname_body = ""} 
  if ($Description -ne '') {$description_body = ' description ="'+ $Description +'"'} else { $description_body = ""}
  if ($ContentPermissions -ne '') {$Permissions_body = ' contentPermissions ="'+ $ContentPermissions +'"'} else { $Permissions_body = ""}
 
  $request_body = ('<tsRequest><project' + $projectname_body + $description_body + $Permissions_body + ' /></tsRequest>')
  $request_body
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID -Headers $headers -Method Put -Body $request_body
  $response.tsResponse.project
 }
 catch {"Unable to Update Project: " + $ProjectName}

}

function TS-DeleteProject
{
 param(
  [string[]] $ProjectName
  )
  try
  {
   $ProjectID= TS-GetProjectDetails -projectname $ProjectName
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID -Headers $Headers -Method Delete
   $response.tsResponse
  }
  catch {"Unable to delete Project: "+$ProjectName}
}


function TS-GetProjectDetails
{
 param(
 [string[]] $ProjectName = "",
 [string[]] $ProjectID = ""
 )
 
  $PageSize = 100
  $PageNumber = 1
  $done = 'FALSE'

  While ($done -eq 'FALSE')
   {
     $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
     $totalAvailable = $response.tsResponse.pagination.totalAvailable

     If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

     $PageNumber += 1

     foreach ($project_detail in $response.tsResponse.Projects.Project)
     { 
      if ($projectName -eq $project_detail.name){Return $Project_detail.ID}
      if ($projectID -eq $project_detail.ID){Return $Project_detail.Name}
     }
   }
}


################################################## Site Management

function TS-QuerySites
{
 try
 {
  $PageSize = 100
  $PageNumber = 1
  $done = 'FALSE'

  While ($done -eq 'FALSE')
   {
     $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
     $totalAvailable = $response.tsResponse.pagination.totalAvailable

     If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

     $PageNumber += 1
     $response.tsresponse.Sites.site
   }
 }
 catch {"Unable to Query Sites."}
}

function TS-QuerySite
{
 try
 {
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID -Headers $headers -Method Get
  $response.tsResponse.Site
 }
 catch {"Unable to Query Site."}
}

function TS-UpdateSite
{
 param(
  [string[]] $NewSiteName = "",
  [string[]] $NewSiteID = "",
  [validateset('ContentAndUsers','ContentOnly')][string[]] $AdminMode = "",
  [string[]] $UserQuota = "",
  [validateset('Active','Suspended')][string[]] $State = "",
  [string[]] $StorageQuota = "",
  [validateset('true','false')][string[]] $DisableSubscriptions = "",
  [validateset('true','false')][string[]] $RevisionHistoryEnabled = "",
  [validateRange(2,10000)][string[]] $RevisionLimit = ""
 )

 try
 {
  $body = ""
  if ($NewSiteName -ne '') {$body += ' name ="'+ $NewSitename +'"'}
  if ($NewSiteID -ne '') {$body += ' contentUrl ="'+ $NewSiteID +'"'}
  if ($AdminMode -ne '') {$body += ' adminMode ="'+ $AdminMode +'"'}
  if ($UserQuota -ne '') {$body += ' userQuota ="'+ $UserQuota +'"'}
  if ($State -ne '') {$body += ' state ="'+ $State +'"'}
  if ($StorageQuota -ne '') {$body += ' storageQuota ="'+ $StorageQuota +'"'}
  if ($DisableSubscriptions -ne '') {$body += ' disableSubscriptions ="'+ $DisableSubscriptions +'"'}
  if ($RevisionHistoryEnabled -ne '') {$body += ' revisionHistoryEnabled ="'+ $RevisionHistoryEnabled +'"'}
  if ($RevisionLimit -ne '') {$body += ' adminMode ="'+ $RevisionLimit +'"'}

  $body = ('<tsRequest><site' + $body +  ' /></tsRequest>')
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID -Headers $headers -Method Put -Body $body
  $response.tsResponse.Site
 }
 catch{"Problem updating Site: " + $SiteName }
}


function TS-CreateSite
{
 param(
  [string[]] $SiteName = "",
  [string[]] $SiteID = "",
  [validateset('ContentAndUsers','ContentOnly')][string[]] $AdminMode = "",
  [string[]] $StorageQuota = "",
  [string[]] $UserQuota = "",
  [validateset('true','false')][string[]] $DisableSubscriptions = ""
 )
 
 try
 {
  $body = ""
  if ($SiteName -ne '') {$body += ' name ="'+ $Sitename +'"'}
  if ($SiteID -ne '') {$body += ' contentUrl ="'+ $SiteID +'"'}
  if ($AdminMode -ne '') {$body += ' adminMode ="'+ $AdminMode +'"'}
  if ($UserQuota -ne '') {$body += ' userQuota ="'+ $UserQuota +'"'}
  if ($StorageQuota -ne '') {$body += ' storageQuota ="'+ $StorageQuota +'"'}
  if ($DisableSubscriptions -ne '') {$body += ' disableSubscriptions ="'+ $DisableSubscriptions +'"'}

  $body = ('<tsRequest><site' + $body +  ' /></tsRequest>')
  $body
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites -Headers $headers -Method POST -Body $body
  $response.tsResponse.Site
 }
 catch{"Problem Creating Site: " + $SiteName }
}

function TS-ChangeToSite
{
 param(
 [string[]] $SiteID = ""
 )
 try
 { 
  TS-SignOut
  TS-SignIn -username $username -password $password -server $server -protocol $protocol -siteID $SiteID
 }
 Catch {"Unable to Change to Site: " + $SiteID }
}


function TS-DeleteSite
{
 param ([validateset('Yes','No')][string[]] $AreYouSure = "No")
 if ($AreYouSure -eq "Yes")
 {
  try
   {
    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID -Headers $Headers -Method Delete
    $response.tsResponse
   }
   catch {"Unable to delete Site."}
 }
}

########################## GROUPS ###########################


function TS-CreateGroup
{
  param(
 [string[]] $GroupName = "",
 [string[]] $DomainName = "",
 [validateset('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish')][string[]] $SiteRole = "Unlicensed",
 [validateset('True', 'False')][string[]] $BackgroundTask = "True"
 )
 #try
 #{
   if (-not($DomainName)) 
    { # Local Group Creation
    "AA"
      $body = ('<tsRequest><group name="' + $GroupName +  '" /></tsRequest>')
      $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/groups -Headers $headers -Method POST -Body $body
      $response.tsResponse.group
    }
   else
    {  # Active Directory Group Creation

      $body = ('<tsRequest><group name="' + $GroupName + '" ><import source="ActiveDirectory" domainName="' +$DomainName + '" siteRole="' + $SiteRole +'" /></group></tsRequest>')
            $body

      $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/groups -Headers $headers -Method POST -Body $body
      $response.tsResponse.group
    }
 # }
 #catch {"Unable to Create Group: " + $GroupName}
}


function TS-DeleteGroup
{
param(
  [string[]] $GroupName,
  [string[]] $DomainName ="local"

  )
  try
  {
   $GroupID = TS-GetGroupDetails -name $GroupName -Domain $DomainName
   $GRoupID

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/groups/$GroupID -Headers $Headers -Method Delete
   $response.tsResponse
  }
  catch {"Unable to delete Group: "+$GroupName}
}

function TS-QueryGroups
{
  try
   {
    $PageSize = 100
    $PageNumber = 1
    $done = 'FALSE'

    While ($done -eq 'FALSE')
    {
      $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/groups?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
      $totalAvailable = $response.tsResponse.pagination.totalAvailable

      If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}
      $PageNumber += 1

      ForEach ($detail in $response.tsResponse.Groups.Group)
       { 
        $Groups = [pscustomobject]@{Name=$detail.name; Domain=$detail.Domain.Name}
        $Groups
       }
    }
   }
  catch {"Unable to query Groups."}
}


function TS-UpdateGroup
{
 param(

  )
  try
  {

   $GroupID = TS-GetGroupDetails -name $GroupName -Domain $DomainName
   $GRoupID

   if ($DomainName -eq "Local") 
    { # Local Group Update
     $body = ('<tsRequest><group name="' + $NewGroupName +  '" /></tsRequest>')
     $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/groups/$GroupID -Headers $headers -Method PUT -Body $body
     $response.tsResponse.group
    }
   else
    {  # Active Directory Group Update

      $body = ('<tsRequest><group name="' + $GroupName + '" ><import source="ActiveDirectory" domainName="' +$DomainName + '" siteRole="' + $SiteRole +'" /></group></tsRequest>')
      $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/groups/$GroupID -Headers $headers -Method PUT -Body $body
      $response.tsResponse.group
    }
  }
  catch {"Unable to Update Group: "+$GroupName}
}

    
function TS-GetGroupDetails
{
 param(
 [string[]] $Name = "",
 [string[]] $ID = "",
 [string[]] $Domain ="local"
 )
 
 $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/groups -Headers $headers -Method Get

 foreach ($detail in $response.tsResponse.Groups.Group)
  { 
   if ($Name -eq $detail.name -and $Domain -eq $detail.Domain.Name){Return $detail.ID}
   if ($ID -eq $detail.ID){Return $detail.Name}
  }
}


################## User Functions

function TS-GetUsersOnSite
{ 
 try
  {
   $PageSize = 100
   $PageNumber = 1
   $done = 'FALSE'

   While ($done -eq 'FALSE')
    {
     $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/users?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
     $totalAvailable = $response.tsResponse.pagination.totalAvailable

     If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}
     $PageNumber += 1
     $response.tsResponse.Users.User
    }
  }
  catch {"Unable to Get User List from Site"}
}

function TS-AddUserToGroup
{
 param(
  [string[]] $GroupName,
  [string[]] $UserAccount
  )
  try
  {
   $GroupID = TS-GetGroupDetails -name $GroupName
   $UserID  = TS-GetUserDetails -name $UserAccount
   $body = ('<tsRequest><user id="' + $UserID +  '" /></tsRequest>')
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/groups/$GroupID/users -Headers $headers -Method POST -Body $body
   $response.tsResponse.user
  }
  catch {"Unable to Add User "+ $UserAccount + " to Group: "+$GroupName}
}


function TS-RemoveUserFromGroup
{
 param(
  [string[]] $GroupName,
  [string[]] $UserAccount
  )
  try
  {
   $GroupID = TS-GetGroupDetails -name $GroupName
   $UserID  = TS-GetUserDetails -name $UserAccount
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/groups/$GroupID/users/$UserID -Headers $headers -Method DELETE 
  }
  catch {"Unable to Remove User "+ $UserAccount + " from Group: "+$GroupName}
}

function TS-RemoveUserFromSite
{
 param(
  [string[]] $UserAccount
  )
  try
  {
   $UserID  = TS-GetUserDetails -name $UserAccount
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/users/$UserID -Headers $headers -Method DELETE 
  }
  catch {"Unable to Remove User from Site: "+ $UserAccount }
}


function TS-GetUserDetails
{
 param(
 [string[]] $name = "",
 [string[]] $ID = ""
 )
 
  $PageSize = 100
  $PageNumber = 1
  $done = 'FALSE'

  While ($done -eq 'FALSE')
   {
    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/users?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
    $totalAvailable = $response.tsResponse.pagination.totalAvailable

    If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}
      $PageNumber += 1
      foreach ($detail in $response.tsResponse.Users.User)
       { 
        if ($Name -eq $detail.name){Return $detail.ID}
        if ($ID -eq $detail.ID){Return $detail.Name}
       }
   }
}

function TS-GetUsersInGroup
{

param(
  [string[]] $GroupName
  )
  try
  {
   $PageSize = 100
   $PageNumber = 1
   $done = 'FALSE'
   $GroupID = TS-GetGroupDetails -name $GroupName

   While ($done -eq 'FALSE')
    {
     $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/groups/$GroupID/users?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
     $totalAvailable = $response.tsResponse.pagination.totalAvailable

     If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}
     $PageNumber += 1
     $response.tsResponse.Users.User
    }
  }
  catch {"Unable to Get Users in Group: "+$GroupName}
}


function TS-QueryUser
{
 param(
  [string[]] $UserAccount
  )
  try
  {
   $UserID = TS-GetUserDetails -name $UserAccount
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/users/$UserID -Headers $headers -Method GET 

   ForEach ($detail in $response.tsResponse.User)
       { 
        $User = [pscustomobject]@{Name=$detail.name; SiteRole=$detail.siteRole; LastLogin=$detail.lastLogin; FullName=$detail.FullName; Domain=$detail.Domain.Name; externalAuthUserId=$detail.externalAuthUserID; authSetting=$detail.authSetting}
        $User
       }
  }
  catch
  {
  "Unable to Get User Information: "+$UserAccount
  }
}

function TS-AddUserToSite
{
  param(
 [string[]] $UserAccount = "",
 [validateset('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish')][string[]] $SiteRole = "Unlicensed"
 
 )

 try
  {
   $body = ('<tsRequest><user name="' + $UserAccount +  '" siteRole="'+ $SiteRole +'"/></tsRequest>')
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/users -Headers $headers -Method POST -Body $body
   $response.tsResponse.user
  }
  catch {"Unable to Create User: " + $UserAccount}
}

function TS-UpdateUser
{
 param(
 [string[]] $UserAccount = "",
 [string[]] $Fullname = "",
 [string[]] $Password = "",
 [string[]] $Email = "",
 [validateset('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish')][string[]] $SiteRole = ""
 )
 
 try
   { 
    $UserID = TS-GetUserDetails -Name $UserAccount

    $body = ""
    if ($FullName -ne '') {$body += ' fullName ="'+ $FullName +'"'}
    if ($Password -ne '') {$body += ' password ="'+ $Password +'"'}
    if ($Email -ne '') {$body += ' email ="'+ $Email +'"'}
    if ($SiteRole -ne '') {$body += ' siteRole ="'+ $SiteRole +'"'}

    $body = ('<tsRequest><user' + $body +  ' /></tsRequest>')

    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/users/$UserID -Headers $headers -Method Put -Body $body
    $response.tsResponse.User
   }
   catch{"Problem updating User: " + $UserAccount }
}


###################### DataSource Functions


function TS-QueryDataSources
{
 try
  {
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources -Headers $headers -Method Get

   ForEach ($detail in $response.tsResponse.datasources.datasource)
   {
    $owner = TS-GetUserDetails -ID $detail.owner.id
    $DataSources = [pscustomobject]@{Name=$detail.name; Project=$detail.project.name; Owner=$owner; UpdatedAt = $detail.updatedAt;ContentURL=$detail.ContentURL}
    $DataSources
   }
  }
  catch{"Unabled to query Data Sources."}
}  


function TS-QueryDataSource
{
 param(
 [string[]] $DataSourceName = "",
 [string[]] $ProjectName = ""
 )
 try
 {
   $DS_ID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName
   $DS_ID
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DS_ID -Headers $headers -Method GET 

   ForEach ($detail in $response.tsresponse.datasource)
   {
    $owner = TS-GetUserDetails -ID $detail.owner.id
    $DataSource = [pscustomobject]@{Name=$detail.name; Project=$detail.project.name; Owner=$owner; CreatedAt = $detail.createdat; UpdatedAt = $detail.updatedAt;ContentURL=$detail.ContentURL; type=$detail.type; tags=$detail.tags.tag.label}
    $DataSource
   }
 }
 catch { "Unable to Query Data Source Connections: " + $DataSourceName}
}


function TS-QueryDataSourceConnections
{
 param(
 [string[]] $DataSourceName = "",
 [string[]] $ProjectName = ""
 )
 try
 {
   $DS_ID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName
   $DS_ID
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DS_ID/connections -Headers $headers -Method GET 
  $response.tsResponse.Connections.connection
 }
catch { "Unable to Query Data Source Connections: " + $DataSourceName}
    
}

function TS-GetDataSourceDetails
{
 param(
 [string[]] $Name = "",
 [string[]] $ID = "",
 [string[]] $ProjectName = ""
 )
 
$PageSize = 100
$PageNumber = 1
$done = 'FALSE'

While ($done -eq 'FALSE')
 {
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
  $totalAvailable = $response.tsResponse.pagination.totalAvailable

  If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

  $PageNumber += 1

  foreach ($detail in $response.tsResponse.DataSources.DataSource)
   { 
    if ($Name -eq $detail.name -and $ProjectName -eq $detail.project.name){Return $detail.ID}
    if ($ID -eq $detail.ID){Return $detail.Name}
   }
 }
}


function TS-PublishDataSource
{

 param(
 [string[]] $ProjectName = "",
 [string[]] $DataSourceName = "",
 [string[]] $DataSourceFile = "",
 [string[]] $DataSourcePath = "",
 [string[]] $UserAccount = "",
 [string[]] $Password = "",
 [validateset('True', 'False')][string[]] $Embed = "",
 [validateset('True', 'False')][string[]] $OAuth = "", 
 [validateset('True', 'False')][string[]] $OverWrite = "False"
 )

 try
  {
   $project_ID = TS-GetProjectDetails -ProjectName $ProjectName
   $DS_Content = Get-Content $DataSourcePath\$DataSourceFile -Raw

   $connectionCredentials = ""
   if ($UserAccount -ne '') {$connectionCredentials += ' name ="'+ $UserAccount +'"'}
   if ($Password -ne '') {$connectionCredentials += ' password ="'+ $Password +'"'}
   if ($embed -ne '') {$connectionCredentials += ' embed ="'+ $embed +'"'}
   if ($OAuth -ne '') {$connectionCredentials += ' oAuth ="'+ $OAuth +'"'} 
   if ($connectionCredentials -ne ''){$connectionCredentials = '<connectionCredentials'+ $connectionCredentials + ' />'}

$request_body = '
--6691a87289ac461bab2c945741f136e6
Content-Disposition: name="request_payload"
Content-Type: text/xml

<tsRequest>
    <datasource name="' + $DataSourceName + '" >
    ' + $connectionCredentials + '
        <project id="' + $project_ID + '" />
  </datasource>
</tsRequest>
--6691a87289ac461bab2c945741f136e6
Content-Disposition: name="tableau_datasource"; filename="' + $DataSourceFile +'"
Content-Type:  application/octet-stream

' + $DS_Content + '
--6691a87289ac461bab2c945741f136e6--
'

  $url = $protocol.trim() + "://" + $server +"/api/" + $api_ver+ "/sites/" + $siteID + "/datasources?overwrite=" +$overwrite
 
  $wc = New-Object System.Net.WebClient
  $wc.Headers.Add('X-Tableau-Auth',$headers.Values[0])
  $wc.Headers.Add('ContentLength', $request_body.Length)
  $wc.Headers.Add('Content-Type', 'multipart/mixed; boundary=6691a87289ac461bab2c945741f136e6')
  $response = $wc.UploadString($url ,'POST', $request_body)
  "Data Source " + $DataSourceName + " was successfully published to " + $ProjectName + " Project."
 }
 catch {"Unable to publish Data Source."}

}


function TS-PublishWorkbook
{
 param(
 [string[]] $ProjectName = "",
 [string[]] $WorkbookName = "",
 [string[]] $WorkbookFile = "",
 [string[]] $WorkbookPath = "",
 [string[]] $UserAccount = "",
 [string[]] $Password = "",
 [validateset('True', 'False')][string[]] $Embed = "",
 [validateset('True', 'False')][string[]] $OAuth = "", 
 [validateset('True', 'False')][string[]] $OverWrite = "False",
 [validateset('True', 'False')][string[]] $ShowTabs = "False"

 )
 try
  {
    $project_ID = TS-GetProjectDetails -ProjectName $ProjectName
    $WB_Content = Get-Content $WorkbookPath\$workbookfile -Raw
    $Connection_Details = ""
   if ($UserAccount -ne '') {$Connection_Details += '<connectionCredentials name ="'+ $UserAccount +'"'}
   if ($Password -ne '') {$Connection_Details += ' password ="'+ $Password +'"'}
   if ($Embed -ne '') {$Connection_Details += ' embed ="'+ $Embed +'"'}
   if ($OAuth -ne '') {$Connection_Details += ' oAuth ="'+ $OAuth +'"'}
   if ($UserAccount -ne '') {$Connection_Details += '/>'}


$request_body = '
--6691a87289ac461bab2c945741f136e6
Content-Disposition: name="request_payload"
Content-Type: text/xml

<tsRequest>
   <workbook name="' + $WorkbookName + '" showTabs="'+ $ShowTabs +'">
' + $Connection_Details + '
     <project id="' + $project_ID + '" />
  </workbook>
</tsRequest>
--6691a87289ac461bab2c945741f136e6
Content-Disposition: name="tableau_workbook";filename="' + $WorkbookFile + '"
Content-Type: application/octet-stream

' + $WB_Content + '
--6691a87289ac461bab2c945741f136e6--'
#$request_body
#$request_body | Out-File D:\Downloads\simpletwbupload.txt 
$url = $protocol.trim() + "://" + $server +"/api/" + $api_ver+ "/sites/" + $siteID + "/workbooks?overwrite=" +$overwrite
 
$wc = New-Object System.Net.WebClient
$wc.Headers.Add('X-Tableau-Auth',$headers.Values[0])
$wc.Headers.Add('ContentLength', $request_body.Length)

$wc.Headers.Add('Content-Type', 'multipart/mixed; boundary=6691a87289ac461bab2c945741f136e6')
$response = $wc.UploadString($url ,'POST', $request_body)
"Workbook published successfully."

 }
 catch {"Unable to publish workbook."}
}


function TS-DeleteDataSource
{
 param(
 [string[]] $ProjectName = "",
 [string[]] $DataSourceName = ""
 )
 try
 {
   $DS_ID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DS_ID -Headers $headers -Method DELETE 
   $response.tsresponse
 }
 catch { "Unable to Delete Data Source: " + $DataSourceName}
}


function TS-UpdateDataSource
{
 param(
 [string[]] $DataSourceName = "",
 [string[]] $ProjectName = "",
 [string[]] $NewProjectName = "",
 [string[]] $NewOwnerAccount = ""
 
 )
 try
 {
   $DS_ID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName
   $userID = TS-GetUserDetails -name $NewOwnerAccount
   $ProjectID = TS-GetProjectDetails -ProjectName $NewProjectName

   $body = ""
   if ($NewProjectName -ne '') {$body += '<project id ="'+ $ProjectID +'" />'}
   if ($NewOwnerAccount -ne '') {$body += '<owner id ="'+ $userID +'"/>'}

   $body = ('<tsRequest><datasource>' + $body +  ' </datasource></tsRequest>')

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DS_ID -Headers $headers -Method Put -Body $body
   $response.tsResponse.datasource
 }
 catch { "Unable to Update Data Source: " + $DataSourceName}
}

function TS-UpdateDataSourceConnection
{
 param(
 [string[]] $DataSourceName = "",
 [string[]] $ProjectName = "",
 [string[]] $ServerName = "",
 [string[]] $Port = "",
 [string[]] $UserName = "",
 [string[]] $Password = "",
 [validateset('True', 'False')][string[]] $embed = ""
 )
 try
 {
   $DS_ID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName
   $DS_ID
   $body = ""
   if ($ServerName -ne '') {$body += 'serverAddress ="'+ $ServerName +'" '}
   if ($Port -ne '') {$body += 'serverPort ="'+ $Port +'" '}
   if ($UserName -ne '') {$body += 'userName ="'+ $UserName +'" '}
   if ($Password -ne '') {$body += 'password ="'+ $Password +'" '}
   if ($embed -ne '') {$body += 'embedPassword ="'+ $embed +'" '}
   
   $body = ('<tsRequest><connection ' + $body +  '/></tsRequest>')
   $body
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DS_ID/connection -Headers $headers -Method Put -Body $body
   $response.tsResponse.connection
 }
 catch { "Unable to Update Data Source: " + $DataSourceName}
}


###### PERMISSIONS


function TS-QueryProjectPermissions
{
param(
  [string[]] $ProjectName = ""
  )

 try
  {
   $ProjectID= TS-GetProjectDetails -projectname $ProjectName

   $content_types = ("Project","Workbook","DataSource")
   $content_locations = ("permissions","default-permissions/workbooks","default-permissions/datasources")
   $count = 0

   While($count -lt $content_types.Count) 
    {
     $location = $content_Locations[$count]
     $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/$location -Headers $headers -Method Get
 
     foreach ($detail in $response.tsResponse.permissions.granteeCapabilities)
      { 
       $Type = ""
       if($detail.group.id) 
        {
         $GroupUser = TS-GetGroupDetails -ID $detail.group.id
         $Type = "Group"  
        }

       if ($detail.user.id)
        {
         $GroupUser = TS-GetUserDetails -ID $detail.user.id
         $Type = "User" 
        }
  
       foreach ($capability in $detail.capabilities.capability)
        {
         $Permissions = [pscustomobject]@{UserOrGroup = $GroupUser; Type = $Type;AffectedObject=$content_types[$count];Capability=$capability.name; Rights=$capability.mode}
         $Permissions
        }
      }
     $count++
    }


   }
  catch{"Unable to query Project Permissions: " + $ProjectName  }
}


function TS-QueryWorkbookPermissions
{
param(
  [string[]] $ProjectName = "",
  [string[]] $WorkbookName = ""
  )

 try
  {
   $workbookID= TS-GetWorkbookDetails -Name $workbookName -ProjectName $ProjectName
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$WorkbookID/permissions -Headers $headers -Method Get
 
     foreach ($detail in $response.tsResponse.permissions.granteeCapabilities)
      { 
       $Type = ""
       if($detail.group.id) 
        {
         $GroupUser = TS-GetGroupDetails -ID $detail.group.id
         $Type = "Group"  
        }

       if ($detail.user.id)
        {
         $GroupUser = TS-GetUserDetails -ID $detail.user.id
         $Type = "User" 
        }
  
       foreach ($capability in $detail.capabilities.capability)
        {
         $Permissions = [pscustomobject]@{UserOrGroup = $GroupUser; Type = $Type;Capability=$capability.name; Rights=$capability.mode}
         $Permissions
        }
      }
   }
  catch{"Unable to query Workbook Permissions: " + $WorkbookName  }
}


function TS-QueryDataSourcePermissions
{
param(
  [string[]] $ProjectName = "",
  [string[]] $DataSourceName = ""
  )

 try
  {
   $DataSourceID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DataSourceID/permissions -Headers $headers -Method Get
 
     foreach ($detail in $response.tsResponse.permissions.granteeCapabilities)
      { 
       $Type = ""
       if($detail.group.id) 
        {
         $GroupUser = TS-GetGroupDetails -ID $detail.group.id
         $Type = "Group"  
        }

       if ($detail.user.id)
        {
         $GroupUser = TS-GetUserDetails -ID $detail.user.id
         $Type = "User" 
        }
  
       foreach ($capability in $detail.capabilities.capability)
        {
         $Permissions = [pscustomobject]@{UserOrGroup = $GroupUser; Type = $Type;Capability=$capability.name; Rights=$capability.mode}
         $Permissions
        }
      }
   }
  catch{"Unable to query DataSources Permissions: " + $DataSourceName }
}


function TS-UpdateProjectPermissions
{
param(
  [string[]] $ProjectName = "",
  [string[]] $GroupName = "",
  [string[]] $UserAccount = "",
  #Project Permissions
  [validateset('Allow', 'Deny', 'Blank')][string[]] $ViewProject = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $SaveProject = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $ProjectLeader = "",

  #Workbook Permissions
  [validateset('Allow', 'Deny', 'Blank')][string[]] $ViewWorkbook = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DownloadImagePDF = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DownloadSummaryData = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $ViewComments = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $AddComments = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $Filter = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DownloadFullData = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $ShareCustomized = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $WebEdit = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $SaveWorkbook = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $MoveWorkbook = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DeleteWorkbook = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DownloadWorkbook = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $SetWorkbookPermissions = "",

  #DataSource Permissions
  [validateset('Allow', 'Deny', 'Blank')][string[]] $ViewDataSource = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $Connect = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $SaveDataSource = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DownloadDataSource = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DeleteDataSource = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $SetDataSourcePermissions = ""
 )

try
 {

  $GroupID = ''
  $UserID = ''

  $ProjectID= TS-GetProjectDetails -projectname $ProjectName
  if ($GroupName -ne '')
   {
    $GroupID = TS-GetGroupDetails -name $GroupName
    $affectedObject = '      <group id="' + $GroupID +'" />'
   }

  if ($UserAccount -ne '')
   {
    $UserID = TS-GetUserDetails -name $UserAccount
    $affectedObject = '      <user id="' + $UserID +'" />'
   }

   # Check Existing Project Permissions

  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/permissions -Headers $headers -Method Get

  foreach ($detail in $response.tsResponse.permissions.granteeCapabilities)
   { 
    if ($groupID -ne '' -and $groupID -eq $detail.group.id)
     {
       # Group is already permissioned against Project

      #"GroupID " + $GroupID
 
       # Check existing permissions
 
        ForEach ($permission in $detail.capabilities.capability)
           {
            
                if (($ViewProject -ne '' -and $permission.name -eq 'Read') -or ($SaveProject -ne '' -and $permission.name -eq 'Write') -or ($ProjectLeader -ne '' -and $permission.name -eq 'ProjectLeader'))
                 {
                    $permission_name = $permission.name
                    $permission_mode = $permission.mode
                    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/permissions/groups/$groupID/$permission_name/$permission_mode -Headers $headers -Method Delete
                 }
            }
     } 

    if ($UserID -ne '' -and $UserID -eq $detail.user.id)
     {
       # User is already permissioned against Project

        ForEach ($permission in $detail.capabilities.capability)
           {
                if (($ViewProject -ne '' -and $permission.name -eq 'Read') -or ($SaveProject -ne '' -and $permission.name -eq 'Write') -or ($ProjectLeader -ne '' -and $permission.name -eq 'ProjectLeader'))
                 {
                    $permission_name = $permission.name
                    $permission_mode = $permission.mode
#                    $permission_name, $permission_mode
                    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/permissions/users/$userID/$permission_name/$permission_mode -Headers $headers -Method Delete
                 }
            }
     } 
   }

   # Set New Group / User Permissions

   $ProjectCapabilities = ""
   If ($ViewProject -eq 'Allow' -or $ViewProject -eq 'Deny'){$ProjectCapabilities += '        <capability name="Read" mode="' + $ViewProject +'" />'}
   If ($SaveProject -eq 'Allow' -or $SaveProject -eq 'Deny'){$ProjectCapabilities += '        <capability name="Write" mode="' + $SaveProject +'" />'}
   If ($ProjectLeader -eq 'Allow' -or $ProjectLeader -eq 'Deny'){$ProjectCapabilities += '        <capability name="ProjectLeader" mode="' + $ProjectLeader +'" />'}

#   $projectCapabilities
   $Project_Request = '
        <tsRequest>
          <permissions>
            <granteeCapabilities>'     + $affectedObject + '
              <capabilities>' + $ProjectCapabilities + '
              </capabilities>
            </granteeCapabilities>
          </permissions>
        </tsRequest>
        '

#   $Project_Request

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/permissions -Headers $headers -Method PUT -Body $Project_request
   #$response.tsResponse

  # Check existing Workbook Permissions

  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/default-permissions/workbooks -Headers $headers -Method Get

  foreach ($detail in $response.tsResponse.permissions.granteeCapabilities)
   { 
    if ($groupID -ne '' -and $groupID -eq $detail.group.id)
     {
       # Group is already permissioned against Project

      #"GroupID " + $GroupID
 
       # Check existing permissions
 
        ForEach ($permission in $detail.capabilities.capability)
           {
             if (($ViewWorkbook -ne '' -and $permission.name -eq 'Read') -or ($DownloadImagePDF -ne '' -and $permission.name -eq 'ExportImage') -or ($DownloadSummaryData -ne '' -and $permission.name -eq 'ExportData') -or ($ViewComments -ne '' -and $permission.name -eq 'ViewComments') -or ($AddComments -ne '' -and $permission.name -eq 'AddComment') -or ($Filter -ne '' -and $permission.name -eq 'Filter') -or ($DownloadFullData -ne '' -and $permission.name -eq 'ViewUnderlyingData') -or ($ShareCustomized -ne '' -and $permission.name -eq 'ShareView') -or ($WebEdit -ne '' -and $permission.name -eq 'WebAuthoring') -or ($SaveWorkbook -ne '' -and $permission.name -eq 'Write') -or ($MoveWorkbook -ne '' -and $permission.name -eq 'ChangeHierarchy') -or ($DeleteWorkbook -ne '' -and $permission.name -eq 'Delete') -or ($DownloadWorkbook -ne '' -and $permission.name -eq 'ExportXML') -or ($SetWorkbookPermissions -ne '' -and $permission.name -eq 'ChangePermissions'))
                 {
                    $permission_name = $permission.name
                    $permission_mode = $permission.mode
                   # $permission_name, $permission_mode
                    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/default-permissions/workbooks/groups/$groupID/$permission_name/$permission_mode -Headers $headers -Method Delete

                    #DELETE /api/api-version/sites/site-id/projects/project-id/default-permissions/workbooks/groups/group-id/capability-name/capability-mode
                 }
           }
     } 

    if ($UserID -ne '' -and $UserID -eq $detail.user.id)
     {
       # User is already permissioned against Project

      #"UserID " + $UserID

        ForEach ($permission in $detail.capabilities.capability)
           {
             if (($ViewWorkbook -ne '' -and $permission.name -eq 'Read') -or ($DownloadImagePDF -ne '' -and $permission.name -eq 'ExportImage') -or ($DownloadSummaryData -ne '' -and $permission.name -eq 'ExportData') -or ($ViewComments -ne '' -and $permission.name -eq 'ViewComments') -or ($AddComments -ne '' -and $permission.name -eq 'AddComment') -or ($Filter -ne '' -and $permission.name -eq 'Filter') -or ($DownloadFullData -ne '' -and $permission.name -eq 'ViewUnderlyingData') -or ($ShareCustomized -ne '' -and $permission.name -eq 'ShareView') -or ($WebEdit -ne '' -and $permission.name -eq 'WebAuthoring') -or ($SaveWorkbook -ne '' -and $permission.name -eq 'Write') -or ($MoveWorkbook -ne '' -and $permission.name -eq 'ChangeHierarchy') -or ($DeleteWorkbook -ne '' -and $permission.name -eq 'Delete') -or ($DownloadWorkbook -ne '' -and $permission.name -eq 'ExportXML') -or ($SetWorkbookPermissions -ne '' -and $permission.name -eq 'ChangePermissions'))
                 {
                    $permission_name = $permission.name
                    $permission_mode = $permission.mode
                    #$permission_name, $permission_mode
                    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/default-permissions/workbooks/users/$userID/$permission_name/$permission_mode -Headers $headers -Method Delete
                 }
            }
     } 
   }
   
   $WorkbookCapabilities = ""
   If ($ViewWorkbook -eq 'Allow' -or $ViewWorkbook -eq 'Deny'){$WorkbookCapabilities += '        <capability name="Read" mode="' + $ViewWorkbook +'" />'}
   If ($SaveWorkbook -eq 'Allow' -or $SaveWorkbook -eq 'Deny'){$WorkbookCapabilities += '        <capability name="Write" mode="' + $SaveWorkbook +'" />'}
   If ($DownloadImagePDF -eq 'Allow' -or $DownloadImagePDF -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ExportImage" mode="' + $DownloadImagePDF +'" />'}
   If ($DownloadSummaryData -eq 'Allow' -or $DownloadSummaryData -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ExportData" mode="' + $DownloadSummaryData +'" />'}
   If ($ViewComments -eq 'Allow' -or $ViewComments -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ViewComments" mode="' + $ViewComments +'" />'}
   If ($AddComments -eq 'Allow' -or $AddComments -eq 'Deny'){$WorkbookCapabilities += '        <capability name="AddComment" mode="' + $AddComments +'" />'}
   If ($Filter -eq 'Allow' -or $Filter -eq 'Deny'){$WorkbookCapabilities += '        <capability name="Filter" mode="' + $Filter +'" />'}
   If ($DownloadFullData -eq 'Allow' -or $DownloadFullData -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ViewUnderlyingData" mode="' + $DownloadFullData +'" />'}
   If ($ShareCustomized -eq 'Allow' -or $ShareCustomized -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ShareView" mode="' + $ShareCustomized +'" />'}
   If ($WebEdit -eq 'Allow' -or $WebEdit -eq 'Deny'){$WorkbookCapabilities += '        <capability name="WebAuthoring" mode="' + $WebEdit +'" />'}
   If ($MoveWorkbook -eq 'Allow' -or $MoveWorkbook -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ChangeHierarchy" mode="' + $MoveWorkbook +'" />'}
   If ($DeleteWorkbook -eq 'Allow' -or $DeleteWorkbook -eq 'Deny'){$WorkbookCapabilities += '        <capability name="Delete" mode="' + $DeleteWorkbook +'" />'}
   If ($DownloadWorkbook -eq 'Allow' -or $DownloadWorkbook -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ExportXML" mode="' + $DownloadWorkbook +'" />'}
   If ($SetWorkbookPermissions -eq 'Allow' -or $SetWorkbookPermissions -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ChangePermissions" mode="' + $SetWorkbookPermissions +'" />'}

   $Workbook_request = '
        <tsRequest>
          <permissions>
            <granteeCapabilities>'     + $affectedObject + '
              <capabilities>' + $WorkbookCapabilities + '
              </capabilities>
            </granteeCapabilities>
          </permissions>
        </tsRequest>
        '

#   $Workbook_request

 if ($WorkbookCapabilities -ne '')
  {  
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/default-permissions/workbooks -Headers $headers -Method PUT -Body $Workbook_request
   #$response.tsResponse
  }


  # Check existing DataSource Permissions

  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/default-permissions/datasources -Headers $headers -Method Get

  foreach ($detail in $response.tsResponse.permissions.granteeCapabilities)
   { 
    if ($groupID -ne '' -and $groupID -eq $detail.group.id)
     {
       # Group is already permissioned against Project

      #"GroupID " + $GroupID
 
       # Check existing permissions
 
        ForEach ($permission in $detail.capabilities.capability)
           {
             if (($ViewDataSource  -ne '' -and $permission.name -eq 'Read') -or ($Connect -ne '' -and $permission.name -eq 'Connect') -or ($SaveDataSource  -ne '' -and $permission.name -eq 'Write') -or ($DownloadDataSource  -ne '' -and $permission.name -eq 'ExportXML') -or ($DeleteDataSource  -ne '' -and $permission.name -eq 'Delete') -or ($SetDataSourcePermissions  -ne '' -and $permission.name -eq 'ChangePermissions'))
                 {
                    $permission_name = $permission.name
                    $permission_mode = $permission.mode
                    #$permission_name, $permission_mode
                    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/default-permissions/datasources/groups/$groupID/$permission_name/$permission_mode -Headers $headers -Method Delete
                 }
           }
     } 

    if ($UserID -ne '' -and $UserID -eq $detail.user.id)
     {
       # User is already permissioned against Project

      #"UserID " + $UserID

        ForEach ($permission in $detail.capabilities.capability)
           {
             if (($ViewDataSource  -ne '' -and $permission.name -eq 'Read') -or ($Connect -ne '' -and $permission.name -eq 'Connect') -or ($SaveDataSource  -ne '' -and $permission.name -eq 'Write') -or ($DownloadDataSource  -ne '' -and $permission.name -eq 'ExportXML') -or ($DeleteDataSource  -ne '' -and $permission.name -eq 'Delete') -or ($SetDataSourcePermissions  -ne '' -and $permission.name -eq 'ChangePermissions'))
                 {
                    $permission_name = $permission.name
                    $permission_mode = $permission.mode
 #                   $permission_name, $permission_mode
                    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/default-permissions/datasources/users/$userID/$permission_name/$permission_mode -Headers $headers -Method Delete
                 }
            }
     } 
   }
   
   $DataSourceCapabilities = ""
   If ($ViewDataSource -eq 'Allow' -or $ViewDataSource -eq 'Deny'){$DataSourceCapabilities += '        <capability name="Read" mode="' + $ViewWorkbook +'" />'}
   If ($Connect  -eq 'Allow' -or $Connect  -eq 'Deny'){$DataSourceCapabilities += '        <capability name="Connect" mode="' + $Connect  +'" />'}
   If ($SaveDataSource  -eq 'Allow' -or $SaveDataSource -eq 'Deny'){$DataSourceCapabilities += '        <capability name="Write" mode="' + $SaveDataSource +'" />'}
   If ($DownloadDataSource  -eq 'Allow' -or $DownloadDataSource -eq 'Deny'){$DataSourceCapabilities += '        <capability name="ExportXML" mode="' + $DownloadDataSource +'" />'}
   If ($DeleteDataSource  -eq 'Allow' -or $DeleteDataSource -eq 'Deny'){$DataSourceCapabilities += '        <capability name="Delete" mode="' + $DeleteDataSource +'" />'}
   If ($SetDataSourcePermissions  -eq 'Allow' -or $SetDataSourcePermissions -eq 'Deny'){$DataSourceCapabilities += '        <capability name="ChangePermissions" mode="' + $SetDataSourcePermissions +'" />'}

   $DataSource_request = '
        <tsRequest>
          <permissions>
            <granteeCapabilities>'     + $affectedObject + '
              <capabilities>' + $DataSourceCapabilities + '
              </capabilities>
            </granteeCapabilities>
          </permissions>
        </tsRequest>
        '

#   $DataSource_request

 if ($DataSourceCapabilities -ne '')
  {  
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/projects/$ProjectID/default-permissions/datasources -Headers $headers -Method PUT -Body $DataSource_request
   #$response.tsResponse
  }

  "Project Permissions updated."
 }
 catch {"Unable to update Project Permissions."}
}

function TS-UpdateWorkbookPermissions
{
param(
  [string[]] $ProjectName = "",
  [string[]] $workbookName = "",
  [string[]] $GroupName = "",
  [string[]] $UserAccount = "",

  #Workbook Permissions
  [validateset('Allow', 'Deny', 'Blank')][string[]] $ViewWorkbook = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DownloadImagePDF = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DownloadSummaryData = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $ViewComments = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $AddComments = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $Filter = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DownloadFullData = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $ShareCustomized = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $WebEdit = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $SaveWorkbook = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $MoveWorkbook = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DeleteWorkbook = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DownloadWorkbook = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $SetWorkbookPermissions = ""

 )

try
 {

  $GroupID = ''
  $UserID = ''

  $WorkbookID= TS-GetWorkbookDetails -Name $workbookName -projectname $ProjectName
  if ($GroupName -ne '')
   {
    $GroupID = TS-GetGroupDetails -name $GroupName
    $affectedObject = '      <group id="' + $GroupID +'" />'
   }

  if ($UserAccount -ne '')
   {
    $UserID = TS-GetUserDetails -name $UserAccount
    $affectedObject = '      <user id="' + $UserID +'" />'
   }


  # Check existing Workbook Permissions

  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$WorkbookID/permissions -Headers $headers -Method Get

  foreach ($detail in $response.tsResponse.permissions.granteeCapabilities)
   { 
    if ($groupID -ne '' -and $groupID -eq $detail.group.id)
     {
       # Group is already permissioned against Project

      #"GroupID " + $GroupID
 
       # Check existing permissions
 
        ForEach ($permission in $detail.capabilities.capability)
           {
             if (($ViewWorkbook -ne '' -and $permission.name -eq 'Read') -or ($DownloadImagePDF -ne '' -and $permission.name -eq 'ExportImage') -or ($DownloadSummaryData -ne '' -and $permission.name -eq 'ExportData') -or ($ViewComments -ne '' -and $permission.name -eq 'ViewComments') -or ($AddComments -ne '' -and $permission.name -eq 'AddComment') -or ($Filter -ne '' -and $permission.name -eq 'Filter') -or ($DownloadFullData -ne '' -and $permission.name -eq 'ViewUnderlyingData') -or ($ShareCustomized -ne '' -and $permission.name -eq 'ShareView') -or ($WebEdit -ne '' -and $permission.name -eq 'WebAuthoring') -or ($SaveWorkbook -ne '' -and $permission.name -eq 'Write') -or ($MoveWorkbook -ne '' -and $permission.name -eq 'ChangeHierarchy') -or ($DeleteWorkbook -ne '' -and $permission.name -eq 'Delete') -or ($DownloadWorkbook -ne '' -and $permission.name -eq 'ExportXML') -or ($SetWorkbookPermissions -ne '' -and $permission.name -eq 'ChangePermissions'))
                 {
                  $permission_name
                    $GroupID
                    $permission_name = $permission.name
                    $permission_mode = $permission.mode
                    $permission_name, $permission_mode
                    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$WorkbookID/permissions/groups/$groupID/$permission_name/$permission_mode -Headers $headers -Method Delete
                 }
           }
     } 


    if ($UserID -ne '' -and $UserID -eq $detail.user.id)
     {
       # User is already permissioned against Project

      #"UserID " + $UserID

        ForEach ($permission in $detail.capabilities.capability)
           {
             if (($ViewWorkbook -ne '' -and $permission.name -eq 'Read') -or ($DownloadImagePDF -ne '' -and $permission.name -eq 'ExportImage') -or ($DownloadSummaryData -ne '' -and $permission.name -eq 'ExportData') -or ($ViewComments -ne '' -and $permission.name -eq 'ViewComments') -or ($AddComments -ne '' -and $permission.name -eq 'AddComment') -or ($Filter -ne '' -and $permission.name -eq 'Filter') -or ($DownloadFullData -ne '' -and $permission.name -eq 'ViewUnderlyingData') -or ($ShareCustomized -ne '' -and $permission.name -eq 'ShareView') -or ($WebEdit -ne '' -and $permission.name -eq 'WebAuthoring') -or ($SaveWorkbook -ne '' -and $permission.name -eq 'Write') -or ($MoveWorkbook -ne '' -and $permission.name -eq 'ChangeHierarchy') -or ($DeleteWorkbook -ne '' -and $permission.name -eq 'Delete') -or ($DownloadWorkbook -ne '' -and $permission.name -eq 'ExportXML') -or ($SetWorkbookPermissions -ne '' -and $permission.name -eq 'ChangePermissions'))
                 {
                    $permission_name = $permission.name
                    $permission_mode = $permission.mode
                    #$permission_name, $permission_mode
                    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$WorkbookID/permissions/users/$userID/$permission_name/$permission_mode -Headers $headers -Method Delete
                 }
            }
     } 
   }
   
   $WorkbookCapabilities = ""
   If ($ViewWorkbook -eq 'Allow' -or $ViewWorkbook -eq 'Deny'){$WorkbookCapabilities += '        <capability name="Read" mode="' + $ViewWorkbook +'" />'}
   If ($SaveWorkbook -eq 'Allow' -or $SaveWorkbook -eq 'Deny'){$WorkbookCapabilities += '        <capability name="Write" mode="' + $SaveWorkbook +'" />'}
   If ($DownloadImagePDF -eq 'Allow' -or $DownloadImagePDF -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ExportImage" mode="' + $DownloadImagePDF +'" />'}
   If ($DownloadSummaryData -eq 'Allow' -or $DownloadSummaryData -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ExportData" mode="' + $DownloadSummaryData +'" />'}
   If ($ViewComments -eq 'Allow' -or $ViewComments -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ViewComments" mode="' + $ViewComments +'" />'}
   If ($AddComments -eq 'Allow' -or $AddComments -eq 'Deny'){$WorkbookCapabilities += '        <capability name="AddComment" mode="' + $AddComments +'" />'}
   If ($Filter -eq 'Allow' -or $Filter -eq 'Deny'){$WorkbookCapabilities += '        <capability name="Filter" mode="' + $Filter +'" />'}
   If ($DownloadFullData -eq 'Allow' -or $DownloadFullData -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ViewUnderlyingData" mode="' + $DownloadFullData +'" />'}
   If ($ShareCustomized -eq 'Allow' -or $ShareCustomized -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ShareView" mode="' + $ShareCustomized +'" />'}
   If ($WebEdit -eq 'Allow' -or $WebEdit -eq 'Deny'){$WorkbookCapabilities += '        <capability name="WebAuthoring" mode="' + $WebEdit +'" />'}
   If ($MoveWorkbook -eq 'Allow' -or $MoveWorkbook -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ChangeHierarchy" mode="' + $MoveWorkbook +'" />'}
   If ($DeleteWorkbook -eq 'Allow' -or $DeleteWorkbook -eq 'Deny'){$WorkbookCapabilities += '        <capability name="Delete" mode="' + $DeleteWorkbook +'" />'}
   If ($DownloadWorkbook -eq 'Allow' -or $DownloadWorkbook -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ExportXML" mode="' + $DownloadWorkbook +'" />'}
   If ($SetWorkbookPermissions -eq 'Allow' -or $SetWorkbookPermissions -eq 'Deny'){$WorkbookCapabilities += '        <capability name="ChangePermissions" mode="' + $SetWorkbookPermissions +'" />'}

   $Workbook_request = '
        <tsRequest>
          <permissions>
            <granteeCapabilities>'     + $affectedObject + '
              <capabilities>' + $WorkbookCapabilities + '
              </capabilities>
            </granteeCapabilities>
          </permissions>
        </tsRequest>
        '

#   $Workbook_request

 if ($WorkbookCapabilities -ne '')
  {  
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$WorkbookID/permissions -Headers $headers -Method PUT -Body $Workbook_request
   #$response.tsResponse
  }


  "Workbook Permissions updated."
 }
 catch {"Unable to update Workbook Permissions."}
}



function TS-UpdateDataSourcePermissions
{
param(
  [string[]] $ProjectName = "",
  [string[]] $DataSourceName = "",
  [string[]] $GroupName = "",
  [string[]] $UserAccount = "",


  #DataSource Permissions
  [validateset('Allow', 'Deny', 'Blank')][string[]] $ViewDataSource = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $Connect = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $SaveDataSource = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DownloadDataSource = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $DeleteDataSource = "",
  [validateset('Allow', 'Deny', 'Blank')][string[]] $SetDataSourcePermissions = ""

 )

try
 {

  $GroupID = ''
  $UserID = ''

  $DataSourceID= TS-GetDataSourceDetails -Name $DataSourcekName -projectname $ProjectName
  if ($GroupName -ne '')
   {
    $GroupID = TS-GetGroupDetails -name $GroupName
    $affectedObject = '      <group id="' + $GroupID +'" />'
   }

  if ($UserAccount -ne '')
   {
    $UserID = TS-GetUserDetails -name $UserAccount
    $affectedObject = '      <user id="' + $UserID +'" />'
   }


  # Check existing DataSource Permissions

  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DataSourceID/permissions -Headers $headers -Method Get

  foreach ($detail in $response.tsResponse.permissions.granteeCapabilities)
   { 
    if ($groupID -ne '' -and $groupID -eq $detail.group.id)
     {
       # Group is already permissioned against DataSource

      #"GroupID " + $GroupID
 
       # Check existing permissions
 
        ForEach ($permission in $detail.capabilities.capability)
           {
             if (($ViewDataSource  -ne '' -and $permission.name -eq 'Read') -or ($Connect -ne '' -and $permission.name -eq 'Connect') -or ($SaveDataSource  -ne '' -and $permission.name -eq 'Write') -or ($DownloadDataSource  -ne '' -and $permission.name -eq 'ExportXML') -or ($DeleteDataSource  -ne '' -and $permission.name -eq 'Delete') -or ($SetDataSourcePermissions  -ne '' -and $permission.name -eq 'ChangePermissions'))
                 {
                  $permission_name
                    $GroupID
                    $permission_name = $permission.name
                    $permission_mode = $permission.mode
                    $permission_name, $permission_mode
                    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DataSourceID/permissions/groups/$groupID/$permission_name/$permission_mode -Headers $headers -Method Delete
                 }
           }
     } 


    if ($UserID -ne '' -and $UserID -eq $detail.user.id)
     {
       # User is already permissioned against DataSource

      #"UserID " + $UserID

        ForEach ($permission in $detail.capabilities.capability)
           {
             if (($ViewDataSource  -ne '' -and $permission.name -eq 'Read') -or ($Connect -ne '' -and $permission.name -eq 'Connect') -or ($SaveDataSource  -ne '' -and $permission.name -eq 'Write') -or ($DownloadDataSource  -ne '' -and $permission.name -eq 'ExportXML') -or ($DeleteDataSource  -ne '' -and $permission.name -eq 'Delete') -or ($SetDataSourcePermissions  -ne '' -and $permission.name -eq 'ChangePermissions'))
                 {
                    $permission_name = $permission.name
                    $permission_mode = $permission.mode
                    #$permission_name, $permission_mode
                    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DataSourceID/permissions/users/$userID/$permission_name/$permission_mode -Headers $headers -Method Delete
                 }
            }
     } 
   }
   
   $DataSourceCapabilities = ""
   If ($ViewDataSource -eq 'Allow' -or $ViewDataSource -eq 'Deny'){$DataSourceCapabilities += '        <capability name="Read" mode="' + $ViewDataSource +'" />'}
   If ($Connect  -eq 'Allow' -or $Connect  -eq 'Deny'){$DataSourceCapabilities += '        <capability name="Connect" mode="' + $Connect  +'" />'}
   If ($SaveDataSource  -eq 'Allow' -or $SaveDataSource -eq 'Deny'){$DataSourceCapabilities += '        <capability name="Write" mode="' + $SaveDataSource +'" />'}
   If ($DownloadDataSource  -eq 'Allow' -or $DownloadDataSource -eq 'Deny'){$DataSourceCapabilities += '        <capability name="ExportXML" mode="' + $DownloadDataSource +'" />'}
   If ($DeleteDataSource  -eq 'Allow' -or $DeleteDataSource -eq 'Deny'){$DataSourceCapabilities += '        <capability name="Delete" mode="' + $DeleteDataSource +'" />'}
   If ($SetDataSourcePermissions  -eq 'Allow' -or $SetDataSourcePermissions -eq 'Deny'){$DataSourceCapabilities += '        <capability name="ChangePermissions" mode="' + $SetDataSourcePermissions +'" />'}

   $DataSource_request = '
        <tsRequest>
          <permissions>
            <granteeCapabilities>'     + $affectedObject + '
              <capabilities>' + $DataSourceCapabilities + '
              </capabilities>
            </granteeCapabilities>
          </permissions>
        </tsRequest>
        '

 if ($DataSourceCapabilities -ne '')
  {  
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DataSourceID/permissions -Headers $headers -Method PUT -Body $DataSource_request
   #$response.tsResponse
  }


  "DataSource Permissions updated."
 }
 catch {"Unable to update DataSource Permissions."}
}



###### Jobs, Tasks, and Schedules


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
 [string[]] $ScheduleName = "",
 [string[]] $newScheduleName ="",
 [string[]] $newPriority ="",
 [validateset('Active','Suspended')][string[]] $newState = "",
 [validateset('Parallel', 'Serial')][string[]] $newExecutionOrder = "",
 [validateset('Hourly', 'Daily', 'Weekly', 'Monthly')][string[]] $newFrequency ="",
 [string[]] $newStartTime ="00:00",
 [string[]] $newEndTime ="00:00",
 [string[]] $newInterval = ""
 )

try
 {
  $ID = TS-GetScheduleDetails -name $ScheduleName
  $ID


  $updated_schedule = ""
  $updated_frequency = ""
  $updated_intervals = ""

  if ($NewScheduleName -ne '') {$updated_schedule += ' name="'+ $newScheduleName+'"'}
  if ($newPriority -ne '') {$updated_schedule += ' priority="'+ $newPriority+'"'}
  if ($newExecutionOrder -ne '') {$updated_schedule += ' executionOrder="'+ $newExecutionOrder+'"'}
  if ($newState -ne '') {$updated_schedule += ' state="'+ $newState+'"'}
  if ($newFrequency -ne '') 
    {
     
     if ($newFrequency -eq 'Hourly')
      {     
        If ($newInterval -eq '15' -or $newInterval -eq '30')
         {
           $interval_text = '<interval minutes="'+$newInterval +'" />'
         }
        else
         {
           $interval_text = '<interval hours="'+$newInterval +'" />'
         }
        $updated_schedule += ' frequency="'+ $newFrequency+'"'
        $updated_frequency = '<frequencyDetails start="'+ $newStartTime+':00" end="' +$newEndTime +':00">
         <intervals>
         ' + $interval_text + '
          </intervals>
      </frequencyDetails>'
      }
      elseif
       ($newFrequency -eq 'Daily')
      {     
        $updated_schedule += ' frequency="'+ $newFrequency+'"'
        $updated_frequency = '<frequencyDetails start="'+ $newStartTime+':00">
         <intervals>
          <interval hours="1" />
        </intervals>
      </frequencyDetails>'
      }
      elseif
       ($newFrequency -eq 'Weekly')
      {     
        $IntervalsArrary = $newInterval.Split(",")
        Foreach ($Interval in $IntervalsArrary) {$interval_text += '<interval weekDay ="'+ $Interval +'" />'}


        $updated_schedule += ' frequency="'+ $newFrequency+'"'
        $updated_frequency = '<frequencyDetails start="'+ $newStartTime+':00">
         <intervals>
          ' + $interval_text + '
        </intervals>
      </frequencyDetails>'
      }
      elseif
       ($newFrequency -eq 'Monthly')
      {     
        $updated_schedule += ' frequency="'+ $newFrequency+'"'
        $updated_frequency = '<frequencyDetails start="'+ $newStartTime+':00">
         <intervals>
          <interval monthDay="'+$newInterval +'" />
        </intervals>
      </frequencyDetails>'
      }
    }

   $Schedule_request = "
        <tsRequest>
          <schedule 
          " + $updated_schedule +">" + $updated_frequency + $updated_intervals + "
          </schedule>
        </tsRequest>
        "

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/schedules/$ID -Headers $headers -Method PUT -Body $Schedule_request
   $response.tsresponse.schedule
   
 }
 catch{"Unable to Update Schedule."}
}

function TS-DeleteSchedule
{
param(
 [string[]] $ScheduleName = ""
 )

try
 {
  $ID = TS-GetScheduleDetails -name $ScheduleName
  $ID
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/schedules/$ID -Headers $headers -Method DELETE
 }
 catch{"Unable to Delete Schedule."}
}




function TS-CreateSchedule
{
param(
 [string[]] $ScheduleName = "",
 [string[]] $Priority ="",
 [validateset('Extract','Subscription')][string[]] $Type = "",
 [validateset('Active','Suspended')][string[]] $State = "",
 [validateset('Parallel', 'Serial')][string[]] $ExecutionOrder = "Parallel",
 [validateset('Hourly', 'Daily', 'Weekly', 'Monthly')][string[]] $Frequency ="",
 [string[]] $StartTime ="00:00",
 [string[]] $EndTime ="00:00",
 [string[]] $Interval = ""
 )

try
 {
  $updated_schedule = ""
  $updated_frequency = ""
  $updated_intervals = ""

  if ($ScheduleName -ne '') {$updated_schedule += ' name="'+ $ScheduleName+'"'}
  if ($Priority -ne '') {$updated_schedule += ' priority="'+ $Priority+'"'}
  if ($ExecutionOrder -ne '') {$updated_schedule += ' executionOrder="'+ $ExecutionOrder+'"'}
  if ($State -ne '') {$updated_schedule += ' state="'+ $State+'"'}
  if ($Type -ne '') {$updated_schedule += ' type="'+ $Type+'"'}

  if ($Frequency -ne '') 
    {
     
     if ($Frequency -eq 'Hourly')
      {     
        If ($Interval -eq '15' -or $Interval -eq '30')
         {
           $interval_text = '<interval minutes="'+$Interval +'" />'
         }
        else
         {
           $interval_text = '<interval hours="'+$Interval +'" />'
         }
        $updated_schedule += ' frequency="'+ $Frequency+'"'
        $updated_frequency = '<frequencyDetails start="'+ $StartTime+':00" end="' +$EndTime +':00">
         <intervals>
         ' + $interval_text + '
          </intervals>
      </frequencyDetails>'
      }
      elseif
       ($Frequency -eq 'Daily')
      {     
        $updated_schedule += ' frequency="'+ $Frequency+'"'
        $updated_frequency = '<frequencyDetails start="'+ $StartTime+':00">
         <intervals>
          <interval hours="1" />
        </intervals>
      </frequencyDetails>'
      }
      elseif
       ($Frequency -eq 'Weekly')
      {     
        $IntervalsArrary = $Interval.Split(",")
        Foreach ($Interval in $IntervalsArrary) {$interval_text += '<interval weekDay ="'+ $Interval +'" />'}


        $updated_schedule += ' frequency="'+ $Frequency+'"'
        $updated_frequency = '<frequencyDetails start="'+ $StartTime+':00">
         <intervals>
          ' + $interval_text + '
        </intervals>
      </frequencyDetails>'
      }
      elseif
       ($Frequency -eq 'Monthly')
      {     
        $updated_schedule += ' frequency="'+ $Frequency+'"'
        $updated_frequency = '<frequencyDetails start="'+ $StartTime+':00">
         <intervals>
          <interval monthDay="'+$Interval +'" />
        </intervals>
      </frequencyDetails>'
      }
    }

   $Schedule_request = "
        <tsRequest>
          <schedule 
          " + $updated_schedule +">" + $updated_frequency + $updated_intervals + "
          </schedule>
        </tsRequest>
        "

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/schedules -Headers $headers -Method POST -Body $Schedule_request
   $response.tsresponse.schedule
   
 }
 catch{"Unable to Create Schedule."}
}


function TS-QueryExtractRefreshTasks
{
 param(
 [string[]] $ScheduleName = ""
 )

 try
 {
  $ID = TS-GetScheduleDetails -name $ScheduleName
  $ID
  $PageSize = 100
  $PageNumber = 1
  $done = 'FALSE'

  While ($done -eq 'FALSE')
   {
    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/schedules/$ID/extracts?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
    $totalAvailable = $response.tsResponse.pagination.totalAvailable

    If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

    $PageNumber += 1

    ForEach ($detail in $response.tsResponse.extracts.extract)
     { 
       $datasource_name = TS-GetDataSourceDetails -ID $detail.datasource.id
       $workbook_name = TS-GetWorkbookDetails -ID $detail.workbook.id
       $Task = [pscustomobject]@{Priority=$detail.priority; Type=$detail.Type; Workbook=$workbook_name; Datasource=$datasource_name; ID=$detail.ID}
       $Task
     }
   }
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


function TS-GetExtractRefreshTasks
{
     $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/tasks/extractRefreshes -Headers $headers -Method Get
     $response.tsResponse.tasks.task.extractRefresh
}


function TS-RunExtractRefreshTask
{
 param(
[string[]] $ScheduleName ="",
[string[]] $WorkbookName ="",
[string[]] $DataSourceName ="",
[string[]] $ProjectName =""
  )
     $TaskID = TS-GetExtractRefreshTaskID -ScheduleName $ScheduleName -WorkbookName $WorkbookName -DataSourceName $DataSourceName -ProjectName $ProjectName
     $TaskID   
     $body = "<tsRequest></tsRequest>"
     $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/tasks/extractRefreshes/$TaskID/runNow -Headers $headers -Method POST -Body $body -ContentType "text/xml"
     $response.tsresponse.job
}


function TS-GetExtractRefreshTaskID
{
param(
[string[]] $ScheduleName ="",
[string[]] $WorkbookName ="",
[string[]] $DataSourceName ="",
[string[]] $ProjectName =""

)
  if ($DataSourceName -ne '') {$DataSourceID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName}
  if ($WorkbookName -ne ''){$workbookID = TS-GetWorkbookDetails -Name $WorkBookName -ProjectName $ProjectName}

  $Tasks = TS-GetExtractRefreshTasks

  ForEach ($Task in $Tasks)
    {
      If ($ScheduleName -eq $Task.Schedule.name -and ($DataSourceID -eq $Task.datasource.id -or $workbookID -eq $task.Workbook.id))
       {
         return $Task.id
       }
    }
}


function TS-DownloadWorkbook
{
param
 (
 [string[]] $WorkBookName ="",
 [string[]] $ProjectName ="",
 [string[]] $FileName ="",
 [validateset('True', 'False')][string[]] $IncludeExtract =""

 )
 try
  {
   $workbookID = TS-GetWorkbookDetails -Name $WorkBookName -ProjectName $ProjectName
   $suffix = ""
   if ($IncludeExtract -ne ''){$suffix = '?includeExtract='+$IncludeExtract}

   $url = $protocol.trim() + "://" + $server +"/api/" + $api_ver+ "/sites/" + $siteID + "/workbooks/" + $WorkbookID + "/content" + $suffix

   $wc = New-Object System.Net.WebClient
   $wc.Headers.Add('X-Tableau-Auth',$headers.Values[0])
   $wc.DownloadFile($url, $FileName)
   "Workbook " + $WorkbookName + " download successfully to " + $FileName

  }
 catch{"Unable to download workbook. " + $WorkBookName}
}

function TS-DownloadWorkbookRevision
{
param
 (
 [string[]] $WorkBookName ="",
 [string[]] $ProjectName ="",
 [string[]] $FileName ="",
 [string[]] $RevisionNumber,
 [validateset('True', 'False')][string[]] $IncludeExtract =""

 )
 try
 {
   $workbookID = TS-GetWorkbookDetails -Name $WorkBookName -ProjectName $ProjectName
   $suffix = ""
   if ($IncludeExtract -ne ''){$suffix = '?includeExtract='+$IncludeExtract}

   $url = $protocol.trim() + "://" + $server +"/api/" + $api_ver+ "/sites/" + $siteID + "/workbooks/" + $WorkbookID + "/revisions/" + $RevisionNumber + "/content" + $suffix
   $wc = New-Object System.Net.WebClient
   $wc.Headers.Add('X-Tableau-Auth',$headers.Values[0])
   $wc.DownloadFile($url, $FileName)
   "Workbook " + $WorkbookName + " download successfully to " + $FileName

 }
 catch{"Unable to download workbook revision. " + $WorkBookName}
}



function TS-DownloadDataSource
{
param
 (
 [string[]] $DatasourceName ="",
 [string[]] $ProjectName ="",
 [string[]] $FileName ="",
 [validateset('True', 'False')][string[]] $IncludeExtract =""
 )
 try
  {
   $DataSourceID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName
   $suffix = ""
   if ($IncludeExtract -ne ''){$suffix = '?includeExtract='+$IncludeExtract}
   $url = $protocol.trim() + "://" + $server +"/api/" + $api_ver+ "/sites/" + $siteID + "/DataSources/" + $DataSourceID + "/content"+ $suffix

   $wc = New-Object System.Net.WebClient
   $wc.Headers.Add('X-Tableau-Auth',$headers.Values[0])
   $wc.DownloadFile($url, $FileName)
   "Data Source " + $DatasourceName + " download successfully to " + $FileName
  }
 catch{"Unable to download datasource. " + $DatasourceName }
}

function TS-DownloadDataSourceRevision
{
param
 (
 [string[]] $DatasourceName ="",
 [string[]] $ProjectName ="",
 [string[]] $FileName ="",
 [string[]] $RevisionNumber,
 [validateset('True', 'False')][string[]] $IncludeExtract =""
 )
 try
  {
   $DataSourceID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName
   $suffix = ""
   if ($IncludeExtract -ne ''){$suffix = '?includeExtract='+$IncludeExtract}
   $url = $protocol.trim() + "://" + $server +"/api/" + $api_ver+ "/sites/" + $siteID + "/DataSources/" + $DataSourceID + "/revisions/" + $RevisionNumber + "/content"+ $suffix

   $wc = New-Object System.Net.WebClient
   $wc.Headers.Add('X-Tableau-Auth',$headers.Values[0])
   $wc.DownloadFile($url, $FileName)
   "Data Source " + $DatasourceName + " download successfully to " + $FileName
  }
 catch{"Unable to download datasource revision. " + $DatasourceName }
}





function TS-QueryViewsForSite
{
 # try
 # {
   $PageSize = 100
   $PageNumber = 1
   $done = 'FALSE'

   While ($done -eq 'FALSE')
    {
     $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/views?includeUsageStatistics=true`&pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get

     $totalAvailable = $response.tsResponse.pagination.totalAvailable

     If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

     $PageNumber += 1
     ForEach ($detail in $response.tsResponse.Views.view)
      { 
       $WorkbookName = TS-GetWorkbookDetails -ID $detail.workbook.id
       $Owner = TS-GetUserDetails -ID $detail.owner.id
       $Views = [pscustomobject]@{ViewName=$detail.name; ViewCount=$detail.usage.TotalViewCount; Owner=$Owner; WorkbookName = $workbookName; ContentURL=$detail.contentURL}
       $views
      }
    }
 # }
 # catch {"Unable to Query Views"}
}

function TS-QueryViewsForWorkbook
{
   param(
   [string[]] $WorkbookName = "",
   [string[]] $ProjectName = ""
   )
 try
  {
   $WorkbookID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$WorkbookID/views?includeUsageStatistics=true -Headers $headers -Method Get

   ForEach ($detail in $response.tsResponse.Views.view)
    {
     $Views = [pscustomobject]@{ViewName=$detail.name; ViewCount=$detail.usage.TotalViewCount; ContentURL=$detail.contentURL}
     $views
    }
  }
  catch{"Unable to Query Views for Workbook: " + $WorkbookName}
}
 
function TS-QueryWorkbooksForUser
{
  param
  (
   [string[]] $UserAccount ="",
   [validateset('True', 'False')][string[]][string[]] $IsOwner ="False"
  )
 try
 {

  if (-not($UserAccount)){$UserAccount = $userName}

  $userId = TS-GetUserDetails -Name $UserAccount
 
  $PageSize = 100
  $PageNumber = 1
  $done = 'FALSE'

  While ($done -eq 'FALSE')
   { 
    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/users/$userId/workbooks?ownedBy=$IsOwner`&pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
    $totalAvailable = $response.tsResponse.pagination.totalAvailable

    If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

    $PageNumber += 1

    ForEach ($detail in $response.tsResponse.workbooks.workbook)
     {
      $taglist =''
      $ProjectName = TS-GetProjectDetails -ProjectID $detail.Project.ID
      $Owner = TS-GetUserDetails -ID $detail.Owner.ID

      ForEach ($tag in $detail.tags.tag.label){$taglist += $tag + " "}

      $Workbooks = [pscustomobject]@{WorkbookName=$detail.name; ShowTabs=$detail.ShowTabs; ContentURL=$detail.contentURL; Size=$detail.size; CreatedAt=$detail.CreatedAt; UpdatedAt=$detail.UpdatedAt; Project=$ProjectName; Owner=$Owner; Tags=$taglist}
      $workbooks
     }
   }
 }
 catch {"Unable to Query Workbooks for User"}
}


function TS-QueryWorkbooksForSite
{
  try
 {
  $PageSize = 100
  $PageNumber = 1
  $done = 'FALSE'



  While ($done -eq 'FALSE')
   { 
    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get
    $totalAvailable = $response.tsResponse.pagination.totalAvailable

    If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

    $PageNumber += 1

    ForEach ($detail in $response.tsResponse.workbooks.workbook)
     {
      $taglist =''
      $ProjectName = TS-GetProjectDetails -ProjectID $detail.Project.ID
      $Owner = TS-GetUserDetails -ID $detail.Owner.ID

      ForEach ($tag in $detail.tags.tag.label){$taglist += $tag + " "}

      $Workbooks = [pscustomobject]@{WorkbookName=$detail.name; ShowTabs=$detail.ShowTabs; ContentURL=$detail.contentURL; Size=$detail.size; CreatedAt=$detail.CreatedAt; UpdatedAt=$detail.UpdatedAt; Project=$ProjectName; Owner=$Owner; Tags=$taglist}
      $workbooks
     }
   }
 }
 catch {"Unable to Query Workbooks for Site"}
}

function TS-GetWorkbookDetails
{

  param(
 [string[]] $Name = "",
 [string[]] $ID = "",
 [string[]] $ProjectName = ""
 )

 $userID = TS-GetUserDetails -name $username

 $PageSize = 100
 $PageNumber = 1
 $done = 'FALSE'

 While ($done -eq 'FALSE')
 {

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/users/$userId/workbooks?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get

   $totalAvailable = $response.tsResponse.pagination.totalAvailable

   If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

   $PageNumber += 1

   foreach ($detail in $response.tsResponse.workbooks.workbook)
    {
     if ($Name -eq $detail.name -and $ProjectName -eq $detail.project.name){Return $detail.ID}
     if ($ID -eq $detail.ID){Return $detail.Name}
    }
 }
}


function TS-QueryWorkbook
{
 param(
 [string[]] $WorkbookName,
 [string[]] $ProjectName
 )
 try
  {
   $workbookID = TS-GetWorkbookDetails -Name $WorkBookName -ProjectName $ProjectName
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$workbookID -Headers $headers -Method Get
  
   ForEach ($detail in $response.tsResponse.workbook)
     {
      $taglist =''
      $ProjectName = TS-GetProjectDetails -ProjectID $detail.Project.ID
      $Owner = TS-GetUserDetails -ID $detail.Owner.ID

      ForEach ($tag in $detail.tags.tag.label){$taglist += $tag + " "}
      $Workbook = [pscustomobject]@{WorkbookName = $WorkbookName;ShowTabs=$detail.ShowTabs; ContentURL=$detail.contentURL; Size=$detail.size; CreatedAt=$detail.CreatedAt; UpdatedAt=$detail.UpdatedAt; Project=$ProjectName; Owner=$Owner; Tags=$detail.tags.tag.label; Views = $detail.Views.View.Count; ViewList =$detail.Views.View.name}
     }
      $workbook

  }
  catch{"Unable to Query Workbook: " + $WorkbookName}
}

function TS-QueryWorkbookConnections
{
param(
[string[]] $WorkbookName,
[string[]] $ProjectName
)

try
 {
 $workbookID = TS-GetWorkbookDetails -Name $WorkBookName -ProjectName $ProjectName
 $WorkbookID
 $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$workbookID/connections -Headers $headers -Method Get

  ForEach ($detail in $response.tsResponse.Connections.connection)
   {
    $Connections = [pscustomobject]@{Id=$detail.id; Type=$detail.type; ServerAddress=$detail.serverAddress; ServerPort=$detail.serverPort;UserName=$detail.userName;DataSourceID=$detail.datasource.Id;DataSourceName=$detail.datasource.name}
    $Connections`
   }
 }
 catch {"Unable to Query Workbook connections."}
}


function TS-UpdateWorkbook
{
 param(
  [string[]] $WorkbookName = "",
  [string[]] $ProjectName = "",
  [string[]] $NewProjectName = "",
  [string[]] $NewOwnerAccount = "",
  [validateset('True', 'False')][string[]] $ShowTabs = ""
 )
 try
 {
  $workbookID = TS-GetWorkbookDetails -Name $WorkBookName -ProjectName $ProjectName
  $userID = TS-GetUserDetails -name $NewOwnerAccount
  $ProjectID = TS-GetProjectDetails -ProjectName $NewProjectName

  $body = ""
  $tabsbody = ""

  if ($ShowTabs -ne '') {$tabsbody += ' showTabs ="'+ $ShowTabs +'"'}
  if ($NewProjectName -ne '') {$body += '<project id ="'+ $ProjectID +'" />'}
  if ($NewOwnerAccount -ne '') {$body += '<owner id ="'+ $userID +'"/>'}

  $body = ('<tsRequest><workbook' +$tabsbody + '>' + $body +  ' </workbook></tsRequest>')

  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$workbookID -Headers $headers -Method Put -Body $body
  $response.tsResponse.Workbook
 }
 catch{"Problem updating Workbook: " + $WorkbookName }
}

function TS-DeleteWorkbook
{
 param(
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = ""
 )
 try
  {
   $Workbook_ID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$Workbook_ID -Headers $headers -Method DELETE 
   $response.tsresponse
  }
  catch{"Unable to Delete Workbook: " + $WorkbookName}
}

function TS-AddTagsToWorkbook
{
 param(
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "",
 [string[]] $Tags = ""
 )
 try
 {
  $workbookID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName
  $workbookID

  $body = ''
  $TagsArrary = $Tags.Split(",")
  Foreach ($Tag in $TagsArrary) {$body += '<tag label ="'+ $Tag +'" />'}
 
  $body = ('<tsRequest><tags>'  + $body +  ' </tags></tsRequest>')

  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$workbookID/tags -Headers $headers -Method Put -Body $body
  $response.tsResponse.tags.tag
 }
 catch {"Problem adding tags to Workbook:" + $WorkbookName}
}

function TS-DeleteTagFromWorkbook
{
 param(
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "",
 [string[]] $Tag = ""
 )
 try
 {
  $workbookID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName
  $workbookID
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$workbookID/tags/$Tag -Headers $headers -Method Delete
 }
 catch {"Problem remove tag from Workbook:" + $WorkbookName}
}

function TS-GetViewDetails
{

  param(
 [string[]] $ViewName = "",
 [string[]] $WorkbookName = "",
 [string[]] $ID = "",
 [string[]] $ProjectName = ""
 )

 $userID = TS-GetUserDetails -name $username
 $WorkbookID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName
 
 $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$workbookID/Views -Headers $headers -Method Get

 foreach ($detail in $response.tsResponse.Views.View)
  {
   if ($ViewName -eq $detail.name){Return $detail.ID}
   if ($ID -eq $detail.ID){Return $detail.Name}
  }
}


####### Favourites

function TS-AddWorkbookToFavorites
{
 param(

 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "",
 [string[]] $UserAccount = "",
 [string[]] $Label = ""
 )
 try
 {
   $workbookID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName
   $userID = TS-GetUserDetails -name $UserAccount

   $body = '<tsRequest>
   <favorite label="' +$label +'">
    <workbook id="' + $workbookID +'" />
   </favorite>
   </tsRequest>'
 
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/favorites/$userID -Headers $headers -Method Put -Body $body
   $response.tsResponse.favorites.favorite
  }
  catch {"Unable To Add Workbook to Favorites."}
}

function TS-AddViewToFavorites
{
 param(
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "",
 [string[]] $ViewName = "",
 [string[]] $UserAccount = "",
 [string[]] $Label = ""
 )

 try
  {
   $ViewID = TS-GetViewDetails -WorkbookName $WorkbookName -ProjectName $ProjectName -ViewName $ViewName
   $userID = TS-GetUserDetails -name $UserAccount

   $body = '<tsRequest>
   <favorite label="' +$label +'">
    <view id="' + $viewID +'" />
   </favorite>
   </tsRequest>'
 
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/favorites/$userID -Headers $headers -Method Put -Body $body
   $response.tsResponse.favorites.favorite
  }
  catch {"Unable to Add View to Favorites."}
}

function TS-DeleteWorkbookFromFavorites
{
 param(
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "",
 [string[]] $UserAccount = ""
 )

 try
  {

   $workbookID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName
   $userID = TS-GetUserDetails -name $UserAccount

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/favorites/$userID/workbooks/$WorkbookID -Headers $headers -Method Delete
   $response.tsResponse.favorites.favorite
  }
  catch {"Unable to Delete Workbook From Favorites."}
}

function TS-DeleteViewFromFavorites
{
 param(
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "",
 [string[]] $ViewName = "",
 [string[]] $UserAccount = ""
 )

 try
  {
   $viewID = TS-GetViewDetails -WorkbookName $WorkbookName -ProjectName $ProjectName -ViewName $ViewName
   $userID = TS-GetUserDetails -name $UserAccount
   
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/favorites/$userID/views/$ViewID -Headers $headers -Method Delete
   $response.tsResponse.favorites.favorite
  }
  catch {"Unable to Delete View From Favorites."}
}

Function TS-QueryWorkbookPreviewImage
{
 param(
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "",
 [string[]] $FileName = ""
 )
 try
  {
   $workbookID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName

   $url = $protocol.trim() + "://" + $server +"/api/" + $api_ver+ "/sites/" + $siteID + "/workbooks/" + $workbookID + "/previewImage"
   $wc = New-Object System.Net.WebClient
   $wc.Headers.Add('X-Tableau-Auth',$headers.Values[0])
   $wc.DownloadFile($url, $FileName)
   "File Downloaded: " + $FileName

  }
  catch {"Unable to Query Workbook Preview Image."}
}

Function TS-QueryViewPreviewImage
{
param(
 [string[]] $ViewName = "",
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "",
 [string[]] $FileName = ""
 )
 try
  {
   $workbookID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName
   $viewID = TS-GetViewDetails -WorkbookName $WorkbookName -ProjectName $ProjectName -ViewName $ViewName

   $url = $protocol.trim() + "://" + $server +"/api/" + $api_ver+ "/sites/" + $siteID + "/workbooks/" + $workbookID + "/views/" + $viewID + "/previewImage"
   
   $wc = New-Object System.Net.WebClient
   $wc.Headers.Add('X-Tableau-Auth',$headers.Values[0])
   $wc.DownloadFile($url, $FileName)
   "File Downloaded: " + $FileName
  }
  catch {"Unable to Query View Preview Image."}
}



Function TS-QueryViewImage
{
 param(
 [string[]] $ViewName = "",
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "",
 [string[]] $FileName = "None",
 [validateset('Normal', 'High')][string[]] $ImageQuality = "Normal"
 )
 try
  {
   $suffix = ""
   $viewID = TS-GetViewDetails -WorkbookName $WorkbookName -ProjectName $ProjectName -ViewName $ViewName
   If ($ImageQuality = "High")
    {$suffix = "?resolution=high"}

   $url = $protocol.trim() + "://" + $server +"/api/" + $api_ver+ "/sites/" + $siteID + "/views/" + $viewID + "/image" + $suffix
   
   if ($FileName -eq "None")
     { 
      $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
     }
    else
     {
      $wc = New-Object System.Net.WebClient
      $wc.Headers.Add('X-Tableau-Auth',$headers.Values[0])
      $wc.DownloadFile($url, $FileName)
      "File Downloaded: " + $FileName
     }
  }
  catch {"Unable to Query View Image."
  }
}



function TS-GetDataSourceRevisions
{
 param(
 [string[]] $DataSourceName = "",
 [string[]] $ProjectName = "" 
 )
 try
 {
  $DataSourceID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName
  
  $PageSize = 100
  $PageNumber = 1
  $done = 'FALSE'

  While ($done -eq 'FALSE')
   {
    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$DataSourceID/revisions?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get

    $totalAvailable = $response.tsResponse.pagination.totalAvailable

    If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

    $PageNumber += 1


    ForEach ($detail in $response.tsResponse.revisions.revision)
    {
     $Revisions = [pscustomobject]@{DataSourceName=$DataSourceName; Project=$ProjectName; RevisionNumber=$detail.revisionnumber; PublishedAt=$detail.publishedAt; IsDeleted=$detail.deleted; IsCurrent=$detail.current;Size=$detail.SizeinBytes; Publisher=$detail.publisher.name}
     $Revisions
    }
   }
  }
  catch {"Unable to Get Datasource Revisions"}
 }

function TS-GetWorkbookRevisions
{
 param(
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "" 
 )
 try
 {
  $WorkbookID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName
  
  $PageSize = 100
  $PageNumber = 1
  $done = 'FALSE'

  While ($done -eq 'FALSE')
   {
    $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$workbookID/revisions?pageSize=$PageSize`&pageNumber=$PageNumber -Headers $headers -Method Get

    $totalAvailable = $response.tsResponse.pagination.totalAvailable

    If ($PageSize*$PageNumber -gt $totalAvailable) { $done = 'TRUE'}

    $PageNumber += 1


    ForEach ($detail in $response.tsResponse.revisions.revision)
    {
     $Revisions = [pscustomobject]@{WorkbookName=$WorkbookName; Project=$ProjectName; RevisionNumber=$detail.revisionnumber; PublishedAt=$detail.publishedAt; IsDeleted=$detail.deleted; IsCurrent=$detail.current;Size=$detail.SizeinBytes; Publisher=$detail.publisher.name}
     $Revisions
    }
   }
  }
  catch {"Unable to Get Workbook Revisions"}
 }

function TS-RemoveWorkbookRevision
{
 param(
 [string[]] $WorkbookName = "",
 [string[]] $ProjectName = "",
 [string[]] $RevisionNumber =""
 )
 try
 {
  $WorkbookID = TS-GetWorkbookDetails -Name $WorkbookName -ProjectName $ProjectName
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/workbooks/$workbookID/revisions/$RevisionNumber -Headers $headers -Method Delete
  "Removed Workbook Revision: " + $RevisionNumber
  }
  catch {"Unable to remove Workbook Revision: " + $RevisionNumber  }
 }


function TS-RemoveDataSourceRevision
{
 param(
 [string[]] $DataSourceName = "",
 [string[]] $ProjectName = "",
 [string[]] $RevisionNumber =""
 )
# try
 #{
  $DataSourceID = TS-GetDataSourceDetails -Name $DataSourceName -ProjectName $ProjectName
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$siteID/datasources/$datasourceID/revisions/$RevisionNumber -Headers $headers -Method Delete
  "Removed Datasource Revision: " + $RevisionNumber
 # }
  #catch {"Unable to remove Datasource Revision: " + $RevisionNumber  }
 }




    
## Sign in / Out
Export-ModuleMember -Function TS-SignIn
Export-ModuleMember -Function TS-SignOut

## Projects Management
Export-ModuleMember -Function TS-QueryProjects
Export-ModuleMember -Function TS-DeleteProject
Export-ModuleMember -Function TS-CreateProject
Export-ModuleMember -Function TS-UpdateProject

## Sites Management
Export-ModuleMember -Function TS-QuerySites
Export-ModuleMember -Function TS-QuerySite
Export-ModuleMember -Function TS-UpdateSite
Export-ModuleMember -Function TS-CreateSite
Export-ModuleMember -Function TS-ChangeToSite
Export-ModuleMember -Function TS-DeleteSite

## Groups Management
Export-ModuleMember -Function TS-CreateGroup
Export-ModuleMember -Function TS-DeleteGroup
Export-ModuleMember -Function TS-QueryGroups
Export-ModuleMember -Function TS-UpdateGroup

## Users Management
Export-ModuleMember -Function TS-GetUsersOnSite
Export-ModuleMember -Function TS-AddUserToGroup
Export-ModuleMember -Function TS-RemoveUserFromGroup
Export-ModuleMember -Function TS-RemoveUserFromSite
Export-ModuleMember -Function TS-GetUsersInGroup
Export-ModuleMember -Function TS-QueryUser
Export-ModuleMember -Function TS-AddUserToSite
Export-ModuleMember -Function TS-UpdateUser

## Schedules and Extracts Management
Export-ModuleMember -Function TS-QuerySchedules
Export-ModuleMember -Function TS-QueryExtractRefreshTasks
Export-ModuleMember -Function TS-UpdateSchedule
Export-ModuleMember -Function TS-CreateSchedule
Export-ModuleMember -Function TS-DeleteSchedule
Export-ModuleMember -Function TS-GetExtractRefreshTasks
Export-ModuleMember -Function TS-RunExtractRefreshTask

## Workbook and Views Management
Export-ModuleMember -Function TS-QueryViewsForSite
Export-ModuleMember -Function TS-QueryWorkbooksForUser
Export-ModuleMember -Function TS-QueryWorkbooksForSite
Export-ModuleMember -Function TS-QueryViewsForWorkbook
Export-ModuleMember -Function TS-QueryWorkbook
Export-ModuleMember -Function TS-UpdateWorkbook
Export-ModuleMember -Function TS-DeleteWorkbook
Export-ModuleMember -Function TS-AddTagsToWorkbook
Export-ModuleMember -Function TS-DeleteTagFromWorkbook
Export-ModuleMember -Function TS-QueryWorkbookConnections

## DataSources Management
Export-ModuleMember -Function TS-QueryDataSources
Export-ModuleMember -Function TS-QueryDataSource
Export-ModuleMember -Function TS-QueryDataSourceConnections

Export-ModuleMember -Function TS-DeleteDataSource
Export-ModuleMember -Function TS-UpdateDataSource
Export-ModuleMember -Function TS-UpdateDataSourceConnection

## Favorites Management
Export-ModuleMember -Function TS-AddWorkbookToFavorites
Export-ModuleMember -Function TS-AddViewToFavorites
Export-ModuleMember -Function TS-DeleteWorkbookFromFavorites
Export-ModuleMember -Function TS-DeleteViewFromFavorites

## Permissions Management
Export-ModuleMember -Function TS-UpdateProjectPermissions
Export-ModuleMember -Function TS-QueryProjectPermissions

Export-ModuleMember -Function TS-QueryWorkbookPermissions
Export-ModuleMember -Function TS-UpdateWorkbookPermissions

Export-ModuleMember -Function TS-QueryDataSourcePermissions
Export-ModuleMember -Function TS-UpdateDataSourcePermissions

# Publishing & Downloading
Export-ModuleMember -Function TS-PublishDataSource
Export-ModuleMember -Function TS-PublishWorkbook

Export-ModuleMember -Function TS-DownloadDataSource
Export-ModuleMember -Function TS-DownloadWorkbook

Export-ModuleMember -Function TS-QueryWorkbookPreviewImage
Export-ModuleMember -Function TS-QueryViewPreviewImage
Export-ModuleMember -Function TS-QueryViewImage


# Workbook and DataSource Revisions 
Export-ModuleMember -Function TS-GetDataSourceRevisions
Export-ModuleMember -Function TS-GetWorkbookRevisions
Export-ModuleMember -Function TS-RemoveWorkbookRevision
Export-ModuleMember -Function TS-RemoveDataSourceRevision
Export-ModuleMember -Function TS-DownloadDataSourceRevision
Export-ModuleMember -Function TS-DownloadWorkbookRevision
