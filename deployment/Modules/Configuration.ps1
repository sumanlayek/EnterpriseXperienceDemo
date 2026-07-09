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

    $script:EnvironmentName 	= $config.EnvironmentName
    $script:SitePath        	= $config.SitePath
    $script:BackupPath      	= $config.BackupPath
    $script:AppPool         	= $config.ApplicationPool
    $script:ConfigFile      	= $config.ConfigurationFile
    $script:HealthCheckUrl  	= $config.HealthCheckUrl
	$script:LockFolder 			= $config.LockFolder
	$script:LockTimeoutMinutes 	= $config.LockTimeoutMinutes
	$script:LockFile 			= Join-Path $LockFolder "$EnvironmentName.lock"
	$script:CurrentLock 		= $null
	$script:LogFolder 			= Join-Path $config.LogFolder $EnvironmentName
	$script:LogFile 			= Join-Path $LogFolder "$DeploymentId.log"
	$script:LogRetentionDays 	= $config.LogRetentionDays
	
	if ([string]::IsNullOrWhiteSpace($config.LogFolder))
	{
		throw "LogFolder is not configured in the environment configuration."
	}

	if ($config.LogRetentionDays -le 0)
	{
		throw "LogRetentionDays must be greater than zero."
	}

    Write-Info "Environment : $EnvironmentName"
    Write-Info "Site Path   : $SitePath"
    Write-Info "Backup Path : $BackupPath"
    Write-Info "App Pool    : $AppPool"
	Write-Info "Lock Folder : $LockFolder"
	Write-Info "Log Folder  : $LogFolder"
}
