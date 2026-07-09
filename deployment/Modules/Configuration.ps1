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

    Write-Info "Environment : $EnvironmentName"
    Write-Info "Site Path   : $SitePath"
    Write-Info "Backup Path : $BackupPath"
    Write-Info "App Pool    : $AppPool"
}
