#=========================================================
# Deployment Lock
#=========================================================

function Acquire-DeploymentLock
{
    Write-Section "Acquiring Deployment Lock"

    if (!(Test-Path $LockFolder))
    {
        New-Item `
            -ItemType Directory `
            -Path $LockFolder | Out-Null
    }

    $Timeout = (Get-Date).AddMinutes($LockTimeoutMinutes)

    while (Test-Path $LockFile)
    {
        if ((Get-Date) -gt $Timeout)
        {
            throw "Timed out waiting for deployment lock."
        }

        Write-WarningLog "Another deployment is running."

        Write-Info "Waiting 10 seconds..."

        Start-Sleep -Seconds 10
    }

    New-Item `
        -ItemType File `
        -Path $LockFile `
        -Force | Out-Null

    Write-Success "Deployment lock acquired."
}

function Release-DeploymentLock
{
    Write-Section "Releasing Deployment Lock"

    if (Test-Path $LockFile)
    {
        Remove-Item `
            $LockFile `
            -Force

        Write-Success "Deployment lock released."
    }
}

