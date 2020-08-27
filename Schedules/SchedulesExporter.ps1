 param(
 [string[]] $server,
 [string[]] $username,
 [string[]] $password,
 [validateset('http','https')][string[]] $protocol = 'http',
 [string[]] $file = "C:\temp\schedules.csv"
 )

TS-SignIn -server $server -username $username -password $password -protocol $protocol

$schedules = TS-QuerySchedules
"Name;State;Priority;Type;Frequency;ExecutionOrder;Start;End;Interval" > $file

ForEach ($schedule in $schedules)
  {
    $scheduleDetails = TS-UpdateSchedule -ScheduleName $schedule.name
    $scheduleDetails
    $Freqlist = ""
    switch ($scheduleDetails.Frequency)
     {

     "Weekly"
      {
       "Weekly"
        ForEach ($Interval in $scheduleDetails.Weekdays)
        { $Freqlist += $Interval + "," }
        $scheduleDetails.Name + ";" + $scheduleDetails.State + ";" + $scheduleDetails.Priority + ";" + $scheduleDetails.Type + ";" + $scheduleDetails.Frequency + ";" + $scheduleDetails.ExecutionOrder + ";" + $scheduleDetails.frequencyStart+ ";" + $scheduleDetails.frequencyEnd + ";" + $FreqList >> $file        

     }

     "Monthly"
      {
       "Monthly"
        $Freqlist = $scheduleDetails.DayofMonth
        $scheduleDetails.Name + ";" + $scheduleDetails.State + ";" + $scheduleDetails.Priority + ";" + $scheduleDetails.Type + ";" + $scheduleDetails.Frequency + ";" + $scheduleDetails.ExecutionOrder + ";" + $scheduleDetails.frequencyStart+ ";" + $scheduleDetails.frequencyEnd + ";" + $FreqList >> $file        

     }

     "Daily"
      {
       "Daily"
       $scheduleDetails.Name + ";" + $scheduleDetails.State + ";" + $scheduleDetails.Priority + ";" + $scheduleDetails.Type + ";" + $scheduleDetails.Frequency + ";" + $scheduleDetails.ExecutionOrder + ";" + $scheduleDetails.frequencyStart+ ";" + $scheduleDetails.frequencyEnd + ";" + $FreqList >> $file        

     }

     "Hourly"
      {
       "Hourly"
       $scheduleDetails

       $Freqlist = $scheduleDetails.Hours + $scheduleDetails.Minutes 
       $scheduleDetails.Name + ";" + $scheduleDetails.State + ";" + $scheduleDetails.Priority + ";" + $scheduleDetails.Type + ";" + $scheduleDetails.Frequency + ";" + $scheduleDetails.ExecutionOrder + ";" + $scheduleDetails.frequencyStart+ ";" + $scheduleDetails.frequencyEnd + ";" + $FreqList >> $file        
     }
   }

  }

TS-SignOut
