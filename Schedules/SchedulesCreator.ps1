 param(
 [string[]] $server,
 [string[]] $username,
 [string[]] $password,
 [validateset('http','https')][string[]] $protocol = 'http',
 [validateset('True','False')][string[]] $disable = 'False',
 [string[]] $file = "C:\temp\schedules.csv"
 )

TS-SignIn -server $server -username $username -password $password -protocol $protocol

$Schedules = Import-Csv -Delimiter ";" -Path $file

ForEach ($schedule in $Schedules)
 {
    $schedule
    if ($schedule.End -ne ''){$EndTime = ($schedule.End).Substring(0,5)}else{$EndTime = ''}

    TS-CreateSchedule -ScheduleName $schedule.name -Priority $schedule.priority -Type $schedule.type -ExecutionOrder $schedule.executionOrder -State $schedule.state -Frequency $schedule.Frequency -StartTime ($schedule.Start).Substring(0,5) -EndTime $EndTime -Interval $schedule.Interval

    if ($disable -eq 'True')
        {
         Start-Sleep -Seconds 1
         TS-UpdateSchedule -ScheduleName $schedule.name  -newState Suspended
        }
 }

TS-SignOut
