#---------------------------------------------------------
# Validate Deployment
#---------------------------------------------------------

function Test-Deployment
{
    Write-Section "Validating Deployment"

    if (!(Test-Path $PublishFolder))
    {
        throw "Publish folder does not exist: $PublishFolder"
    }

    Write-Success "Publish folder found."

    if (!(Test-Path $SitePath))
    {
        throw "Deployment folder does not exist: $SitePath"
    }

    Write-Success "Deployment folder found."

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

    Write-Host ""
    Write-Info "Publish Folder : $PublishFolder"
    Write-Info "Configuration  : $ConfigFile"

    Write-Host ""
    Write-Info "Contents of Publish Folder"

    Get-ChildItem `
        -Path $PublishFolder |
    Select-Object Name

    $ConfigurationPath = Join-Path $PublishFolder $ConfigFile

    if (!(Test-Path $ConfigurationPath))
    {
        throw "Configuration file '$ConfigFile' was not found in the publish folder: $PublishFolder"
    }

    Write-Success "Configuration file found."
}
