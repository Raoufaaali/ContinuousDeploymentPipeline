Function CheckIfDatabaseExists ($ConnectionStringPrameter)
{
	try
	{
		#Try connecting to Database to verify if it exists
		$ConnectionString = $ConnectionStringPrameter
		$SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
		$SQLConnection.Open()

        return 'True';
	
	}
	catch
	{
		Write-Host 'Database not present, Creating Database ...'
		return 'False';
	}
	finally
	{
		$SQLConnection.Close()
	}
}


Function WriteConfiguration ($ConnectionString)
{
	try
	{    
	$SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
    $SQLConnection.Open()

    $SQLCommand = New-Object System.Data.SqlClient.SqlCommand
	# List of configuration values
    $SQLCommand.CommandText = "select ConfigCode, ConfigValue1 FROM dbo.CG_X_Config"
    $SQLCommand.Connection = $SQLConnection
    $DataAdapter = new-object System.Data.SqlClient.SqlDataAdapter $SQLCommand
    $Dataset = new-object System.Data.Dataset
    $DataAdapter.Fill($Dataset)
    $table = $Dataset.Tables[0]
	for($i=0;$i -lt $Dataset.Tables[0].Rows.Count;$i++)
	{ 
	  write-host "$($Dataset.Tables[0].Rows[$i][0]) = $($Dataset.Tables[0].Rows[$i][1])"
	}

	# Active Directory Prefix
	$SQLCommand = New-Object System.Data.SqlClient.SqlCommand
	$SQLCommand.CommandText = "select ConfigValue4 from CG_X_ConfigDetail where ConfigID = (select ConfigId FROM CG_X_Config where ConfigCode = 'ADDOMAIN')"
	$SQLCommand.Connection = $SQLConnection
	$DataAdapter = new-object System.Data.SqlClient.SqlDataAdapter $SQLCommand
	$Dataset = new-object System.Data.Dataset
	$res = $DataAdapter.Fill($Dataset)
    $table = $Dataset.Tables[0]
	write-host "Active Directory Prefix = $($Dataset.Tables[0].Rows[0][0])"

	# Active Directory Group Table
	$SQLCommand = New-Object System.Data.SqlClient.SqlCommand
	$SQLCommand.CommandText = "select ADGroupName from CG_X_ADGroup where Active = 1"
	$SQLCommand.Connection = $SQLConnection
	$DataAdapter = new-object System.Data.SqlClient.SqlDataAdapter $SQLCommand
	$Dataset = new-object System.Data.Dataset
        $res = $DataAdapter.Fill($Dataset)
        $table = $Dataset.Tables[0]
	write-host "Active Directory Groups"
	for($i=0;$i -lt $Dataset.Tables[0].Rows.Count;$i++)
	{ 
	  write-host "   $($Dataset.Tables[0].Rows[$i][0])"
	}	
	}
	catch
	{
		Write-Host 'Configuration Listing Failed'
        Write-Host $_.Exception.Message        
		Exit -1 
		
	}
	finally
	{
		$SQLConnection.Close()
	}
}

#execution starts here:

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
    
    #Check if Database exists, create if not.
	$IsDataasbaseExists = CheckIfDatabaseExists "$ConnectionString Initial Catalog=$Databasename;"

    if ( $IsDataasbaseExists -eq 'True'){
        WriteConfiguration  "$ConnectionString Initial Catalog=$Databasename; "; 
     }
     else {
        Write-Host "Database doesnt exist"
     }
}

catch
{
	Write-Host "Couldn't access the DB"
	Write-Host $_.Exception.Message
	EXIT -1
}