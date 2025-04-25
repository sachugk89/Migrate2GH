Install-Module -Name ImportExcel -Scope CurrentUser -Force
# Import the required module
Import-Module ImportExcel

# Define variables
$excelFilePath = Read-Host "Enter the path to the Excel file containing organization and repository details"
$githubPAT = Read-Host "Enter your GitHub Personal Access Token (PAT)" -AsSecureString
$outputFilePath = Read-Host "Enter the path to save the output Excel file"

# Convert the PAT to plain text
$githubPATPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubPAT))

# Function to get branches, commits, and tags from a GitHub repository
function Get-GitHubRepoDetails {
    param (
        [string]$organization,
        [string]$repository
    )

    $baseUrl = "https://api.github.com/repos/$organization/$repository"

    # Get branches
    $branchesUrl = "$baseUrl/branches"
    $branchesResponse = Invoke-RestMethod -Uri $branchesUrl -Headers @{Authorization = "Bearer $githubPATPlain"} -Method Get
    $branches = $branchesResponse | Select-Object -ExpandProperty name

    # Get tags
    $tagsUrl = "$baseUrl/tags"
    $tagsResponse = Invoke-RestMethod -Uri $tagsUrl -Headers @{Authorization = "Bearer $githubPATPlain"} -Method Get
    $tags = $tagsResponse | Select-Object -ExpandProperty name

    # Get commits (limited to the latest 100 commits)
    $commitsUrl = "$baseUrl/commits?per_page=100"
    $commitsResponse = Invoke-RestMethod -Uri $commitsUrl -Headers @{Authorization = "Bearer $githubPATPlain"} -Method Get
    $commits = $commitsResponse | Select-Object -ExpandProperty sha

    return @{
        Branches = $branches
        Tags = $tags
        Commits = $commits
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
    $repository = $row.'Repository'

    Write-Host "Processing repository: $repository in organization: $organization"

    try {
        # Get repository details
        $repoDetails = Get-GitHubRepoDetails -organization $organization -repository $repository

        # Add the details to the results array
        $results += [PSCustomObject]@{
            Organization = $organization
            Repository = $repository
            Branches = ($repoDetails.Branches -join ", ")
            Tags = ($repoDetails.Tags -join ", ")
            Commits = ($repoDetails.Commits -join ", ")
        }
    } catch {
        Write-Error "Failed to process repository $repository in organization $organization`: $_"
    }
}

# Export the results to an Excel file
$results | Export-Excel -Path $outputFilePath -AutoSize -Title "GitHub Repository Details"

Write-Host "Repository details have been exported to $outputFilePath"