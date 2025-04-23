# Install the powershell-yaml module if not already installed
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Scope CurrentUser -Force
}

# Import the powershell-yaml module
Import-Module powershell-yaml

# Define variables
$organization = Read-Host "Enter your Azure DevOps organization"
$token = Read-Host "Enter your Azure DevOps personal access token"
$ppath = Read-Host "Enter the base path for saving the output files"

# Base64 encode the token
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($token)"))

try {
    Write-Output "Starting script execution..."

    # Get all projects in the organization
    $projectsUrl = "https://dev.azure.com/$organization/_apis/projects?api-version=6.0"
    Write-Output "Fetching projects from $projectsUrl"
    $projectsResponse = Invoke-RestMethod -Uri $projectsUrl -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

    foreach ($project in $projectsResponse.value) {
        $projectName = $project.name
        Write-Output "Processing project: $projectName"

        # Create output directories if they do not exist
        $reposDir = "$ppath\$organization\$projectName\Repos"
        $pipelinesDir = "$ppath\$organization\$projectName\Pipelines"
        $releasesDir = "$ppath\$organization\$projectName\Releases"

        if (-not (Test-Path -Path $reposDir)) {
            New-Item -ItemType Directory -Path $reposDir -Force | Out-Null
            Write-Output "Created directory: $reposDir"
        }

        if (-not (Test-Path -Path $pipelinesDir)) {
            New-Item -ItemType Directory -Path $pipelinesDir -Force | Out-Null
            Write-Output "Created directory: $pipelinesDir"
        }

        if (-not (Test-Path -Path $releasesDir)) {
            New-Item -ItemType Directory -Path $releasesDir -Force | Out-Null
            Write-Output "Created directory: $releasesDir"
        }

        # Get all repositories in the project
        $reposUrl = "https://dev.azure.com/$organization/$projectName/_apis/git/repositories?api-version=6.0"
        Write-Output "Fetching repositories from $reposUrl"
        $reposResponse = Invoke-RestMethod -Uri $reposUrl -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

        foreach ($repo in $reposResponse.value) {
            $repoId = $repo.id
            $repoName = $repo.name
            Write-Output "Processing repository: $repoName (ID: $repoId)"

            try {
                # Save repository details to a file
                $repoDetailsFilePath = "$reposDir\$repoName-repo-details.yml"
                $repo | ConvertTo-Yaml | Out-File -FilePath $repoDetailsFilePath

                Write-Output "Repository details saved as $repoDetailsFilePath"
            } catch {
                Write-Error "Failed to process repository ${repoName}: $_"
                Write-Output "Error details: $($_.Exception.Response.Content)"
            }
        }

        # Get all pipelines in the project
        $pipelinesUrl = "https://dev.azure.com/$organization/$projectName/_apis/build/definitions?api-version=6.0"
        Write-Output "Fetching pipelines from $pipelinesUrl"
        $pipelinesResponse = Invoke-RestMethod -Uri $pipelinesUrl -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

        foreach ($pipeline in $pipelinesResponse.value) {
            $pipelineId = [int]$pipeline.id
            $pipelineName = $pipeline.name
            Write-Output "Processing pipeline: $pipelineName (ID: $pipelineId)"

            try {
                # Get the Classic pipeline definition
                $pipelineUrl = "https://dev.azure.com/$organization/$projectName/_apis/build/definitions/$pipelineId?api-version=6.0"
                Write-Output "Fetching pipeline definition from $pipelineUrl"
                $pipelineResponse = Invoke-RestMethod -Uri $pipelineUrl -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

                # Convert the pipeline to YAML
                $yamlPipeline = $pipelineResponse | ConvertTo-Yaml

                # Save the YAML pipeline to a file
                $yamlFilePath = "$pipelinesDir\$pipelineName-pipeline.yml"
                $yamlPipeline | Out-File -FilePath $yamlFilePath

                Write-Output "Pipeline converted to YAML and saved as $yamlFilePath"
            } catch {
                Write-Error "Failed to process pipeline ${pipelineName}: $_"
                Write-Output "Error details: $($_.Exception.Response.Content)"
            }
        }

        # Get all releases in the project
        $releasesUrl = "https://vsrm.dev.azure.com/$organization/$projectName/_apis/release/definitions?api-version=6.0"
        Write-Output "Fetching releases from $releasesUrl"
        $releasesResponse = Invoke-RestMethod -Uri $releasesUrl -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

        foreach ($release in $releasesResponse.value) {
            $releaseId = [int]$release.id
            $releaseName = $release.name
            Write-Output "Processing release: $releaseName (ID: $releaseId)"

            if ($null -ne $releaseId -and $releaseId -is [int]) {
                try {
                    # Get the release definition
                    $releaseUrl = "https://vsrm.dev.azure.com/$organization/$projectName/_apis/release/definitions/$releaseId?api-version=6.0"
                    Write-Output "Fetching release definition from $releaseUrl"
                    $releaseResponse = Invoke-RestMethod -Uri $releaseUrl -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

                    # Convert the release to YAML
                    $yamlRelease = $releaseResponse | ConvertTo-Yaml

                    # Save the YAML release to a file
                    $yamlReleaseFilePath = "$releasesDir\$releaseName-release.yml"
                    $yamlRelease | Out-File -FilePath $yamlReleaseFilePath

                    Write-Output "Release converted to YAML and saved as $yamlReleaseFilePath"
                } catch {
                    Write-Error "Failed to process release ${releaseName}: $_"
                    Write-Output "Error details: $($_.Exception.Response.Content)"
                }
            } else {
                Write-Error "Invalid release ID: $releaseId"
            }
        }
    }

    Write-Output "All pipelines, releases, and repositories have been processed."
} catch {
    Write-Error "An error occurred: $_"
}