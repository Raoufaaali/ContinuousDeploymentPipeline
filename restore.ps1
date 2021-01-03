Function DoRestore ($ConnectionString, $Server, $RestoreFrom) {
	try {
		$SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
		$SQLCommand = New-Object System.Data.SqlClient.SqlCommand
		Write-Host "Connecting to $Server..."
		$SQLConnection.Open()
				
		#check if the DB exist before restoring. If it doesn not, create it
		$IsDataasbaseExists = CheckIfDatabaseExists "$ConnectionString Initial Catalog= CGMOBILEADMINDB;"

		if ($IsDataasbaseExists -eq 'False' ) {
			Write-Host "CGMOBILEADMINDB database doesnt exist. Creating an empty DB shell to restore to..."
			$SQLCommand.CommandText = "CREATE DATABASE CGMOBILEADMINDB;"
			$SQLCommand.Connection = $SQLConnection
			$res = $SQLCommand.ExecuteNonQuery()
		}

		Write-Host "Set Single User Mode..."
		$SQLCommand.CommandText = "ALTER DATABASE CGMOBILEADMINDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
		$SQLCommand.Connection = $SQLConnection
		$res = $SQLCommand.ExecuteNonQuery()

		Write-Host "Drop Database..."
		$SQLCommand.CommandText = "DROP DATABASE CGMOBILEADMINDB"
		$SQLCommand.Connection = $SQLConnection
		$res = $SQLCommand.ExecuteNonQuery()

		Write-Host "Starting restore..."
		$SQLCommand.CommandText = "exec msdb.dbo.rds_restore_database @restore_db_name='CGMOBILEADMINDB', @s3_arn_to_restore_from='$RestoreFrom', @type='FULL'"
		$SQLCommand.Connection = $SQLConnection
		$res = $SQLCommand.ExecuteNonQuery()
		if ($res -eq -1) {
			Write-Host "Restore started. Run task-status.ps1 to check the operation status."
		}
	}
	catch {
		Write-Host "Exception occurred in restore"		
		Write-Host $_.Exception.Message
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

# Restore Database Pre-requisites
# ========================================
# Follow instructions below and/or review:
# https://aws.amazon.com/premiumsupport/knowledge-center/native-backup-rds-sql-server/

# 1. Change the role of "PlayerMaxWindowsServiceIDInstanceRoleDefaultPolicy" in IAM and add AmazonS3FullAccess
# 2. Role will also require trust relationship with rds.amazonaws.com
# 3. Create an s3 bucket and place it in the script above
# 4. In RDS for the playermax database create a new Option Group called "playermax-backup" then...
# 5. Click "Add option", choose SQLSERVER_BACKUP_RESTORE from the drop down
# 6. Choose the S3 bucket
# 7. Choose the IAM role of the EC2 server you modified
# 8. Choose "Immediately" and add the option
# 9. Edit RDS playermax and select the option "playermax-backup" and apply
# 10. Run the ./restore command and you should get "Restore started". Wait 
# 11. Use ./task-status to find if the restore has completed
# 12. Run ./multi-user once the restore is done

try {

	Write-Host "This is a dangerous operation. Data loss could occur. It's strongly recommdended to take a backup and snapshot before performing this operation"
	$IUnderstand = Read-Host "Type 'I Understand' to continue"

	If ($IUnderstand -ne 'I Understand') {
		Write-Host "Exiting. User cancelled."
		EXIT -1
	}

	Write-Host -ForegroundColor Red 'Do you want to DROP the existing PlayerMax database and restore it from a backup in S3. If the restore fails, PlayerMax DB MIGHT still be dropped regardless. Y/N?'
	$UserResponse = Read-Host 
    
	If ($UserResponse -ne 'Y') {
		Write-Host "Exiting. User cancelled."
		EXIT -1
	}
		
	If ($UserResponse -eq 'Y') {
		$RestoreFrom = Read-Host "Paste the S3 ARN to restore from then press enter. Example arn:aws:s3:::playermax-prod-bucket/CGMOBILEADMINDB.bak"
	}				

	# Specify the region this EC2 instance is running on
	$region = (Invoke-RestMethod "http://169.254.169.254/latest/dynamic/instance-identity/document").region

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
	DoRestore "$ConnectionString" "$Server" "$RestoreFrom"; 
}
catch {
	Write-Host "Couldn't access the DB"
	Write-Host $_.Exception.Message
	EXIT -1
}