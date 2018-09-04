#######################################################################################################
#     
#        PROGRAM: TSMBackup.ps1
#
#    DESCRIPTION: Powershell script to run tableau server backups, email results to server admin, 
#                 and purge old backups. (using TSM)
#
#
#     WRITTEN BY:  Glen Robinson (Interworks UK)
#
#
#######################################################################################################




$server = "localhost"
$username = "admin"
$password = "Passw0rd"
$filesfolder    = "C:\ProgramData\Tableau\Tableau Server\data\tabsvc\files"
$backups_folder = $filesfolder+"\backups\"
$logs_folder    = $filesfolder+"\log-archives\"
$remote_Backups_Folder = "\\RemoteServer\ShareName\"
$remote_Backups_Folder = "C:\Backups\"


$CopyFilesToRemote = $True
$PurgeOldFiles = $True

$EmailSubject = "Tableau Server Backup and Log Zip: " + $env:COMPUTERNAME + " " + $date
$smtp_server = "smtp.mail.com"
$smtp_port = 25
$smtp_from = "tableau@server.com"
$smtp_to = "YourEmail@address.com"

$DaysToKeep = 0

$date = Get-Date
$CrLf = "`r`n"
$TSM_server         = "https://"+$server+":8850"
$zipfile            = "logs_"+ $date.Year+$date.Month+$date.Day+".zip"
$backups_file       = "tabsvc_"+ $date.Year+$date.Month+$date.Day
$TSM_server

# Login to Server
$EmailBody = "***** Login to TSM *****" +$CrLf
$output = &tsm login -s $TSM_server -u $username -p $password
$output = @($output -split '`n')


foreach ($line in $output)
 {
   $emailbody += $line +$CrLf
 }

#Run Zip Logs
$Emailbody += $crlf + "***** Zip Up old Log Files *****" + $CrLf
$output = &tsm maintenance ziplogs -a -f $zipfile
$output = @($output -split '`n')


foreach ($line in $output)
 {
   $emailbody += $line +$CrLf
 }
 
# Run Clean Up
$Emailbody += $crlf + "***** Clean Up old Log Files *****" + $CrLf
$output = &tsm maintenance cleanup -l -t -q
$output = @($output -split '`n')

foreach ($line in $output)
 {
   $emailbody += $line +$CrLf
 }


# Run backups
$Emailbody += $crlf + "***** Backup  Files *****" + $CrLf
$output = &tsm maintenance backup -f $Backups_file
$output = @($output -split '`n')

foreach ($line in $output)
 {
   $emailbody += $line +$CrLf
 }

# Logout of Server
$Emailbody += $crlf + "***** Logout of TSM *****" + $CrLf
$output = &tsm logout
$output = @($output -split '`n')


foreach ($line in $output)
 {
   $emailbody += $line +$CrLf
 }

 $emailbody

 
If ($CopyFilesToRemote -eq $True)
 {
  copy-Item -path $logs_folder$zipfile -destination $remote_Backups_Folder$zipfile
  copy-Item -path $backups_folder$backups_file".tsbak" -Destination $remote_Backups_Folder$backups_file".tsbak"
 }
 

# Delete old backup and zip log Files
If ($PurgeOldFiles -eq $True)
 {
  # Delete local copies of backups and zip logs
  $oldfiles = Get-ChildItem $backups_folder -file | Where-object {$_.LastWriteTime -lt $date.AddDays(-$DaysToKeep)}
  if($oldfiles.count -gt 0)
   {
    $oldfiles.Delete()
   }
  # Delete local copies of zip logs
  $oldfiles = Get-ChildItem $logs_folder -file | Where-object {$_.LastWriteTime -lt $date.AddDays(-$DaysToKeep)}
  if($oldfiles.count -gt 0)
   {
    $oldfiles.Delete()
   }


  # Delete Remote copies of Old files
  if ($CopyFilesToRemote -eq $True)
   {
    $oldfiles = Get-ChildItem $remote_backups_folder -file | Where-object {$_.LastWriteTime -lt $date.AddDays(-$DaysToKeep)}
    if($oldfiles.count -gt 0)
     {
      $oldfiles.Delete()
     }
   }
 } 

  
#Email Results to Admin

$msg = new-object system.net.mail.mailmessage
$smtp = new-object Net.Mail.SmtpClient($smtp_server, $smtp_port)
$smtp.Credentials = New-Object System.Net.NetworkCredential;
$smtp.Timeout = 1000000

$msg.From = $smtp_from
$msg.To.Add($smtp_to)

$msg.subject = $EmailSubject
$msg.body = $EmailBody

#$smtp.Send($msg)
$msg.dispose()


