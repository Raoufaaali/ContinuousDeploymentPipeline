Function DoBackup ($ConnectionString, $Server, $S3ARNToRestoreTo)
{
	try
	{
    #Update Configuration
	$SQLConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
	Write-Host "Connecting to $Server..."
        $SQLConnection.Open()
        Write-Host "Starting backup..."

        $SQLCommand = New-Object System.Data.SqlClient.SqlCommand
        $SQLCommand.CommandText = "exec msdb.dbo.rds_backup_database @source_db_name='CGMOBILEADMINDB', @s3_arn_to_backup_to= '$S3ARNToRestoreTo', @type='FULL', @overwrite_S3_backup_file=1"
        $SQLCommand.Connection = $SQLConnection
	    $res = $SQLCommand.ExecuteNonQuery()
	    if ($res -eq -1) {
		    Write-Host "Backup started. Run task-status.ps1 to check the operation status."
	    }

	}
	catch
	{
		Write-Host "Exception occurred in backup"		
	        Write-Host $_.Exception.Message
		Exit -1 		
	}
	finally
	{
		$SQLConnection.Close()
	}
}

# Backup Database Pre-requisites
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
# 10. Run the ./backup command and you should get "Backup started". Wait and backup will be sent to s3 bucket

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

    Write-Host 'Enter the S3 ARN to backup to. The format is <BucketARN>/<FileName.Extension> ...'
	$S3ARNToRestoreTo = Read-Host 

    Write-Host "Are you sure you want to backup to $S3ARNToRestoreTo ? Existing backups with the same name will be overwritten. Y/N ? "
    $UserResponse = Read-Host 
    
	If ($UserResponse -ne 'Y')
        {
            Write-Host "Exiting. User cancelled."
            EXIT -1
        }
		
	If ($UserResponse -eq 'Y')
        {
        DoBackup "$ConnectionString" "$Server" "$S3ARNToRestoreTo";         
        }
    
}
catch
{
	Write-Host "Couldn't access the DB"
	Write-Host $_.Exception.Message
	EXIT -1
}