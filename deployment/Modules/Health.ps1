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
