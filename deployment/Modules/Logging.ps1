#=========================================================
# Enterprise Logging
# Version : 1.3.0
#=========================================================

#---------------------------------------------------------
# Initialize Logging
#---------------------------------------------------------

function Initialize-Logging
{
    if (!(Test-Path $LogFolder))
    {
        New-Item `
            -ItemType Directory `
            -Path $LogFolder | Out-Null
    }

    New-Item `
        -ItemType File `
        -Path $LogFile `
        -Force | Out-Null
}

#---------------------------------------------------------
# Write Log
#---------------------------------------------------------

function Write-Log
{
    param(
        [string]$Level,
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Add-Content `
        -Path $LogFile `
        -Value "$Timestamp [$Level] $Message"
}