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


 param(
 [string[]] $server,
 [string[]] $username,
 [string[]] $password
 )

$remote_Backups_Folder = "\\RemoteServer\ShareName\"

$CopyFilesToRemote = $True
$PurgeOldFiles = $True

$EmailSubject = "Tableau Server Backup and Log Zip: " + $env:COMPUTERNAME + " " + $date
$smtp_server = "smtp.mail.com"
$smtp_port = 25
$smtp_from = "tableau@server.com"
$smtp_to = "YourEmail@address.com"

$DaysToKeep = 5

$date = Get-Date
$CrLf = "`r`n"
$TSM_server         = "https://"+$server+":8850"
$zipfile            = "logs_"+ $date.Year+$date.Month+$date.Day+".zip"
$backups_file       = "tabsvc_"+ $date.Year+$date.Month+$date.Day
$settings_file      = "ServerSettings.json"

# Login to Server
$EmailBody = "***** Login to TSM *****" +$CrLf
$output = &tsm login -s $TSM_server -u $username -p $password
$output = @($output -split '`n')


foreach ($line in $output)
 {
   $emailbody += $line +$CrLf
 }

# Get Folder Locations
$backups_folder = &tsm configuration get -k basefilepath.backuprestore
$logs_folder    = &tsm configuration get -k basefilepath.log_archive


# Export Settings File
$Emailbody += $crlf + "***** Export Settings File *****" + $CrLf
$output = &tsm settings export -f $backups_folder'\'$settings_file
$output = @($output -split '`n')

foreach ($line in $output)
 {
   $emailbody += $line +$CrLf
 }

#Run Zip Logs
$Emailbody += $crlf + "***** Zip Up old Log Files *****" + $CrLf
#$output = &tsm maintenance ziplogs -a -f $zipfile
$output = @($output -split '`n')


foreach ($line in $output)
 {
   $emailbody += $line +$CrLf
 }
 
# Run Clean Up
$Emailbody += $crlf + "***** Clean Up old Log Files *****" + $CrLf
#$output = &tsm maintenance cleanup -l -t -q
$output = @($output -split '`n')

foreach ($line in $output)
 {
   $emailbody += $line +$CrLf
 }


# Run backups
$Emailbody += $crlf + "***** Backup  Files *****" + $CrLf
#$output = &tsm maintenance backup -f $Backups_file
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


If ($CopyFilesToRemote -eq $True)
 {
  copy-Item -path $logs_folder"\"$zipfile -destination $remote_Backups_Folder$zipfile -Force
  copy-Item -path $backups_folder"\"$settings_file -destination $remote_Backups_Folder$settings_file -Force
  copy-Item -path $backups_folder"\"$backups_file".tsbak" -Destination $remote_Backups_Folder$backups_file".tsbak" -Force
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

$smtp.Send($msg)
$msg.dispose()


