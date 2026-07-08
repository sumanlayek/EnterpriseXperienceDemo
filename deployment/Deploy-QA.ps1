param(
    [string]$PublishFolder
)

$SitePath = "C:\Sites\QA\KenticoSample.Web"
$BackupRoot = "C:\Backups\QA"
$AppPool = "QA"

Write-Host "==============================="
Write-Host "Starting QA Deployment"
Write-Host "==============================="

Import-Module WebAdministration

# Create backup folder if needed
if (!(Test-Path $BackupRoot))
{
    New-Item -ItemType Directory -Path $BackupRoot | Out-Null
}

# Backup existing deployment
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFolder = Join-Path $BackupRoot $TimeStamp

if (Test-Path $SitePath)
{
    Write-Host "Creating backup..."

    Copy-Item `
        -Path $SitePath `
        -Destination $BackupFolder `
        -Recurse `
        -Force
}

Write-Host "Stopping App Pool..."

Stop-WebAppPool $AppPool

Write-Host "Cleaning deployment folder..."

Get-ChildItem $SitePath -Force |
Where-Object { $_.Name -ne "App_Data" } |
Remove-Item -Recurse -Force

Write-Host "Copying published files..."

Copy-Item `
    "$PublishFolder\*" `
    $SitePath `
    -Recurse `
    -Force

Write-Host "Applying QA configuration..."

Copy-Item `
    "$SitePath\appsettings.QA.Deployment.json" `
    "$SitePath\appsettings.json" `
    -Force

Write-Host "Starting App Pool..."

Start-WebAppPool $AppPool

Write-Host ""
Write-Host "QA Deployment Completed Successfully"