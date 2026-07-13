#=========================================================
# Enterprise Output
# Version : 1.3.0
#=========================================================

function Initialize-Logging
{
    if (!(Test-Path $LogFolder))
    {
        New-Item -ItemType Directory -Path $LogFolder | Out-Null
    }

    New-Item -ItemType File -Path $LogFile -Force | Out-Null

    Set-Content -Path $LogFile -Value "" -Encoding UTF8

    Write-DeploymentHeader
	
	Invoke-LogMaintenance
}

#---------------------------------------------------------
# Log Maintenance
#---------------------------------------------------------

function Invoke-LogMaintenance
{
    Write-Section -Title "Log Maintenance"

    Write-Info -Message "Log Folder : $LogFolder"
    Write-Info -Message "Retention  : $LogRetentionDays days"

    $CutoffDate = (Get-Date).AddDays(-$LogRetentionDays)

    $DeletedFiles = 0

    Get-ChildItem `
        -Path $LogFolder `
        -Filter "*.log" `
        -File `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.LastWriteTime -lt $CutoffDate -and
		$_.Name -ne (Split-Path $LogFile -Leaf)
    } |
    ForEach-Object {

        try
		{
			Remove-Item `
				-Path $_.FullName `
				-Force `
				-ErrorAction Stop

			$DeletedFiles++
		}
		catch
		{
			Write-WarningLog -Message "Unable to delete log file: $($_.FullName)"
		}
    }

    Write-Success -Message "Deleted $DeletedFiles expired log file(s)."
}

function Write-DeploymentHeader
{
    Write-Section -Title "Xperience Deployment Engine"
    Write-Info -Message "Version        : $DeploymentVersion"
    Write-Info -Message "Deployment Id  : $DeploymentId"
    Write-Info -Message "Environment    : $EnvironmentName"
    Write-Info -Message "Machine        : $env:COMPUTERNAME"
    Write-Info -Message "User           : $env:USERNAME"
    Write-Info -Message "Started        : $DeploymentStartTime"
}

function Write-Log
{
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$true)][string]$Level
    )

    if (!(Test-Path $LogFile)) { return }

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Add-Content -Path $LogFile -Value "$Timestamp [$Level] $Message" -Encoding UTF8
}

function Write-LogRaw
{
    param(
        [Parameter(Mandatory=$true)][string]$Message
    )

    if (!(Test-Path $LogFile)) { return }

    Add-Content -Path $LogFile -Value $Message -Encoding UTF8
}

function Write-Message
{
    param(
        [Parameter(Mandatory=$true)][string]$Level,
        [Parameter(Mandatory=$true)][string]$Message,
        [ConsoleColor]$Color=[ConsoleColor]::White
    )

    $ConsoleMessage = switch ($Level)
    {
        "INFO" { "[INFO ] $Message" }
        "OK"   { "[ OK  ] $Message" }
        "WARN" { "[WARN ] $Message" }
        "FAIL" { "[FAIL ] $Message" }
        default { $Message }
    }

    Write-Host $ConsoleMessage -ForegroundColor $Color
    Write-Log -Message $Message -Level $Level
}

function Write-Section
{
    param(
        [Parameter(Mandatory=$true)][string]$Title
    )

    $Line = "=" * 50

    Write-Host ""
    Write-Host $Line -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host $Line -ForegroundColor Cyan
    Write-Host ""

    Write-LogRaw -Message " "
    Write-LogRaw -Message $Line
    Write-LogRaw -Message " $Title"
    Write-LogRaw -Message $Line
    Write-LogRaw -Message " "
}

function Write-Info { param([Parameter(Mandatory=$true)][string]$Message) Write-Message -Level "INFO" -Message $Message -Color White }
function Write-Success { param([Parameter(Mandatory=$true)][string]$Message) Write-Message -Level "OK" -Message $Message -Color Green }
function Write-WarningLog { param([Parameter(Mandatory=$true)][string]$Message) Write-Message -Level "WARN" -Message $Message -Color Yellow }
function Write-ErrorLog { param([Parameter(Mandatory=$true)][string]$Message) Write-Message -Level "FAIL" -Message $Message -Color Red }

function Write-DeploymentSummary
{
    $Duration = (Get-Date) - $DeploymentStartTime

    Write-Section -Title "Deployment Summary"

    Write-Info -Message "Environment      : $EnvironmentName"
    Write-Info -Message "Deployment Id    : $DeploymentId"
    Write-Info -Message "Duration         : $($Duration.ToString())"
	Write-Info -Message "Retry Count      : $RetryCount"
    Write-Info -Message "Started          : $DeploymentStartTime"
	Write-Info -Message "Finished         : $(Get-Date)"
	Write-Info -Message "Server           : $env:COMPUTERNAME"
	Write-Info -Message "User             : $env:USERNAME"

    if ($DeploymentSucceeded)
    {
        Write-Success -Message "Deployment completed successfully."
    }
    elseif ($RollbackSucceeded)
    {
        Write-WarningLog -Message "Deployment failed."
        Write-WarningLog -Message "Rollback completed successfully."
        Write-WarningLog -Message "Environment restored to previous version."
    }
    else
    {
        Write-ErrorLog -Message "Deployment failed."
        Write-ErrorLog -Message "Rollback failed."
        Write-ErrorLog -Message "Environment requires manual intervention."
    }
}

#---------------------------------------------------------
# Update Latest Log
#---------------------------------------------------------

function Update-LatestLog
{
    $LatestLog = Join-Path $LogFolder "latest.log"

    Copy-Item `
        -Path $LogFile `
        -Destination $LatestLog `
        -Force

    Write-Info -Message "Latest Log : $LatestLog"
}
