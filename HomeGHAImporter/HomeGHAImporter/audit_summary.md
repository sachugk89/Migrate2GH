# Audit summary

Summary for [Azure DevOps instance](https://dev.azure.com/sachugk/MyHealthClinic/_build)

- GitHub Actions Importer version: **1.3.22380 (5857c4329d376f00e242a93eb3264ccafad47e55)**
- Performed at: **4/10/25 at 13:10**

## Pipelines

Total: **1**

- Successful: **1 (100%)**
- Partially successful: **0 (0%)**
- Unsupported: **0 (0%)**
- Failed: **0 (0%)**

### Job types

Supported: **1 (100%)**

- YAML: **1**

### Build steps

Total: **5**

Known: **5 (100%)**

- AzureWebApp@1: **2**
- script: **2**
- NodeTool@0: **1**

Actions: **6**

- run: **2**
- azure/webapps-deploy@v3.0.0: **1**
- azure/login@v1.6.0: **1**
- actions/setup-node@v4.0.0: **1**
- actions/checkout@v4.1.0: **1**

### Triggers

Total: **1**

Known: **1 (100%)**

- continuousIntegration: **1**

Actions: **1**

- push: **1**

### Environment

Total: **0**

### Other

Total: **0**

### Manual tasks

Total: **1**

Secrets: **1**

- `${{ secrets.AZURE_CREDENTIALS }}`: **1**

### Successful

#### MyHealthClinic/nodejsbuild

- [pipelines/MyHealthClinic/nodejsbuild/.github/workflows/nodejsbuild.yml](pipelines/MyHealthClinic/nodejsbuild/.github/workflows/nodejsbuild.yml)
- [pipelines/MyHealthClinic/nodejsbuild/config.json](pipelines/MyHealthClinic/nodejsbuild/config.json)
- [pipelines/MyHealthClinic/nodejsbuild/source.yml](pipelines/MyHealthClinic/nodejsbuild/source.yml)
