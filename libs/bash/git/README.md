# Git Hooks

## Functions, Purpose, and Overrides

### createTmpDir

Creates a working directory to store toolchain-management project, scan reports, or other output artifacts.

### doNotAllowSharedModulesInsideDeploymentProjects

We do not want to allow references to TF modules via local file system.

`export WL_TF_MODULE_DEV=true` Skip module source checks. For use when creating/update/upgrading module source code.

### documentation

Generates module API documentation, appends to README in the directory

### generateSBOM

Create software-bill-of-materials for use with compliance and security scanning processes.

### terraformCompliance

Execute Terraform / IaC community best practices and security configurations.

- checkov
- kics
- trivy
- and so on. The more, the better.

### terraformLinting

- Styling and layout adjustments per vendor recommendations. 
