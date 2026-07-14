# Xperience Deployment Engine

PowerShell-based deployment engine for Xperience by Kentico.

## Features

- Environment-based deployments
- Enterprise logging
- Automatic log maintenance
- Deployment locking
- Backup and automatic rollback
- IIS application pool management
- Health check validation
- Generic retry framework
- Reliable deployment operations

## Modules

| Module | Responsibility |
|---------|----------------|
| Configuration.ps1 | Load environment configuration |
| Validation.ps1 | Validate deployment prerequisites |
| Backup.ps1 | Backup current deployment |
| Rollback.ps1 | Restore previous deployment if deployment fails |
| Deployment.ps1 | Clean, copy and configure deployment |
| IIS.ps1 | Manage IIS Application Pool |
| Health.ps1 | Perform post-deployment health checks |
| Lock.ps1 | Prevent concurrent deployments |
| Output.ps1 | Enterprise logging, deployment header, summary and log maintenance |
| Retry.ps1 | Generic retry framework for transient failures |

## Current Reliability Features

- Retry deployment folder cleanup
- Retry deployment file copy
- Retry configuration update

## Observability

- Deployment metrics
- Retry statistics

## Environment Validation

- Validate IIS Application Pool
- Validate IIS Website
- Validate Site Path
- Validate Backup Path
- Validate Lock Folder
- Validate Log Folder
- Verify folder write permissions

## Current Version

**Deployment Engine v1.4.0**