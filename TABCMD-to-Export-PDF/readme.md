A simple example of using a Powershell script to export PDF from Tableau Server.

The powershell script opens a CSV file, and uses this as a URL filter.
The username, password, servername, etc need to be made specific to your environment.


$csvfile = import-csv -path "regions.csv"

$server = "http://localhost"
$username = "admin"
$password = "password"
$Folder = "C:\temp\"
$tabcmd = "C:\Program Files\Tableau\Tableau Server\10.0\bin\tabcmd.exe"
$URL = "/views/Superstore/Overview.pdf"


foreach ($line in $csvfile)
{
  $Region = $line.Regions
  $FileName = $Folder + $Region + ".pdf"
  $FullURL = $URL + "?:Refresh&Region="+ $Region
$Region
$FileName
$FullURL
  & $tabcmd get -s $server -u $username -p $password  $FullURL  -f $FileName
}
& $tabcmd logout
