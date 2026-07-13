#=========================================================
# Retry Framework
# Version : 1.3.1
#=========================================================

#---------------------------------------------------------
# Invoke With Retry
#---------------------------------------------------------

function Invoke-WithRetry
{
    param
    (
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [int]$MaxAttempts = 5,

        [int]$DelaySeconds = 3
    )

    for ($Attempt = 1; $Attempt -le $MaxAttempts; $Attempt++)
    {
        try
        {
            & $Action

            if ($Attempt -gt 1)
            {
                Write-Success -Message "$Operation succeeded on attempt $Attempt."
            }

            return
        }
        catch
        {
            if ($Attempt -eq $MaxAttempts)
            {
                throw
            }

            Write-WarningLog -Message "$Operation failed."

            Write-Info -Message "Attempt : $Attempt of $MaxAttempts"

            Write-WarningLog -Message $_.Exception.Message

            Write-Info -Message "Retrying in $DelaySeconds second(s)..."

            Start-Sleep -Seconds $DelaySeconds
        }
    }
}