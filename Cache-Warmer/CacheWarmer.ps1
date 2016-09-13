$csvfile = import-csv -path "CacheWarmerList.csv"

$server = "http://localhost"
$username = "username"
$password = "password"
$TempFile = "c:\temp\tempfile.pdf"
$tabcmd = "c:\Program Files\Tableau\Tableau Server\10.0\bin\tabcmd.exe"

foreach ($line in $csvfile)
{
  $site = $line.site
  $URLPath = $line.URLPath+"?:refresh=yes"
  $FileName = $line.File
  $type = $line.type

  if ($FileName -eq '') {$FileName = $TempFile}

  if ($site -eq '') #Default Site
  {
   # Export View
   if ($type -eq 'View') 
     { & $tabcmd get -s $server -u $username -p $password  $URLPath -f $FileName}
   else
   {
   # Export Full Workbook
   & $tabcmd export -s $server -u $username -p $password  $URLPath --fullpdf -f $FileName
   }
  }
  else
  {
    # Non Default Site (add site ID)
    if ($type -eq 'View') 
     { & $tabcmd get -s $server -u $username -p $password -t $site $URLPath -f $FileName}
   else
   {
   # Add Site to command
   & $tabcmd export -s $server -u $username -p $password -t $site $URLPath --fullpdf -f $FileName
   }
  }
}
& $tabcmd logout