   $password = "MyP@ssW0rd12345"
   $username = "my.Email@gmail.com"
   $smtpServer = "smtp.gmail.com"
   $to_address = "test@test.com"
   $subject = "TEST"
   $port = 587

       $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
       $mycreds = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
      
 Send-MailMessage -From $username -To $to_address -SmtpServer $smtpServer -Subject $subject -Credential $mycreds -Port $port -UseSsl $true
