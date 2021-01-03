$DestinationPath = "C:\PlayerMaxAutomatedDeployment"

If (!(Test-Path  $DestinationPath))
{
    md $DestinationPath
}

$allProcesses = Get-Process

#Stop all processes running inside the Temp folder, if any.
$allProcesses | where {$_.Path -LIKE ($DestinationPath + "*")} | Stop-Process -Force -ErrorAction SilentlyContinue

#Check and stop processes that use Property Manager Tool, also check and stop hung processes that use the CasinoServiceInstaller.exe
Get-Process | Where-Object { $_.Name -in ("PropertyManagementTool", "PropertyManagementToolInstaller.tmp", "CasinoServiceInstaller.tmp")  } | Select-Object -First 10 | Stop-Process -Force -ErrorAction SilentlyContinue

Get-ChildItem -Path $DestinationPath -Recurse | Remove-Item -Recurse -Force