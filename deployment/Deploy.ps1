param
(
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentFile,

    [Parameter(Mandatory = $true)]
    [string]$PublishFolder
)

#=========================================================
# Deployment Engine
# Version : 1.1.0
#=========================================================

$ErrorActionPreference = "Stop"

Import-Module WebAdministration

#---------------------------------------------------------
# Global Variables
#---------------------------------------------------------

$DeploymentVersion = "1.1.0"

$DeploymentId = Get-Date -Format "yyyyMMdd_HHmmss"

$DeploymentStartTime = Get-Date

$DeploymentSucceeded = $false

$RollbackSucceeded = $false

$BackupFolder = $null

$config = $null

$EnvironmentName = ""
$SitePath = ""
$BackupPath = ""
$AppPool = ""
$ConfigFile = ""
$HealthCheckUrl = ""

#---------------------------------------------------------
# Logging
#---------------------------------------------------------

function Write-Section
{
    param([string]$Message)

    Write-Host ""
    Write-Host "=================================================="
    Write-Host " $Message"
    Write-Host "=================================================="
    Write-Host ""
}

function Write-Info
{
    param([string]$Message)

    Write-Host "[INFO ] $Message"
}

function Write-WarningLog
{
    param([string]$Message)

    Write-Host "[WARN ] $Message" -ForegroundColor Yellow
}

function Write-Success
{
    param([string]$Message)

    Write-Host "[ OK  ] $Message" -ForegroundColor Green
}

function Write-ErrorLog
{
    param([string]$Message)

    Write-Host "[FAIL ] $Message" -ForegroundColor Red
}

Write-Section "Xperience Deployment Engine"

Write-Info "Version        : $DeploymentVersion"
Write-Info "Deployment Id  : $DeploymentId"
Write-Info "Started        : $DeploymentStartTime"

#---------------------------------------------------------
# Read Environment Configuration
#---------------------------------------------------------

function Read-Configuration
{
    Write-Section "Loading Configuration"

    if (!(Test-Path $EnvironmentFile))
    {
        throw "Environment configuration file not found: $EnvironmentFile"
    }

    $script:config = Get-Content `
        $EnvironmentFile `
        -Raw |
        ConvertFrom-Json

    $script:EnvironmentName = $config.EnvironmentName
    $script:SitePath        = $config.SitePath
    $script:BackupPath      = $config.BackupPath
    $script:AppPool         = $config.ApplicationPool
    $script:ConfigFile      = $config.ConfigurationFile
    $script:HealthCheckUrl  = $config.HealthCheckUrl

    Write-Info "Environment : $EnvironmentName"
    Write-Info "Site Path   : $SitePath"
    Write-Info "Backup Path : $BackupPath"
    Write-Info "App Pool    : $AppPool"
}

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

#---------------------------------------------------------
# Stop Application Pool
#---------------------------------------------------------

function Stop-ApplicationPool
{
    Write-Section "Stopping Application Pool"

    $state = (Get-WebAppPoolState -Name $AppPool).Value

    if ($state -eq "Started")
    {
        Stop-WebAppPool -Name $AppPool

        Write-Success "Application Pool stopped."
    }
    else
    {
        Write-WarningLog "Application Pool already stopped."
    }
}

#---------------------------------------------------------
# Start Application Pool
#---------------------------------------------------------

function Start-ApplicationPool
{
    Write-Section "Starting Application Pool"

    $state = (Get-WebAppPoolState -Name $AppPool).Value

    if ($state -ne "Started")
    {
        Start-WebAppPool -Name $AppPool

        Write-Success "Application Pool started."
    }
    else
    {
        Write-WarningLog "Application Pool already running."
    }

    Start-Sleep -Seconds 5
}

#---------------------------------------------------------
# Ensure Application Pool is Running
#---------------------------------------------------------

function Ensure-ApplicationPoolRunning
{
    Write-Section "Verifying Application Pool"

    $MaxAttempts = 3
    $DelaySeconds = 5

    for ($Attempt = 1; $Attempt -le $MaxAttempts; $Attempt++)
    {
        $State = (Get-WebAppPoolState -Name $AppPool).Value

        if ($State -eq "Started")
        {
            Write-Success "Application Pool is running."

            return
        }

        Write-WarningLog "Application Pool is '$State'. Attempting to start ($Attempt of $MaxAttempts)..."

        Start-WebAppPool -Name $AppPool

        Start-Sleep -Seconds $DelaySeconds
    }

    $State = (Get-WebAppPoolState -Name $AppPool).Value

    if ($State -ne "Started")
    {
        throw "Application Pool failed to start after $MaxAttempts attempts."
    }

    Write-Success "Application Pool is running."
}

#---------------------------------------------------------
# Clean Deployment Folder
#---------------------------------------------------------

function Clear-DeploymentFolder
{
    Write-Section "Cleaning Deployment Folder"

    Get-ChildItem `
        $SitePath `
        -Force |
    Where-Object {
        $_.Name -ne "App_Data"
    } |
    Remove-Item `
        -Recurse `
        -Force

    Write-Success "Deployment folder cleaned."
}

#---------------------------------------------------------
# Copy Deployment Files
#---------------------------------------------------------

