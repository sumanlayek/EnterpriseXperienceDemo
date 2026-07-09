#---------------------------------------------------------
# Backup Deployment
#---------------------------------------------------------

function Backup-Deployment
{
    Write-Section "Creating Backup"

    $TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

    $script:BackupFolder = Join-Path $BackupPath $TimeStamp

    Copy-Item `
        -Path $SitePath `
        -Destination $BackupFolder `
        -Recurse `
        -Force

    Write-Success "Backup created."

    Write-Info "Backup Folder : $BackupFolder"
}