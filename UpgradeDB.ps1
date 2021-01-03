
Function GetDatabaseBuildNumber ($ConnectionStringPrameter) {
	try {
		#Connect to DB and get the latest build # from Util.DBVersion
		$ConnectionString = $ConnectionStringPrameter

		$SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
		$SQLConnection.Open()
		Write-Host 'Connection Established'

		$SQLCommand = New-Object System.Data.SqlClient.SqlCommand
		$SQLCommand.CommandText = 'SELECT TOP 1 Build FROM [CGMOBILEADMINDB].[Util].[DBVersions] ORDER BY 1 DESC'
		$SQLCommand.Connection = $SQLConnection
		$BuildNumber = $SQLCommand.ExecuteScalar()

		return $BuildNumber    
	}
	catch {
		Write-Host 'Failed to connect to database'
		Write-Host 'aborting DB upgrade'
		Exit -1 
	}
	finally {
		$SQLConnection.Close()
	}
}

Function CheckIfDatabaseExists ($ConnectionStringPrameter) {
	try {
		#Try connecting to Database to verify if it exists
		$ConnectionString = $ConnectionStringPrameter
		$SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
		$SQLConnection.Open()

		return 'True';
	}
	catch {
		Write-Host 'Database not present, Creating Database ...'
		return 'False';
	}
	finally {
		$SQLConnection.Close()
	}
}

Function CreateDatabase ($ConnectionStringPrameter) {

	try {
		#Create the Database
		$ConnectionString = $ConnectionStringPrameter
		$SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
		$SQLConnection.Open()
		Write-Host 'Connection Established'

		$SQLCommand = New-Object System.Data.SqlClient.SqlCommand
		$SQLCommand.CommandText = 'CREATE DATABASE CGMOBILEADMINDB'
		$SQLCommand.Connection = $SQLConnection
		$BuildNumber = $SQLCommand.ExecuteNonQuery()
		Write-Host 'Database Created'
	}
	catch {
		Write-Host 'Database not created'
		Write-Host $_.Exception.Message
		Write-Host 'aborting DB make'
		Exit -1 
	}
	finally {
		$SQLConnection.Close()
	}

}

