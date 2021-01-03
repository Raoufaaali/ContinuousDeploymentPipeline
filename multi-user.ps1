Function DoMultiUser ($ConnectionString, $Server)
{
	try
	{    
	    $SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
	    Write-Host "Connecting to $Server..."
        $SQLConnection.Open()
        
	    Write-Host "Set Multi User Mode..."
        $SQLCommand = New-Object System.Data.SqlClient.SqlCommand
        $SQLCommand.CommandText = "alter database CGMOBILEADMINDB set MULTI_USER"
        $SQLCommand.Connection = $SQLConnection
	    $res = $SQLCommand.ExecuteNonQuery()
	}
	catch
	{
		Write-Host "Exception occurred"		
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
	 DoMultiUser "$ConnectionString" "$Server"; 
}
catch
{
	Write-Host "Couldn't access the DB"
	Write-Host $_.Exception.Message
	EXIT -1
}