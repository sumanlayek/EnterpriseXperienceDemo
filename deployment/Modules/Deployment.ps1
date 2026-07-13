#---------------------------------------------------------
# Clean Deployment Folder
#---------------------------------------------------------

function Clear-DeploymentFolder
{
    Write-Section "Cleaning Deployment Folder"

    Invoke-WithRetry `
        -Operation "Clean deployment folder" `
        -MaxAttempts 10 `
        -DelaySeconds 3 `
        -Action {

            Get-ChildItem `
                -Path $SitePath `
                -Force |
            Where-Object {
                $_.Name -ne "App_Data"
            } |
            Remove-Item `
                -Recurse `
                -Force `
                -ErrorAction Stop
        }

    Write-Success "Deployment folder cleaned."
}

#---------------------------------------------------------
# Copy Deployment Files
#---------------------------------------------------------

function Copy-DeploymentFiles
{
    Write-Section "Copying Deployment Files"

    $LogFile = Join-Path $env:TEMP "robocopy.log"

    Write-Info "Log File : $LogFile"

    robocopy `
        $PublishFolder `
        $SitePath `
        /MIR `
        /R:2 `
        /W:2 `
        /NFL `
        /NDL `
        /NP `
        /LOG:$LogFile

    $ExitCode = $LASTEXITCODE

	Write-Info "Robocopy Exit Code : $ExitCode"

	if ($ExitCode -ge 8)
	{
		throw "Robocopy failed with exit code $ExitCode."
	}

	# Reset Robocopy exit code
	$global:LASTEXITCODE = 0

	Write-Success "Deployment files copied."
}

#---------------------------------------------------------
# Apply Configuration
#---------------------------------------------------------

function Apply-Configuration
{
    Write-Section "Applying Configuration"

    $SourceConfiguration = Join-Path $SitePath $ConfigFile
    $DestinationConfiguration = Join-Path $SitePath "appsettings.json"

    Write-Info "Source      : $SourceConfiguration"
    Write-Info "Destination : $DestinationConfiguration"

    if (!(Test-Path $SourceConfiguration))
    {
        throw "Configuration file '$ConfigFile' was not found in deployment folder."
    }

    Copy-Item `
        -Path $SourceConfiguration `
        -Destination $DestinationConfiguration `
        -Force

    Write-Success "Configuration applied."
}
