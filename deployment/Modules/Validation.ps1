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
	
	Test-ApplicationPool

	Test-IISWebsite
	
	Test-SitePath

	Test-BackupPath

	Test-LockFolder

	Test-LogFolder

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

#---------------------------------------------------------
# Validate Application Pool
#---------------------------------------------------------

function Test-ApplicationPool
{
    Write-Info -Message "Validating Application Pool..."

    if (!(Test-Path "IIS:\AppPools\$AppPool"))
    {
        throw "Application Pool '$AppPool' does not exist."
    }

    Write-Success -Message "Application Pool found."
}

#---------------------------------------------------------
# Validate IIS Website
#---------------------------------------------------------

function Test-IISWebsite
{
    Write-Info -Message "Validating IIS Website..."

    $Website = Get-Website |
        Where-Object {
            $_.PhysicalPath -eq $SitePath
        }

    if ($null -eq $Website)
    {
        throw "No IIS Website is using '$SitePath'."
    }

    Write-Success -Message "IIS Website found."
}

#---------------------------------------------------------
# Validate Site Path
#---------------------------------------------------------

function Test-SitePath
{
    Write-Info -Message "Validating Site Path..."

    if (!(Test-Path $SitePath))
    {
        throw "Site path does not exist: $SitePath"
    }

    Write-Success -Message "Site path found."
}

#---------------------------------------------------------
# Validate Backup Path
#---------------------------------------------------------

function Test-BackupPath
{
    Write-Info -Message "Validating Backup Path..."

    if (!(Test-Path $BackupPath))
    {
        New-Item `
            -ItemType Directory `
            -Path $BackupPath `
            -Force | Out-Null

        Write-Info -Message "Backup path created."
    }

    $TestFile = Join-Path $BackupPath "write-test.tmp"

    try
    {
        Set-Content `
            -Path $TestFile `
            -Value "Deployment Engine Test" `
            -ErrorAction Stop

        Remove-Item `
            -Path $TestFile `
            -Force

        Write-Success -Message "Backup path is writable."
    }
    catch
    {
        throw "Backup path is not writable: $BackupPath"
    }
}

#---------------------------------------------------------
# Validate Lock Folder
#---------------------------------------------------------

function Test-LockFolder
{
    Write-Info -Message "Validating Lock Folder..."

    if (!(Test-Path $LockFolder))
    {
        New-Item `
            -ItemType Directory `
            -Path $LockFolder `
            -Force | Out-Null

        Write-Info -Message "Lock folder created."
    }

    $TestFile = Join-Path $LockFolder "write-test.tmp"

    try
    {
        Set-Content `
            -Path $TestFile `
            -Value "Deployment Engine Test" `
            -ErrorAction Stop

        Remove-Item `
            -Path $TestFile `
            -Force

        Write-Success -Message "Lock folder is writable."
    }
    catch
    {
        throw "Lock folder is not writable: $LockFolder"
    }
}

#---------------------------------------------------------
# Validate Log Folder
#---------------------------------------------------------

function Test-LogFolder
{
    Write-Info -Message "Validating Log Folder..."

    if (!(Test-Path $LogFolder))
    {
        New-Item `
            -ItemType Directory `
            -Path $LogFolder `
            -Force | Out-Null

        Write-Info -Message "Log folder created."
    }

    $TestFile = Join-Path $LogFolder "write-test.tmp"

    try
    {
        Set-Content `
            -Path $TestFile `
            -Value "Deployment Engine Test" `
            -ErrorAction Stop

        Remove-Item `
            -Path $TestFile `
            -Force

        Write-Success -Message "Log folder is writable."
    }
    catch
    {
        throw "Log folder is not writable: $LogFolder"
    }
}
