param
(
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentFile,

    [Parameter(Mandatory = $true)]
    [string]$PublishFolder
)

#=========================================================
# Load Modules
#=========================================================

. "$PSScriptRoot\Modules\Common.ps1"
. "$PSScriptRoot\Modules\Configuration.ps1"
. "$PSScriptRoot\Modules\Validation.ps1"
. "$PSScriptRoot\Modules\Backup.ps1"
. "$PSScriptRoot\Modules\Rollback.ps1"
. "$PSScriptRoot\Modules\IIS.ps1"
. "$PSScriptRoot\Modules\Deployment.ps1"
. "$PSScriptRoot\Modules\Health.ps1"
. "$PSScriptRoot\Modules\Lock.ps1"

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


Write-Section "Xperience Deployment Engine"

Write-Info "Version        : $DeploymentVersion"
Write-Info "Deployment Id  : $DeploymentId"
Write-Info "Started        : $DeploymentStartTime"

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

Acquire-DeploymentLock

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
	#-----------------------------------------------------
    # Release Deployment Lock
    #-----------------------------------------------------

    try
    {
        Release-DeploymentLock
    }
    catch
    {
        Write-WarningLog "Unable to release deployment lock."
		Write-WarningLog $_.Exception.Message
    }

    #-----------------------------------------------------
    # Deployment Summary
    #-----------------------------------------------------
	
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