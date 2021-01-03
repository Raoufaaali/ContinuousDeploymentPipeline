Function DoTaskStatus ($ConnectionString, $Server)
{
	try
	{
    
	$SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
	Write-Host "Connecting to $Server..."
    $SQLConnection.Open()
    Write-Host "Get Task Status"
	$SQLCommandD = New-Object System.Data.SqlClient.SqlCommand
    $SQLCommandD.CommandText = "exec msdb.dbo.rds_task_status @db_name='CGMOBILEADMINDB'"
    $SQLCommandD.Connection = $SQLConnection
	$DataAdapter = new-object System.Data.SqlClient.SqlDataAdapter $SQLCommandD
    $Dataset = new-object System.Data.Dataset
    $res = $DataAdapter.Fill($Dataset)
    $table = $Dataset.Tables[0]
	for($i=0;$i -lt $Dataset.Tables[0].Columns.Count;$i++)
	{ 
	  write-host "$($Dataset.Tables[0].Columns[$i].ColumnName) = $($Dataset.Tables[0].Rows[0][$i])"
	}
	$res = $SQLCommandD.ExecuteNonQuery()
	}
	catch
	{
		Write-Host "Exception occurred in task status"		
	        Write-Host $_.Exception.Message
		Exit -1 		
	}
	finally
	{
		$SQLConnection.Close()
	}
}

try
{
	# Specify the region this EC2 instance is running on
	$region=(Invoke-RestMethod "http://169.254.169.254/latest/dynamic/instance-identity/document").region

	# Get the DB secret
	$secret_manager = Get-SECSecretValue -SecretID PLAYERMAX_DATABASE -Region $region -ErrorAction Stop

	# Only extract the SecretString and discard the metadata 
	$secret = $secret_manager.SecretString | ConvertFrom-Json -ErrorAction Stop

	#Create connection string 
	$Server = $secret.host
	$Databasename = "CGMOBILEADMINDB"
	$User = $secret.username
	$PW = $secret.password

	$ConnectionString = "Data Source= $Server ;User ID = $User ; Password = $PW ;"     
    DoTaskStatus "$ConnectionString" "$Server"; 
}
catch
{
	Write-Host "Couldn't access the DB"
	Write-Host $_.Exception.Message
	EXIT -1
}