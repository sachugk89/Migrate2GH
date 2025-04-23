# Define variables
$adoPipelinesDir = Read-Host "Enter the path to the directory containing ADO pipeline YAML files"
$githubWorkflowsDir = Read-Host "Enter the path to the GitHub workflows directory (e.g., .github\workflows)"

# Ensure the GitHub workflows directory exists
if (-not (Test-Path -Path $githubWorkflowsDir)) {
    New-Item -ItemType Directory -Path $githubWorkflowsDir -Force | Out-Null
    Write-Output "Created GitHub workflows directory: $githubWorkflowsDir"
}

# Function to transform ADO pipeline YAML to GitHub workflow YAML
function Transform-ADOPipelineToGitHubWorkflow {
    param (
        [string]$adoPipelinePath,
        [string]$githubWorkflowPath
    )

    try {
        # Read the ADO pipeline YAML file
        $adoPipeline = Get-Content -Path $adoPipelinePath -Raw | ConvertFrom-Yaml

        # Initialize the GitHub workflow structure
        $githubWorkflow = @{
            name = $adoPipeline.name
            on = @{
                push = @{
                    branches = @("main")
                }
                pull_request = @{
                    branches = @("main")
                }
            }
            jobs = @{}
        }

        # Transform ADO pipeline stages into GitHub workflow jobs
        foreach ($stage in $adoPipeline.stages) {
            $jobName = $stage.name
            $githubWorkflow.jobs.$jobName = @{}
            $githubWorkflow.jobs.$jobName["runs-on"] = "ubuntu-latest"
            $githubWorkflow.jobs.$jobName.steps = @()

            foreach ($step in $stage.steps) {
                $githubStep = @{}

                # Transform common ADO actions into GitHub Actions steps
                if ($step.task -eq "Checkout") {
                    $githubStep = @{
                        name = "Checkout Code"
                        uses = "actions/checkout@v4"
                    }
                } elseif ($step.task -eq "UseNode") {
                    $githubStep = @{
                        name = "Setup Node.js"
                        uses = "actions/setup-node@v3"
                        with = @{
                            "node-version" = $step.inputs["nodeVersion"]
                        }
                    }
                } elseif ($step.task -eq "UsePython") {
                    $githubStep = @{
                        name = "Setup Python"
                        uses = "actions/setup-python@v4"
                        with = @{
                            "python-version" = $step.inputs["pythonVersion"]
                        }
                    }
                } elseif ($step.task -eq "RunScript") {
                    $githubStep = @{
                        name = $step.displayName
                        run = $step.script
                    }
                } else {
                    # Default transformation for unrecognized tasks
                    $githubStep = @{
                        name = $step.displayName
                        run = $step.script
                    }
                }

                $githubWorkflow.jobs.$jobName.steps += $githubStep
            }
        }

        # Convert the GitHub workflow structure to YAML and save it
        $githubWorkflow | ConvertTo-Yaml | Out-File -FilePath $githubWorkflowPath
        Write-Output "Transformed ADO pipeline to GitHub workflow: $githubWorkflowPath"
    } catch {
        Write-Error "Failed to transform ADO pipeline: $_"
    }
}

# Process each ADO pipeline YAML file in the directory
$adoPipelineFiles = Get-ChildItem -Path $adoPipelinesDir -Filter *.yml
foreach ($adoPipelineFile in $adoPipelineFiles) {
    $adoPipelinePath = $adoPipelineFile.FullName
    $githubWorkflowPath = Join-Path -Path $githubWorkflowsDir -ChildPath ($adoPipelineFile.BaseName + "-workflow.yml")

    Transform-ADOPipelineToGitHubWorkflow -adoPipelinePath $adoPipelinePath -githubWorkflowPath $githubWorkflowPath
}

Write-Output "All ADO pipelines have been transformed into GitHub workflows."