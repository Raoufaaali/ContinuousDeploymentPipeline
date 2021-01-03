$DestinationPath = "C:\PlayerMaxAutomatedDeployment"
$DisplayVersionBefore = '0'
$PublisherServiceName = "ATI.PlayerMax.Publisher.Service"
$TranscoderServiceName = "ATI.PlayerMax.Transcoder.Service"
$CasinoServiceName = "ATI.PlayerMax.Casino.Service"
$ApplicationName = $env:APPLICATION_NAME
$InstallCasinoService = 'True'

# List of PlayerMax Registry Display Names
#ATI.PlayerMax Property Management Tool  
#ATI.PlayerMax Publisher Service
#ATI.PlayerMax Transcoder Service
#ATI.PlayerMax Casino Service

#Next, check what application is being deployed usin the temp environmnet variable $env:APPLICATION_NAME 
#Based on the $env:APPLICATION_NAME value, set the $DisplayName variable. The $DisplayName variable is then used to unininstall the service/app 

switch ($ApplicationName) {
    "PublisherService" { $ServiceName = $PublisherServiceName ; $DisplayName = "ATI.PlayerMax Publisher Service" }
    "TranscoderService" { $ServiceName = $TranscoderServiceName ; $DisplayName = "ATI.PlayerMax Transcoder Service" }
    "CasinoService" { $ServiceName = $CasinoServiceName ; $DisplayName = "ATI.PlayerMax Casino Service" }
    "PropertyManagementTool" { $ServiceName = "NA" ; $DisplayName = "ATI.PlayerMax Property Management Tool" }
    "Database" { &   "$DestinationPath\UpgradeDB.ps1" ; Exit $LastExitCode }

    default { "Invalid argument" }
}

Function GetService($name) {
    return Get-WmiObject -Class Win32_Service -Filter "Name = '$name'"
}

Function Wait-ServiceState {
    param (
        [string]$ServiceName,
        [ValidateSet("Running", "StartPending", "Stopped", "StopPending", "ContinuePending", "Paused", "PausePending")][string]$ServiceState,
        [int]$SecondsToWait = 30
    )
    $counter = 0
    $ServiceStateCorrect = $False
    do {
        $counter++
        Start-Sleep -Milliseconds 250
        $serviceInfo = Get-Service $ServiceName
        If ($serviceInfo.Status -eq $ServiceState) {
            $ServiceStateCorrect = $True
            Break
        }
    } until (($counter * .250) -ge $SecondsToWait)
    Return $ServiceStateCorrect
}

Function ApplyCasinoServiceSettings {
    $valueList = (Get-SSMParameterValue -Name CasinoServiceSettings).Parameters.Value 
    Write-Host "CasinoServiceSettings=" $valueList
    $configs = $valueList -split ','

    foreach ($config in $configs) {
        $key, $value = $config.split('=')
        $key = $key.trim()
        $value = $value.trim()
        Write-Host $key "=" $value
        [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Machine)

        # if the pipeline flag CasinoService.CloudInstall is set to false, update the global InstallCasinoService from the default true to false
        if (($key -eq 'CLOUD_INSTALL') -and ($value -eq 'false' )) {       
            $script:InstallCasinoService = 'False';             
            Write-Host "The CLOUD_INSTALL flag is set to $value .. Casino Service won't be installed and will be removed if it exists"
        }
    }
}

Function DoInstall ($CasinoServiceFlag) {

    if ( ( $ApplicationName -eq "CasinoService" ) -and ( $CasinoServiceFlag -eq 'False') ) {
        Write-Host "InstallCasinoService flag is $InstallCasinoService, not going to install the casino service"
        Break
    }
    else {

        Start-sleep -s 3
        Write-Host "Installing $ApplicationName ..."
        CD $DestinationPath
        Get-Location

        Get-ChildItem -Path $DestinationPath -Filter *.exe | Sort LastWriteTime | Select -last 1 |
        Foreach-Object {
            Start-Process $_.Name /VERYSILENT
        }

        #Start  Service 
        Start-sleep -s 3

        Write-Host "Starting $ServiceName..."
        Start-Service -Name $ServiceName        
    }
}

# Execution starts here:

$service = $service = GetService($serviceName)

if ($service -ne $null) {
    Write-Host " $ServiceName Found. Stopping The Service..."
  
    $service | stop-service -Force
    $ok = Wait-ServiceState $ServiceName "Stopped" 20
    if ($ok -eq $False) {
        Write-Host "Failed to stop service"
    }
}
else {
    Write-Host "Service Not Found"
}

if ( $ApplicationName -eq "CasinoService" ) {
    ApplyCasinoServiceSettings
}

# If the application being deployed is not the Casino Service, then uninstall it
# Also uninstall the Casino Service if the InstallCasinoService flag is set to false 
if ( ( $ApplicationName -ne "CasinoService" ) -or ( ( $ApplicationName -eq "CasinoService" ) -and ( $InstallCasinoService -eq 'False' ) ) ) {

    Write-Host "Uninstalling $ServiceName ..."

    $applist = Get-ChildItem -Path  HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
    Get-ItemProperty |
    Where-Object { $_.DisplayName -match $DisplayName } |
    Select-Object -Property DisplayName, UninstallString

    ForEach ($app in $applist) {
        If ($app.UninstallString) {
            $DisplayVersionBefore = $app.DisplayVersion   
            $uninst = $app.UninstallString
            & cmd /c $uninst /quiet /norestart /VERYSILENT
        }
    }
}

DoInstall "$InstallCasinoService"

#Verify windows service. If verification failed, fail the deployment 
if ( ($ApplicationName -eq "PublisherService" ) -or ($ApplicationName -eq "TranscoderService") -or ($ApplicationName -eq "CasinoService")  ) {

    if ( ( $ApplicationName -eq "CasinoService" ) -and ( $InstallCasinoService -eq $False ) ) {
        Break # Dont check the status for the Casino Service if the Casino Service CLOUD_INSTALL flag is set to false
    }

    $ok = Wait-ServiceState $ServiceName "Running" 20

    if ($ok -eq $False) {
        Write-Host "Service failed to start"
        EXIT -1    
    }
    Write-Host "Service installed and verified successfully."
}