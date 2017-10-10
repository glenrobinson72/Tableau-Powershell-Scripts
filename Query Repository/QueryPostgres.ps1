
function Query_Repo{  
    param(
          [string]$query,
          [string]$dbServer = "localhost",   # DB Server (either IP or hostname)
          [string]$dbName   = "workgroup", # Name of the database
          [string]$dbUser   = "readonly",    # User we'll use to connect to the database/server
          [string]$dbPass   = "password",     # Password for the $dbUser
          [string]$port     = "8060"
         )

    $conn = New-Object System.Data.Odbc.OdbcConnection
    $conn.ConnectionString = "Driver={PostgreSQL Unicode(x64)};Server=$dbServer;Port=$port;Database=$dbName;Uid=$dbUser;Pwd=$dbPass;"
    $conn.open()
    $cmd = New-object System.Data.Odbc.OdbcCommand($query,$conn)
    $ds = New-Object system.Data.DataSet
    (New-Object system.Data.odbc.odbcDataAdapter($cmd)).fill($ds) | out-null
    $conn.close()
    $ds.Tables[0]
}


Query_Repo -query "SELECT * FROM _background_tasks" | Format-Table -AutoSize