function Copy-DeploymentFiles
{
    Write-Section "Copying Deployment Files"

    $LogFile = Join-Path $env:TEMP "robocopy.log"

    Write-Info "Log File : $LogFile"

    robocopy `
        $PublishFolder `
        $SitePath `
        /MIR `
        /R:2 `
        /W:2 `
        /NFL `
        /NDL `
        /NP `
        /LOG:$LogFile

    $ExitCode = $LASTEXITCODE

	Write-Info "Robocopy Exit Code : $ExitCode"

	if ($ExitCode -ge 8)
	{
		throw "Robocopy failed with exit code $ExitCode."
	}

	# Reset Robocopy exit code
	$global:LASTEXITCODE = 0

	Write-Success "Deployment files copied."
}

#---------------------------------------------------------
# Apply Configuration
#---------------------------------------------------------

function Apply-Configuration
{
    Write-Section "Applying Configuration"

    $SourceConfiguration = Join-Path $SitePath $ConfigFile
    $DestinationConfiguration = Join-Path $SitePath "appsettings.json"

    Write-Info "Source      : $SourceConfiguration"
    Write-Info "Destination : $DestinationConfiguration"

    if (!(Test-Path $SourceConfiguration))
    {
        throw "Configuration file '$ConfigFile' was not found in deployment folder."
    }

    Copy-Item `
        -Path $SourceConfiguration `
        -Destination $DestinationConfiguration `
        -Force

    Write-Success "Configuration applied."
}

#---------------------------------------------------------
# Health Check
#---------------------------------------------------------

function Invoke-HealthCheck
{
    Write-Section "Running Health Check"

    $MaxAttempts = 12
    $DelaySeconds = 5

    for ($Attempt = 1; $Attempt -le $MaxAttempts; $Attempt++)
    {
        Write-Info "Health Check Attempt $Attempt of $MaxAttempts"

        try
        {
            $Response = Invoke-WebRequest `
                -Uri $HealthCheckUrl `
                -UseBasicParsing `
                -TimeoutSec 10

            if ($Response.StatusCode -eq 200)
            {
                Write-Success "Health check passed."

                return $true
            }

            Write-WarningLog "Received HTTP Status $($Response.StatusCode)"
        }
        catch
        {
            Write-WarningLog $_.Exception.Message
        }

        if ($Attempt -lt $MaxAttempts)
        {
            Write-Info "Waiting $DelaySeconds seconds before retry..."
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    Write-ErrorLog "Health check failed after $MaxAttempts attempts."

    return $false
}

#---------------------------------------------------------
# Rollback
#---------------------------------------------------------

function Invoke-Rollback
{
    Write-Section "Rolling Back Deployment"

    try
    {
        Stop-ApplicationPool

        Write-Info "Removing failed deployment..."

        Get-ChildItem `
            $SitePath `
            -Force |
        Where-Object {
            $_.Name -ne "App_Data"
        } |
        Remove-Item `
            -Recurse `
            -Force

        Write-Info "Restoring backup..."

        robocopy `
            $BackupFolder `
            $SitePath `
            /E `
            /R:2 `
            /W:2 `
            /NFL `
            /NDL `
            /NP | Out-Null

        Apply-Configuration

        Start-ApplicationPool

        if (Invoke-HealthCheck)
        {
            $script:RollbackSucceeded = $true

			Write-Success "Rollback completed successfully."

			Write-WarningLog "Previous deployment has been restored."
        }
        else
        {
            throw "Rollback health check failed."
        }
    }
    catch
    {
        Write-ErrorLog "Rollback failed."

        throw
    }
}

#---------------------------------------------------------
# Deployment Summary
#---------------------------------------------------------

function Write-DeploymentSummary
{
    $Duration = (Get-Date) - $DeploymentStartTime

    Write-Section "Deployment Summary"

    Write-Info "Environment      : $EnvironmentName"
    Write-Info "Deployment Id    : $DeploymentId"
    Write-Info "Duration         : $($Duration.ToString())"

    if ($DeploymentSucceeded)
    {
        Write-Success "Deployment completed successfully."
    }
    elseif ($RollbackSucceeded)
    {
        Write-WarningLog "Deployment failed."

        Write-WarningLog "Rollback completed successfully."

        Write-WarningLog "Environment restored to previous version."
    }
    else
    {
        Write-ErrorLog "Deployment failed."

        Write-ErrorLog "Rollback failed."

        Write-ErrorLog "Environment requires manual intervention."
    }
}

#=========================================================
# Main
#=========================================================

Read-Configuration

Test-Deployment

Backup-Deployment

try
{
    Stop-ApplicationPool

    Clear-DeploymentFolder

    Copy-DeploymentFiles

    Apply-Configuration

    Start-ApplicationPool

	Ensure-ApplicationPoolRunning
	
    if (!(Invoke-HealthCheck))
    {
        throw "Health check failed."
    }

    $script:DeploymentSucceeded = $true
}
catch
{
    Write-ErrorLog $_.Exception.Message

    try
    {
        Invoke-Rollback
    }
    catch
    {
        Write-ErrorLog "Automatic rollback failed."
    }
}
finally
{
    Write-DeploymentSummary

    #-----------------------------------------------------
    # GitHub Actions Exit Code
    #-----------------------------------------------------

    if ($DeploymentSucceeded)
    {
        $global:LASTEXITCODE = 0
        exit 0
    }

    if ($RollbackSucceeded)
    {
        $global:LASTEXITCODE = 1
        exit 1
    }

    $global:LASTEXITCODE = 1
    exit 1
}