#---------------------------------------------------------
# Rollback
#---------------------------------------------------------

function Invoke-Rollback
{
    Write-Section "Rolling Back Deployment"

    try
    {
        Stop-ApplicationPool

        Write-Info "Removing failed deployment..."

        Get-ChildItem `
            $SitePath `
            -Force |
        Where-Object {
            $_.Name -ne "App_Data"
        } |
        Remove-Item `
            -Recurse `
            -Force

        Write-Info "Restoring backup..."

        robocopy `
            $BackupFolder `
            $SitePath `
            /E `
            /R:2 `
            /W:2 `
            /NFL `
            /NDL `
            /NP | Out-Null

        Apply-Configuration

        Start-ApplicationPool

        if (Invoke-HealthCheck)
        {
            $script:RollbackSucceeded = $true

			Write-Success "Rollback completed successfully."

			Write-WarningLog "Previous deployment has been restored."
        }
        else
        {
            throw "Rollback health check failed."
        }
    }
    catch
    {
        Write-ErrorLog "Rollback failed."

        throw
    }
}