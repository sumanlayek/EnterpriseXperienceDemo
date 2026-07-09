#=========================================================
# Deployment Lock Module
# Version : 1.2.1
#=========================================================

#---------------------------------------------------------
# Create Lock Information
#---------------------------------------------------------

function New-LockInformation
{
    return [PSCustomObject]@{
        DeploymentId = $DeploymentId
        Environment  = $EnvironmentName
        Machine      = $env:COMPUTERNAME
        User         = $env:USERNAME
        ProcessId    = $PID
        Version      = $DeploymentVersion
        Started      = (Get-Date).ToString("o")
    }
}

#---------------------------------------------------------
# Read Deployment Lock
#---------------------------------------------------------

function Read-DeploymentLock
{
    if (!(Test-Path $LockFile))
    {
        return $null
    }

    try
    {
        return Get-Content `
            $LockFile `
            -Raw |
        ConvertFrom-Json
    }
	catch
	{
		Write-WarningLog "Deployment lock metadata is invalid."

		Write-Info "Lock File : $LockFile"

		Write-WarningLog $_.Exception.Message

		return $null
	}
}

#---------------------------------------------------------
# Write Deployment Lock
#---------------------------------------------------------

function Write-DeploymentLock
{
    param(
        [Parameter(Mandatory)]
        $LockInformation
    )

    $LockInformation |
        ConvertTo-Json `
            -Depth 5 |
        Set-Content `
            -Path $LockFile `
            -Encoding UTF8
}

#---------------------------------------------------------
# Remove Deployment Lock
#---------------------------------------------------------

function Remove-DeploymentLock
{
    if (Test-Path $LockFile)
    {
        Remove-Item `
            -Path $LockFile `
            -Force

        Write-Success "Lock file removed."
    }
}

#---------------------------------------------------------
# Get Lock Age
#---------------------------------------------------------

function Get-LockAge
{
    param(
        [Parameter(Mandatory)]
        $LockInformation
    )

    $Started = [datetime]$LockInformation.Started

    return (Get-Date) - $Started
}

#---------------------------------------------------------
# Test Stale Lock
#---------------------------------------------------------

function Test-StaleLock
{
    param(
        [Parameter(Mandatory)]
        $LockInformation
    )

    $Age = Get-LockAge $LockInformation

    Write-Info ("Lock Age    : {0:N1} minutes" -f $Age.TotalMinutes)

    return ($Age.TotalMinutes -ge $LockTimeoutMinutes)
}

#---------------------------------------------------------
# Acquire Deployment Lock
#---------------------------------------------------------

function Acquire-DeploymentLock
{
    Write-Section "Acquiring Deployment Lock"

    if (!(Test-Path $LockFolder))
    {
        New-Item `
            -ItemType Directory `
            -Path $LockFolder | Out-Null

        Write-Success "Lock folder created."
    }

    $TimeoutTime = (Get-Date).AddMinutes($LockTimeoutMinutes)

    while ($true)
    {
        #---------------------------------------------
        # Try Atomic Lock Creation
        #---------------------------------------------

        try
		{
			$Stream = [System.IO.File]::Open(
				$LockFile,
				[System.IO.FileMode]::CreateNew,
				[System.IO.FileAccess]::Write,
				[System.IO.FileShare]::None
			)

			$Stream.Close()

			$LockInformation = New-LockInformation

			Write-DeploymentLock $LockInformation

			$script:CurrentLock = $LockInformation

			Write-Success "Deployment lock acquired."

			Write-Info "Deployment : $DeploymentId"
			Write-Info "Machine    : $env:COMPUTERNAME"
			Write-Info "Environment: $EnvironmentName"
			Write-Info "Lock File  : $LockFile"

			return
		}
		catch [System.IO.IOException]
		{
			#
			# Expected:
			# Another deployment already owns the lock.
			#
		}
		catch
		{
			throw "Unable to create deployment lock. $($_.Exception.Message)"
		}

        #---------------------------------------------
        # Read Existing Lock
        #---------------------------------------------

        $ExistingLock = Read-DeploymentLock

        if ($null -eq $ExistingLock)
		{
			Write-WarningLog "Unable to read deployment lock metadata."

			if ((Get-Date) -gt $TimeoutTime)
			{
				throw "Timed out waiting for deployment lock."
			}

			Start-Sleep -Seconds 10

			continue
		}

        Write-WarningLog "Deployment lock detected."

        Write-Info "Deployment : $($ExistingLock.DeploymentId)"
        Write-Info "Machine    : $($ExistingLock.Machine)"
        Write-Info "Started    : $($ExistingLock.Started)"

        #---------------------------------------------
        # Stale Lock
        #---------------------------------------------

        if (Test-StaleLock $ExistingLock)
        {
            Write-WarningLog "Deployment lock is stale."

            Write-WarningLog "Removing stale deployment lock..."

            Remove-DeploymentLock

            Write-Success "Stale deployment lock removed."

            continue
        }

        #---------------------------------------------
        # Timeout
        #---------------------------------------------

        if ((Get-Date) -gt $TimeoutTime)
        {
            throw "Timed out waiting for deployment lock."
        }

        Write-Info "Waiting 10 seconds..."

        Start-Sleep -Seconds 10
    }
}

#---------------------------------------------------------
# Release Deployment Lock
#---------------------------------------------------------

function Release-DeploymentLock
{
    Write-Section "Releasing Deployment Lock"

    if (!(Test-Path $LockFile))
    {
        Write-WarningLog "Deployment lock does not exist."

        return
    }

    $ExistingLock = Read-DeploymentLock

    if ($null -eq $ExistingLock)
    {
        Write-WarningLog "Unable to read deployment lock."

        return
    }

    if ($null -eq $CurrentLock)
    {
        Write-WarningLog "Current deployment does not own a lock."

        return
    }

    if ($ExistingLock.DeploymentId -ne $CurrentLock.DeploymentId)
    {
        Write-WarningLog "Deployment lock belongs to another deployment."

        Write-Info "Current Deployment : $DeploymentId"
        Write-Info "Lock Deployment    : $($ExistingLock.DeploymentId)"

        return
    }

    Remove-DeploymentLock

    Write-Success "Deployment lock released."
}

