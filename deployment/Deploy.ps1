param(
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentFile,

    [Parameter(Mandatory = $true)]
    [string]$PublishFolder
)

$ErrorActionPreference = "Stop"

Import-Module WebAdministration

Write-Host ""
Write-Host "=========================================="
Write-Host " Xperience Deployment Engine"
Write-Host "=========================================="
Write-Host ""

#-------------------------------------------------------
# Read Environment Configuration
#-------------------------------------------------------

if (!(Test-Path $EnvironmentFile))
{
    throw "Environment configuration file not found: $EnvironmentFile"
}

$config = Get-Content $EnvironmentFile -Raw | ConvertFrom-Json

$EnvironmentName = $config.EnvironmentName
$SitePath         = $config.SitePath
$BackupPath       = $config.BackupPath
$AppPool          = $config.ApplicationPool
$ConfigFile       = $config.ConfigurationFile
$HealthCheckUrl   = $config.HealthCheckUrl

Write-Host "Environment : $EnvironmentName"
Write-Host "Site Path   : $SitePath"
Write-Host "Backup Path : $BackupPath"
Write-Host "App Pool    : $AppPool"
Write-Host ""

#-------------------------------------------------------
# Validate Paths
#-------------------------------------------------------

if (!(Test-Path $PublishFolder))
{
    throw "Publish folder does not exist."
}

if (!(Test-Path $SitePath))
{
    throw "Deployment folder does not exist."
}

if (!(Test-Path $BackupPath))
{
    New-Item `
        -ItemType Directory `
        -Path $BackupPath | Out-Null
}

#-------------------------------------------------------
# Backup Current Deployment
#-------------------------------------------------------

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

$BackupFolder = Join-Path $BackupPath $TimeStamp

Write-Host "Creating backup..."

Copy-Item `
    -Path $SitePath `
    -Destination $BackupFolder `
    -Recurse `
    -Force

#-------------------------------------------------------
# Stop IIS
#-------------------------------------------------------

Write-Host ""
Write-Host "Stopping Application Pool..."

Stop-WebAppPool $AppPool

#-------------------------------------------------------
# Clean Deployment Folder
#-------------------------------------------------------

Write-Host ""
Write-Host "Cleaning Deployment Folder..."

Get-ChildItem $SitePath -Force |
Where-Object {
    $_.Name -ne "App_Data"
} |
Remove-Item `
    -Recurse `
    -Force

#-------------------------------------------------------
# Copy New Files
#-------------------------------------------------------

Write-Host ""
Write-Host "Copying Published Files..."

Copy-Item `
    "$PublishFolder\*" `
    $SitePath `
    -Recurse `
    -Force

#-------------------------------------------------------
# Apply Environment Configuration
#-------------------------------------------------------

Write-Host ""
Write-Host "Applying Configuration..."

Copy-Item `
    "$SitePath\$ConfigFile" `
    "$SitePath\appsettings.json" `
    -Force

#-------------------------------------------------------
# Start IIS
#-------------------------------------------------------

Write-Host ""
Write-Host "Starting Application Pool..."

Start-WebAppPool $AppPool

Start-Sleep -Seconds 5

#-------------------------------------------------------
# Health Check
#-------------------------------------------------------

Write-Host ""
Write-Host "Checking Website..."

try
{
    $response = Invoke-WebRequest `
        -Uri $HealthCheckUrl `
        -UseBasicParsing `
        -TimeoutSec 30

    if ($response.StatusCode -eq 200)
    {
        Write-Host ""
        Write-Host "=========================================="
        Write-Host " Deployment Successful"
        Write-Host "=========================================="
    }
    else
    {
        throw "Unexpected HTTP Status: $($response.StatusCode)"
    }
}
catch
{
    Write-Host ""
    Write-Host "=========================================="
    Write-Host " Deployment Failed"
    Write-Host "=========================================="

    throw
}