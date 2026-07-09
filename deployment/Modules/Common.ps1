#---------------------------------------------------------
# Logging
#---------------------------------------------------------

function Write-Section
{
    param([string]$Message)

    Write-Host ""
    Write-Host "=================================================="
    Write-Host " $Message"
    Write-Host "=================================================="
    Write-Host ""
}

function Write-Info
{
    param([string]$Message)

    Write-Host "[INFO ] $Message"
}

function Write-WarningLog
{
    param([string]$Message)

    Write-Host "[WARN ] $Message" -ForegroundColor Yellow
}

function Write-Success
{
    param([string]$Message)

    Write-Host "[ OK  ] $Message" -ForegroundColor Green
}

function Write-ErrorLog
{
    param([string]$Message)

    Write-Host "[FAIL ] $Message" -ForegroundColor Red
}