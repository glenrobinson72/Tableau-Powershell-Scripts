
 param(
 [string[]] $server,
 [string[]] $username,
 [string[]] $password,
 [validateset('http','https')][string[]] $protocol = 'http',
 [string[]] $siteID = "",
 [string] $workbook ="", 
 [string] $File ="" 
 )
 

# Set the Powerpoint Template Directory 
# -------------------------------------
$ppt_location = "C:\temp"
$work_dir      = $ppt_location + '\temp\'
$input_pres    = $ppt_location + '\template.pptx'
$output_folder = $ppt_location + '\output\'
$input_pres

Add-Type -AssemblyName Office

# Powerpoint relevant variables
# -----------------------------
$PPT         = New-Object -ComObject powerpoint.application
$ori         = [Microsoft.Office.Core.MsoTextOrientation]::msoTextOrientationHorizontal
$my_ppt      = $PPT.Presentations.Open($input_pres, $false, $false, $false)
$num_slides  = $my_ppt.Slides.Count - 1
$cover       = $my_ppt.Slides.Item(1)
$base_slide  = $my_ppt.Slides.Item(2)
$template    = $base_slide.CustomLayout
$datestr     = Get-Date -f "MMMM yyyy"
$base_slide.delete()

# Generates the RGB color for the font you want to use.
$rgb = [long] (255 + (255 * 256) + (255 * 65536))

# Adds the date generated to the first slide
$tb = $cover.Shapes.AddTextbox($ori, 50, 380, 405, 70)
$tb.TextFrame.TextRange.Text = $datestr.ToUpper()
$tb.TextFrame.TextRange.Font.NameAscii = 'Ariel'
$tb.TextFrame.TextRange.Font.Size = 20
$tb.TextFrame.TextRange.Font.Color.RGB = $rgb
$tb.Fill.Transparency = 1

$global:api_ver = '2.7'
 # generate body for sign in
 $signin_body = (’<tsRequest>
  <credentials name=“’ + $username + ’” password=“’+ $password + ’” >
   <site contentUrl="’ + $siteID +’"/>
  </credentials>
 </tsRequest>’)

   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/auth/signin -Body $signin_body -Method Post
   # get the auth token, site id and my user id

   $global:authToken = $response.tsResponse.credentials.token
   $global:site_ID = $response.tsResponse.credentials.site.id
   $global:myUserID = $response.tsResponse.credentials.user.id
   $authtoken
   # set up header fields with auth token
   $global:headers = New-Object “System.Collections.Generic.Dictionary[[String],[String]]”
   # add X-Tableau-Auth header with our auth tokents-
   $headers.Add(“X-Tableau-Auth”, $authToken)

   $filter = "&filter=name:eq:"+$workbook

   # Get Workbook Details
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$site_ID/workbooks?$filter -Headers $headers -Method Get 
   $response.tsresponse.workbooks
   $WorkbookID = $response.tsresponse.workbooks.workbook.id
   $WorkbookID

   # Get Views on Workbook
   $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/sites/$site_ID/workbooks/$WorkbookID/views -Headers $headers -Method Get

   ForEach ($detail in $response.tsResponse.Views.view)
    {
      $ViewID = $detail.ID
      $View_Name = $detail.name

      # Download View Image
      $url = $protocol.trim() + "://" + $server +"/api/" + $api_ver+ "/sites/" + $site_ID + "/views/" + $viewID + "/image?resolution=high"
     
      $url
     
      $FileName = "C:\temp\" + $View_Name +".png"
 #     Remove-Item $FileName -Force
      $wc = New-Object System.Net.WebClient
      $wc.Headers.Add('X-Tableau-Auth',$headers.Values[0])
      $wc.DownloadFile($url, $FileName)
      "File Downloaded: " + $FileName


          $num_slides = $num_slides + 1
    $new_slide  = $my_ppt.Slides.AddSlide($num_slides, $template)
    $new_pic    = $new_slide.shapes.AddPicture($FileName, $false, $true,40,120,300,390)
    #$new_txt    = $new_slide.shapes.AddTextbox($ori,600,130, 300, 400)
    #$new_txt.TextFrame.TextRange.Text = 'My Text'
    $new_pic.Title = 'Dashboard'
    $new_slide.Shapes.title.TextFrame.TextRange.Text = $View_Name
    $new_pic.LockAspectRatio = $false
    $new_pic.Width  = $new_slide.CustomLayout.Width - 300
    #$new_pic.Height = 350



     }

$name = $output_folder + $Workbook + " - " + $datestr + ".ppt"
$name
$my_ppt.SaveCopyAs($name)
$my_ppt.Close()


  # Sign out
  $response = Invoke-RestMethod -Uri ${protocol}://$server/api/$api_ver/auth/signout -Headers $headers -Method Post
