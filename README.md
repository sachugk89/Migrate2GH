# Migrate2GH
# Documentation for `ado2gh.yml` and `ghactionimporter.yml`

## `ado2gh.yml`

This YAML configuration file is used to define the parameters and settings for migrating Azure DevOps pipelines to GitHub Actions. It serves as an input to the migration process, specifying the source Azure DevOps project and repository, as well as the target GitHub repository.

### Key Parameters:
- **source_project**: The name of the Azure DevOps project containing the pipelines to be migrated.
- **source_repo**: The name of the Azure DevOps repository containing the pipeline definitions.
- **target_repo**: The name of the GitHub repository where the pipelines will be migrated.
- **pipeline_filters**: Optional filters to specify which pipelines to migrate (e.g., by name or tags).
- **authentication**: Credentials or tokens required to access Azure DevOps and GitHub.

### Usage:
1. Populate the `ado2gh.yml` file with the required parameters.
2. Run the migration tool, ensuring it references this configuration file.
3. The tool will use the settings in `ado2gh.yml` to migrate the specified pipelines.

---

## `ghactionimporter.yml`

This YAML configuration file is used to customize the behavior of the GitHub Actions Importer tool. It defines the rules and mappings for converting Azure DevOps pipeline tasks into equivalent GitHub Actions workflows.

### Key Parameters:
- **task_mappings**: Defines how specific Azure DevOps tasks should be translated into GitHub Actions steps.
- **default_branch**: Specifies the default branch for the target GitHub repository.
- **workflow_templates**: References reusable workflow templates to standardize the migration process.
- **logging**: Configures logging levels and output for the importer tool.

### Usage:
1. Configure the `ghactionimporter.yml` file with the desired mappings and settings.
2. Use the GitHub Actions Importer tool, pointing it to this configuration file.
3. The tool will generate GitHub Actions workflows based on the rules defined in `ghactionimporter.yml`.

---

## Adding to `README.md`

To use these configuration files for migrating Azure DevOps pipelines to GitHub Actions, follow these steps:

1. **Prepare Configuration Files**:
    - Create and populate `ado2gh.yml` with the source and target repository details.
    - Define task mappings and workflow settings in `ghactionimporter.yml`.

2. **Run Migration Tools**:
    - Use the Azure DevOps to GitHub migration tool with `ado2gh.yml` to identify and migrate pipelines.
    - Use the GitHub Actions Importer tool with `ghactionimporter.yml` to convert pipelines into GitHub Actions workflows.

3. **Verify and Test**:
    - Review the generated workflows in the target GitHub repository.
    - Test the workflows to ensure they function as expected.

For more details, refer to the official documentation of the migration tools.