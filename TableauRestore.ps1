#######################################################################################################
#     
#        PROGRAM: TableauRestore.ps1
#
#    DESCRIPTION: Powershell script to run tableau server restore, email results to server admin.
#              
#
#
#     WRITTEN BY:  Glen Robinson (Interworks UK)
#
#
#######################################################################################################


$EmailSubject = "Tableau Server Restore: " + $env:COMPUTERNAME + " " + $date
$smtp_server = "smtp.mail.com"
$smtp_port = 25
$smtp_from = "tableau@server.com"
$smtp_to = "YourEmail@address.com"

$date = Get-Date
$CrLf = "`r`n"
$password = "password"

$appVersion = "10.0"
$bin_location    = "C:\Program Files\Tableau\Tableau Server\" + $appVersion + "\bin"
$backups_folder  = "C:\backups\"
$backups_file          = "tabsvc_"+ $date.Year+$date.Month+$date.Day
$tabadmin = $bin_location + "\tabadmin.exe"


# Run backups
$Emailbody += $crlf + "***** Restore File *****" + $CrLf
$output = &"$tabadmin" restore --no-config $Backups_folder$Backups_file --password $password
$output = @($output -split '`n')

foreach ($line in $output)
 {
   $emailbody += $line +$CrLf
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