Function UpdateDatabaseSettings ($ConnectionString) {
	try {
		$SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
		$SQLConnection.Open()
		Write-Host 'UpdateDatabaseSettings...'

		$valueList = (Get-SSMParameterValue -Name PlayerMaxSettings).Parameters.Value 
		Write-Host "PlayerMaxSettings=" $valueList
		$configs = $valueList -split ','

		foreach ($config in $configs) {
			$key, $value = $config.split('=')
			$key = $key.trim()
			$value = $value.trim()
			Write-Host $key "=" $value

			$SQLCommand = New-Object System.Data.SqlClient.SqlCommand
			$SQLCommand.Connection = $SQLConnection
		   
			if ($key -eq "ADDomain") {				
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue1 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'ADDOMAIN'"				
			}
			elseif ($key -eq "ADPrefix") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue4 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'ADDOMAIN'"
			}
			elseif ($key -eq "AndroidPushARN") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue2 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'Push Notifications' and CD.ConfigValue1 = 'ANDROID'"
			}
			elseif ($key -eq "IOSPushARN") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue2 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'Push Notifications' and CD.ConfigValue1 = 'IOS'"		   
			}
			elseif ($key -eq "WinLossEmailSubject") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue3 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'WINLOSS_SERVICE'"		   
			}
			elseif ($key -eq "WinLossEmailBody") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue4 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'WINLOSS_SERVICE'"		   
			}
			elseif ($key -eq "UserGroups") {
				$groups = $value.split('|')
				foreach ($group in $groups) {
					$group = $group.trim()
					$SQLCommand.CommandText += "IF NOT EXISTS (SELECT * FROM CG_X_ADGroup WHERE ADGroupName = '$group') BEGIN INSERT INTO CG_X_ADGroup (AdGroupName, Active, Global, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate) VALUES ('$group', 1, 1, 'TFS','', getdate(), getDate()) END "
				}
			}
			elseif ($key -eq "AdminGroup") {
				$SQLCommand.CommandText = "UPDATE CG_X_ADGroup SET ADGroupName = '$value', Global = 1, Active = 1, UpdatedDate = GetDate(), UpdatedBy =  'TFS' WHERE ADGroupID = 1"
			}
			elseif ($key -eq "NexmoKey") {  
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue2 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE CD.ConfigValue1 = 'Nexmo' "
			}
			elseif ($key -eq "NexmoSecret") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue3 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE CD.ConfigValue1 = 'Nexmo' "
			}
			elseif ($key -eq "NexmoNumber") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue4 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE CD.ConfigValue1 = 'Nexmo' "
			}
			elseif ($key -eq "WinLossEmailFrom") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue1 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'WINLOSS_SERVICE' "
			}
			elseif ($key -eq "WinLossEmailTo") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue2 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'WINLOSS_SERVICE'  "
			}
			elseif ($key -eq "WinLossSMTPServer") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue1 = '$value' , CD.ConfigValue5 = '30', ConfigValue6 = 'True', ConfigValue7 = 'True' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'WINLOSS_SMTP' "
			}
			elseif ($key -eq "WinLossSMTPUsername") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue2 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'WINLOSS_SMTP'  "
			}
			elseif ($key -eq "WinLossSMTPPassword") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue3 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'WINLOSS_SMTP'  "
			}
			elseif ($key -eq "WinLossSMTPPort") {
				$SQLCommand.CommandText = "UPDATE CD SET CD.ConfigValue4 = '$value' FROM dbo.CG_X_Config C LEFT JOIN dbo.CG_X_ConfigDetail CD ON C.ConfigID = CD.ConfigID WHERE C.ConfigCode = 'WINLOSS_SMTP'  "
			}
			else {
				$SQLCommand.CommandText = "UPDATE dbo.CG_X_Config SET ConfigValue1 = '$value' WHERE ConfigCode = '$key'; "			
			}
			$res = $SQLCommand.ExecuteNonQuery()
		}

		Write-Host 'UpdateDatabaseSettings Succeeded'
	}
	catch {
		Write-Host 'UpdateDatabaseSettings Failed ...'
		Write-Host $_.Exception.Message        
		Exit -1 
	}
	finally {
		$SQLConnection.Close()
	}
}

Function UpdateJobStatus ($ConnectionStringPrameter, $isEnabled) {

	try {
		#Connect to the DB
		$ConnectionString = $ConnectionStringPrameter
		$SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
		$SQLConnection.Open()
		$SQLCommand = New-Object System.Data.SqlClient.SqlCommand
		$SQLCommand.Connection = $SQLConnection
		Write-Host 'Connection Established. Attempting to update the job status'

		$SQLCommand.CommandText = "IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs_view WHERE name=N'Reindex All') EXEC msdb.dbo.sp_update_job @job_name=N'Reindex All',@enabled = $isEnabled ;"
		$SQLCommand.CommandText += "IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs_view WHERE name=N'UpdateStatistics') EXEC msdb.dbo.sp_update_job @job_name=N'UpdateStatistics',@enabled = $isEnabled ;"
		$SQLCommand.CommandText += "IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs_view WHERE name=N'Inactive_Expired') EXEC msdb.dbo.sp_update_job @job_name=N'Inactive_Expired',@enabled = $isEnabled ;"
		$SQLCommand.CommandText += "IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs_view WHERE name=N'usp_Jb_All') EXEC msdb.dbo.sp_update_job @job_name=N'usp_Jb_All',@enabled = $isEnabled ;"
		$SQLCommand.CommandText += "IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs_view WHERE name=N'JOB_Rapid_Reserve') EXEC msdb.dbo.sp_update_job @job_name=N'JOB_Rapid_Reserve',@enabled = $isEnabled ;"
		$SQLCommand.CommandText += "IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs_view WHERE name=N'JOB_Trim_Tables') EXEC msdb.dbo.sp_update_job @job_name=N'JOB_Trim_Tables',@enabled = $isEnabled ;"
		
		$QueryResult = $SQLCommand.ExecuteNonQuery()
		Write-Host "Successfully updated DB jobs status to @enabled = $isEnabled"
	}
	catch {
		Write-Host 'An exception occurred during updating job status. aborting the operation and failing the deployment '
		Write-Host $_.Exception.Message		
		Exit -1 
	}
	finally {
		$SQLConnection.Close()
	}
}

