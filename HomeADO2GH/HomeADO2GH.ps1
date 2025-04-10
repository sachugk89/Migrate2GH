#!/usr/bin/env pwsh

# =========== Created with CLI version 1.12.0 ===========

function Exec {
    param (
        [scriptblock]$ScriptBlock
    )
    & @ScriptBlock
    if ($lastexitcode -ne 0) {
        exit $lastexitcode
    }
}

function ExecAndGetMigrationID {
    param (
        [scriptblock]$ScriptBlock
    )
    $MigrationID = & @ScriptBlock | ForEach-Object {
        Write-Host $_
        $_
    } | Select-String -Pattern "\(ID: (.+)\)" | ForEach-Object { $_.matches.groups[1] }
    return $MigrationID
}

function ExecBatch {
    param (
        [scriptblock[]]$ScriptBlocks
    )
    $Global:LastBatchFailures = 0
    foreach ($ScriptBlock in $ScriptBlocks)
    {
        & @ScriptBlock
        if ($lastexitcode -ne 0) {
            $Global:LastBatchFailures++
        }
    }
}

if (-not $env:ADO_PAT) {
    Write-Error "ADO_PAT environment variable must be set to a valid Azure DevOps Personal Access Token with the appropriate scopes. For more information see https://docs.github.com/en/migrations/using-github-enterprise-importer/preparing-to-migrate-with-github-enterprise-importer/managing-access-for-github-enterprise-importer#personal-access-tokens-for-azure-devops"
    exit 1
} else {
    Write-Host "ADO_PAT environment variable is set and will be used to authenticate to Azure DevOps."
}

if (-not $env:GH_PAT) {
    Write-Error "GH_PAT environment variable must be set to a valid GitHub Personal Access Token with the appropriate scopes. For more information see https://docs.github.com/en/migrations/using-github-enterprise-importer/preparing-to-migrate-with-github-enterprise-importer/managing-access-for-github-enterprise-importer#creating-a-personal-access-token-for-github-enterprise-importer"
    exit 1
} else {
    Write-Host "GH_PAT environment variable is set and will be used to authenticate to GitHub."
}

$Succeeded = 0
$Failed = 0
$RepoMigrations = [ordered]@{}

# =========== Queueing migration for Organization: sachugk ===========

# === Queueing repo migrations for Team Project: sachugk/Github ===

$MigrationID = ExecAndGetMigrationID { gh ado2gh migrate-repo --ado-org "sachugk" --ado-team-project "Github" --ado-repo "Github" --github-org "Terdockube" --github-repo "Github-Github" --queue-only --target-repo-visibility private }
$RepoMigrations["sachugk/Github-Github"] = $MigrationID

# === Queueing repo migrations for Team Project: sachugk/Space Game ===

$MigrationID = ExecAndGetMigrationID { gh ado2gh migrate-repo --ado-org "sachugk" --ado-team-project "Space Game" --ado-repo "Space Game" --github-org "Terdockube" --github-repo "Space-Game-Space-Game" --queue-only --target-repo-visibility private }
$RepoMigrations["sachugk/Space-Game-Space-Game"] = $MigrationID

# === Queueing repo migrations for Team Project: sachugk/MyHealthClinic ===

$MigrationID = ExecAndGetMigrationID { gh ado2gh migrate-repo --ado-org "sachugk" --ado-team-project "MyHealthClinic" --ado-repo "MyHealthClinic" --github-org "Terdockube" --github-repo "MyHealthClinic-MyHealthClinic" --queue-only --target-repo-visibility private }
$RepoMigrations["sachugk/MyHealthClinic-MyHealthClinic"] = $MigrationID

# =========== Waiting for all migrations to finish for Organization: sachugk ===========

# === Waiting for repo migration to finish for Team Project: Github and Repo: Github. Will then complete the below post migration steps. ===
$CanExecuteBatch = $false
if ($null -ne $RepoMigrations["sachugk/Github-Github"]) {
    gh ado2gh wait-for-migration --migration-id $RepoMigrations["sachugk/Github-Github"]
    $CanExecuteBatch = ($lastexitcode -eq 0)
}
if ($CanExecuteBatch) {
    $Succeeded++
} else {
    $Failed++
}

# === Waiting for repo migration to finish for Team Project: Space Game and Repo: Space Game. Will then complete the below post migration steps. ===
$CanExecuteBatch = $false
if ($null -ne $RepoMigrations["sachugk/Space-Game-Space-Game"]) {
    gh ado2gh wait-for-migration --migration-id $RepoMigrations["sachugk/Space-Game-Space-Game"]
    $CanExecuteBatch = ($lastexitcode -eq 0)
}
if ($CanExecuteBatch) {
    $Succeeded++
} else {
    $Failed++
}

# === Waiting for repo migration to finish for Team Project: MyHealthClinic and Repo: MyHealthClinic. Will then complete the below post migration steps. ===
$CanExecuteBatch = $false
if ($null -ne $RepoMigrations["sachugk/MyHealthClinic-MyHealthClinic"]) {
    gh ado2gh wait-for-migration --migration-id $RepoMigrations["sachugk/MyHealthClinic-MyHealthClinic"]
    $CanExecuteBatch = ($lastexitcode -eq 0)
}
if ($CanExecuteBatch) {
    $Succeeded++
} else {
    $Failed++
}

Write-Host =============== Summary ===============
Write-Host Total number of successful migrations: $Succeeded
Write-Host Total number of failed migrations: $Failed

if ($Failed -ne 0) {
    exit 1
}


