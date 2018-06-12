   $password = "xxxxxxx"
   $username = "glen.robinson@acme.org"
   $smtpServer = "smtp.office365.com"
   $to_address = "test@test.com"
   $subject = "TEST"
   $port = 587
   $from_address = "glen.robinson@acme.org"
   $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
   $mycreds = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
      
   Send-MailMessage -From $from_address -To $to_address -SmtpServer $smtpServer -Subject $subject  -Port $port -UseSsl $true -Credential $mycreds
