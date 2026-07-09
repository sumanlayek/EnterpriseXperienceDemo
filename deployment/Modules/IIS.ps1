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