#execution starts here:

try {

	# Specify the region this EC2 instance is running on
	$region = (Invoke-RestMethod "http://169.254.169.254/latest/dynamic/instance-identity/document").region

	# Get the DB secret
	$secret_manager = Get-SECSecretValue -SecretID PLAYERMAX_DATABASE -Region $region -ErrorAction Stop

	# Only extract the SecretString and discard the metadata 
	$secret = $secret_manager.SecretString | ConvertFrom-Json -ErrorAction Stop

	#Create connection string 
	$BuildNumberBeforUpgrade = 0;
	$Server = $secret.host
	$Databasename = "CGMOBILEADMINDB"
	$User = $secret.username
	$PW = $secret.password

	$ConnectionString = "Data Source= $Server ;User ID = $User ; Password = $PW ;" 
    
	#Check if Database exists, create if not.
	$IsDataasbaseExists = CheckIfDatabaseExists "$ConnectionString Initial Catalog=$Databasename;"

	$DestinationPath = "C:\PlayerMaxAutomatedDeployment"
	Get-Location
	CD "$DestinationPath\CGMobileAdminDB" -ErrorAction Stop
	Get-Location

	if ( $IsDataasbaseExists -eq 'True') {
		#Get the db build # before the upgrade 

		$BuildNumberBeforUpgrade = GetDatabaseBuildNumber  "$ConnectionString Initial Catalog=$Databasename; "; 
		Write-Host "Version before upgrade is " $BuildNumberBeforUpgrade
	}
	else {
		CreateDatabase "$ConnectionString"

		Write-Host "Initializing Database ..."
		cmd.exe /C "makedb.bat "$secret.host" CGMOBILEADMINDB "$secret.username" "$secret.password" " --ErrorAction Stop
	}

	UpdateJobStatus "$ConnectionString Initial Catalog=$Databasename;" 0 # Disable DB jobs before the upgrade starts
	Write-Host "Updating Database ..."
	cmd.exe /C "upgradedb.bat "$secret.host" CGMOBILEADMINDB "$secret.username" "$secret.password" " --ErrorAction Stop

	#Fail the deployment if upgradedb reported errors
	if ($LastExitCode -ne 0) {
		Write-Host "Upgradedb.bat reported error(s)"
		Write-Host "Failing the deployment.."
		EXIT -1
	}
	UpdateJobStatus "$ConnectionString Initial Catalog=$Databasename;" 1 # Enable DB jobs after the upgrade is complete

	#Get the db build # after the upgrade 
	$BuildNumberAfterUpgrade = GetDatabaseBuildNumber  "$ConnectionString" 

	#Update any settings in the database
	UpdateDatabaseSettings  "$ConnectionString Initial Catalog=$Databasename; "; 

}

catch {
	Write-Host "Couldn't upgrade the DB "
	Write-Host $_.Exception.Message
	EXIT -1
}


#Verify New Build
if ($BuildNumberAfterUpgrade -gt $BuildNumberBeforUpgrade ) {
	Write-Host "New Build # verified successufully is $BuildNumberAfterUpgrade "
}
elseif ($BuildNumberAfterUpgrade -eq $BuildNumberBeforUpgrade) {
	Write-Host "Database version did not change"	
}
