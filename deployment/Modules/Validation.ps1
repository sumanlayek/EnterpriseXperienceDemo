#=========================================================
# Validation
#=========================================================

function Test-Deployment
{
    Write-Section "Validating Deployment"

    #-----------------------------------------------------
    # Publish Folder
    #-----------------------------------------------------

    if (!(Test-Path $PublishFolder))
    {
        throw "Publish folder does not exist: $PublishFolder"
    }

    Write-Success "Publish folder found."

    #-----------------------------------------------------
    # Deployment Folder
    #-----------------------------------------------------

    if (!(Test-Path $SitePath))
    {
        throw "Deployment folder does not exist: $SitePath"
    }

    Write-Success "Deployment folder found."

    #-----------------------------------------------------
    # Backup Folder
    #-----------------------------------------------------

    if (!(Test-Path $BackupPath))
    {
        Write-WarningLog "Backup folder does not exist."

        New-Item `
            -ItemType Directory `
            -Path $BackupPath | Out-Null

        Write-Success "Backup folder created."
    }
    else
    {
        Write-Success "Backup folder found."
    }

    #-----------------------------------------------------
    # Lock Folder
    #-----------------------------------------------------

    if (![string]::IsNullOrWhiteSpace($LockFolder))
    {
        if (!(Test-Path $LockFolder))
        {
            New-Item `
                -ItemType Directory `
                -Path $LockFolder | Out-Null

            Write-Success "Lock folder created."
        }
        else
        {
            Write-Success "Lock folder found."
        }
    }

    #-----------------------------------------------------
    # Configuration File
    #-----------------------------------------------------

    $ConfigurationPath = Join-Path $PublishFolder $ConfigFile

    if (!(Test-Path $ConfigurationPath))
    {
        throw "Configuration file '$ConfigFile' was not found in the publish folder."
    }

    Write-Success "Configuration file found."

    #-----------------------------------------------------
    # Deployment Information
    #-----------------------------------------------------

    Write-Host ""

    Write-Info "Publish Folder : $PublishFolder"
    Write-Info "Site Path      : $SitePath"
    Write-Info "Backup Path    : $BackupPath"
    Write-Info "Configuration  : $ConfigFile"

    if (![string]::IsNullOrWhiteSpace($LockFolder))
    {
        Write-Info "Lock Folder    : $LockFolder"
        Write-Info "Lock Timeout   : $LockTimeoutMinutes minutes"
    }

    #-----------------------------------------------------
    # Publish Statistics
    #-----------------------------------------------------

    $Files = Get-ChildItem `
        -Path $PublishFolder `
        -File `
        -Recurse

    $TotalFiles = $Files.Count

    $TotalSize = ($Files |
        Measure-Object Length -Sum).Sum

    $SizeMB = [Math]::Round($TotalSize / 1MB, 2)

    Write-Info "Publish Files  : $TotalFiles"
    Write-Info "Publish Size   : $SizeMB MB"

    #-----------------------------------------------------
    # Deployment Configuration Files
    #-----------------------------------------------------

    Write-Host ""
    Write-Info "Deployment Configuration Files"

    Get-ChildItem `
        -Path $PublishFolder `
        -Filter "appsettings*.json" |
    Select-Object Name
}