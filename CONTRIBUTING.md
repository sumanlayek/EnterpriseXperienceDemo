# Contributing Guide

Thank you for contributing to this project.

## Branch Strategy

- `main` – Production
- `develop` – Integration
- `feature/*` – New features
- `release/*` – Release preparation
- `hotfix/*` – Production fixes

## Development Workflow

1. Create an Issue.
2. Create a feature branch from `develop`.
3. Implement the feature.
4. Test locally.
5. Run Xperience CI Store if configuration changed.
6. Commit changes.
7. Push the branch.
8. Create a Pull Request.
9. Merge into `develop`.

## Commit Message Convention

Examples:

```text
feat(ci): configure Xperience Continuous Integration
feat(build): add GitHub Actions workflow
fix(ci): resolve CI synchronization issue
docs(repo): update contributing guide
chore(repo): update .gitignore
```

## Xperience Continuous Integration

Run CI Store when modifying Xperience configuration:

```powershell
dotnet run -- --kxp-ci-store
```

Run CI Restore after pulling configuration changes:

```powershell
dotnet run -- --kxp-ci-restore
```

## Pull Requests

Every Pull Request should:

- Reference an Issue.
- Build successfully.
- Include documentation updates if applicable.
- Pass code review.