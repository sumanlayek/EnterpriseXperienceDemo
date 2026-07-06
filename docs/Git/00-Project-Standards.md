# Enterprise Xperience Demo - Project Standards

## Repository

Repository Name: EnterpriseXperienceDemo

## Solution

KenticoSample.Web.sln

## Project

KenticoSample.Web

---

# Branch Strategy

## Main

Production branch.

No direct development.

Deployment Target:
- Production

---

## Develop

Integration branch.

Deployment Target:
- QA

---

## Feature Branches

Naming:

feature/<feature-name>

Examples:

feature/github-actions

feature/xperience-ci

feature/iis-deployment

---

## Release Branches

Naming:

release/<version>

Example:

release/1.0.0

Deployment Target:
- UAT

---

## Hotfix Branches

Naming:

hotfix/<version>

Example:

hotfix/1.0.1

---

# Commit Messages

Format

type: description

Examples

feat: add GitHub Actions build

fix: resolve deployment issue

docs: update setup guide

ci: add build workflow

chore: initial project structure

---

# Pull Requests

Feature
→ Develop

Release
→ Main

Hotfix
→ Main

---

# Deployment Flow

Feature

↓

Develop

↓

QA

↓

Release

↓

UAT

↓

Main

↓

Production