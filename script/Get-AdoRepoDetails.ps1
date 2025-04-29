# Import the required module
Install-Module -Name ImportExcel -Scope CurrentUser -Force
Import-Module ImportExcel

# Define variables
$excelFilePath = Read-Host "Enter the path to the Excel file containing project and repository details"
$adoPAT = Read-Host "Enter your Azure DevOps Personal Access Token (PAT)" -AsSecureString
$outputFilePath = Read-Host "Enter the path to save the output Excel file"

# Convert the PAT to plain text
$adoPATPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adoPAT))

# Function to get branches, commits, and tags from an ADO repository
function Get-AdoRepoDetails {
    param (
        [string]$organization,
        [string]$project,
        [string]$repository
    )

    $baseUrl = "https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository"

    # Initialize variables
    $branches = @()
    $commits = @()
    $tags = @()

    try {
        # Get branches
        $branchesUrl = "$baseUrl/refs?filter=heads&api-version=6.0"
        $branchesResponse = Invoke-RestMethod -Uri $branchesUrl -Headers @{Authorization = "Basic $( [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPATPlain")) )"} -Method Get
        if ($branchesResponse.value) {
            $branches = $branchesResponse.value | Select-Object -ExpandProperty name
        }

        # Get commits
        $commitsUrl = "$baseUrl/commits?api-version=6.0"
        $commitsResponse = Invoke-RestMethod -Uri $commitsUrl -Headers @{Authorization = "Basic $( [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPATPlain")) )"} -Method Get
        if ($commitsResponse.value) {
            $commits = $commitsResponse.value | Select-Object -ExpandProperty commitId
        }

        # Get tags
        $tagsUrl = "$baseUrl/refs?filter=tags&api-version=6.0"
        $tagsResponse = Invoke-RestMethod -Uri $tagsUrl -Headers @{Authorization = "Basic $( [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPATPlain")) )"} -Method Get
        if ($tagsResponse.value) {
            $tags = $tagsResponse.value | Select-Object -ExpandProperty name
        }
    } catch {
        Write-Error "Failed to fetch details for repository $repository': $_"
    }

    return @{
        Branches = $branches
        BranchCount = $branches.Count
        Commits = $commits
        CommitCount = $commits.Count
        Tags = $tags
    }
}

# Check if the Excel file exists
if (-Not (Test-Path -Path $excelFilePath)) {
    Write-Error "Excel file not found: $excelFilePath"
    exit 1
}

# Read the Excel file
$repoData = Import-Excel -Path $excelFilePath

# Initialize an array to store the results
$results = @()

# Loop through each row in the Excel file
foreach ($row in $repoData) {
    $organization = $row.'Organization'
    $project = $row.'Project'
    $repository = $row.'Repository'

    Write-Host "Processing repository: $repository in project: $project"

    try {
        # Get repository details
        $repoDetails = Get-AdoRepoDetails -organization $organization -project $project -repository $repository

        # Add the details to the results array
        $results += [PSCustomObject]@{
            Organization = $organization
            Project = $project
            Repository = $repository
            BranchCount = $repoDetails.BranchCount
            CommitCount = $repoDetails.CommitCount
            Branches = ($repoDetails.Branches -join ", ")
            Commits = ($repoDetails.Commits -join ", ")
            Tags = ($repoDetails.Tags -join ", ")
        }
    } catch {
        Write-Error "Failed to process repository $repository in project $project': $_"
    }
}

# Export the results to an Excel file
$results | Export-Excel -Path $outputFilePath -AutoSize -Title "ADO Repository Details"

Write-Host "Repository details have been exported to $outputFilePath"