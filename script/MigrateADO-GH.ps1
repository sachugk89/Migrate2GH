# MigrateADO-GH.ps1
# Script to migrate repositories from Azure DevOps (ADO) to GitHub with commits, tags, and branches.
# Also compares commits, branches, and tags between the two repositories.

# Prerequisites:
# - Install Git on your system and ensure it's available in the PATH.
# - Authenticate with both Azure DevOps and GitHub using Personal Access Tokens (PATs).
# - Install the ImportExcel PowerShell module:
#   Install-Module -Name ImportExcel -Scope CurrentUser -Force

# Variables
$adoOrg = Read-Host "Enter Azure DevOps organization name" # Azure DevOps organization name
$adoPAT = Read-Host "Enter Azure DevOps Personal Access Token (PAT)" -AsSecureString # Azure DevOps PAT
$githubOrg = Read-Host "Enter GitHub organization name" # GitHub organization name
$githubPAT = Read-Host "Enter GitHub Personal Access Token (PAT)" -AsSecureString # GitHub PAT
$excelFilePath = Read-Host "Enter the path to the Excel file containing ADO project and repo names" # Excel file path
$logFile = "C:\Users\61036638\OneDrive - LTIMindtree\Desktop\COP\GitHub repo\Migrate2GH\MigrationLogs\migration_log_$(Get-Date -Format "yyyyMMdd_HHmmss").txt" # Log file path
# Convert secure strings to plain text
$adoPATPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adoPAT))
$githubPATPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubPAT))

# Initialize logging
Start-Transcript -Path $logFile -Append

# Ensure TLS 1.2 is enabled
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Function to check if a repository exists in GitHub
function Check-GitHubRepoExists {
    param (
        [string]$githubOrg,
        [string]$repoName,
        [string]$githubPATPlain
    )

    $url = "https://api.github.com/repos/$githubOrg/$repoName"
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{Authorization = "Bearer $githubPATPlain"} -ErrorAction Stop
        if ($response -ne $null) {
            return $true
        } else {
            return $false
        }
    } catch {
        Write-Error "Failed to check repository existence for $repoName = $_"
        return $false
    }
}

# Function to compare commits, branches, and tags
function Compare-Repo {
    param (
        [string]$localPath,
        [string]$sourceRepo,
        [string]$targetRepo
    )

    Write-Host "Comparing commits, branches, and tags for $sourceRepo and $targetRepo..."

    # Compare commits
    $sourceCommits = git -C $localPath log --oneline | Measure-Object -Line
    $targetCommits = git -C $localPath log origin/main --oneline | Measure-Object -Line
    if ($sourceCommits.Lines -eq $targetCommits.Lines) {
        write-host "Source commits == $sourceCommits"
        Write-host " Target commits == $targetCommits"
        Write-Host "Commits match between $sourceRepo and $targetRepo."
    } else {
        Write-Host "Commits do not match between $sourceRepo and $targetRepo."
    }

    # Compare branches
    $sourceBranches = git -C $localPath branch -r | Select-String "origin/" | Measure-Object -Line
    $targetBranches = git -C $localPath branch -r | Select-String "origin/" | Measure-Object -Line
    write-host "sourceBranches  == $sourceBranches "
    Write-host " targetBranches == $targetBranches"
    if ($sourceBranches.Lines -eq $targetBranches.Lines) {
        Write-Host "Branches match between $sourceRepo and $targetRepo."
    } else {
        Write-Host "Branches do not match between $sourceRepo and $targetRepo."
    }

    # Compare tags
    $sourceTags = git -C $localPath tag | Measure-Object -Line
    $targetTags = git -C $localPath tag | Measure-Object -Line
    write-host "sourceTags  == $sourceTags "
    Write-host " targetTags == $targetTags"
    if ($sourceTags.Lines -eq $targetTags.Lines) {
        Write-Host "Tags match between $sourceRepo and $targetRepo."
    } else {
        Write-Host "Tags do not match between $sourceRepo and $targetRepo."
    }
}

# Main script
if (-Not (Test-Path -Path $excelFilePath)) {
    Write-Error "Excel file not found: $excelFilePath"
    exit 1
}

# Import the Excel file
$repoData = Import-Excel -Path $excelFilePath

foreach ($row in $repoData) {
    $adoProject = $row.Project
    $repo = $row.Repo

    Write-Host "Processing repository: $repo in project: $adoProject"

    # Check if the repository already exists in GitHub
    if (Check-GitHubRepoExists -githubOrg $githubOrg -repoName $repo -githubPAT $githubPATPlain) {
        Write-Host "Repository $repo already exists in GitHub. Skipping migration."
        continue
    }

    Write-Host "Migrating repository: $repo"

    # Clone the ADO repository
    $adoRepoUrl = "https://dev.azure.com/$adoOrg/$adoProject/_git/$repo"
    $localPath = "$env:TEMP\$repo"
    git clone --mirror $adoRepoUrl $localPath --config http.extraheader="Authorization: Basic $( [convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPATPlain")) )"

    # Push to GitHub
    $githubRepoUrl = "https://$githubPATPlain@github.com/$githubOrg/$repo.git"
    git -C $localPath push --mirror $githubRepoUrl

    # Compare repositories
    Compare-Repo -localPath $localPath -sourceRepo $adoRepoUrl -targetRepo $githubRepoUrl

    # Cleanup
    Remove-Item -Recurse -Force $localPath
}

Write-Host "Migration completed."

# Stop logging
Stop-Transcript