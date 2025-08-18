# Cloudflare DNS with Terraform

This repository manages DNS records for various domains on Cloudflare using Terraform. It is designed to be a "DNS as Code" solution, leveraging Terraform Cloud for state management and GitHub Actions for a CI/CD workflow.


## Overview

The core idea is to define all DNS records in Terraform configuration files and use a Git-based workflow (pull requests) to review and apply changes. This provides a versioned history of all DNS modifications.

## Repository Structure

`dns.tf`: The main file containing all DNS record definitions (`cloudflare_record` resources).
`provider.tf`: Configures the Cloudflare provider and the Terraform Cloud backend for remote state storage.
`variables.tf`: Defines the variables used in the configuration, such as domain names or zone IDs.
`domains.tf` - a list of domains that a exist in the cloudflare account
`.github/workflows/`: Contains the GitHub Actions workflow definitions for CI/CD.

## Workflow

1.  **Create a Branch**: Create a new branch for your DNS changes (e.g., `feature/add-new-record`).
2.  **Add/Modify DNS Records**: Edit the `dns.tf` file to add, remove, or modify records.
3.  **Commit and Push**: Commit your changes and push the branch to GitHub.
4.  **Create a Pull Request**: Open a pull request targeting the `main` branch.
5.  **Review Plan**: GitHub Actions will automatically run `terraform plan` and post the output as a comment on the pull request. Review this plan to ensure the changes are correct.
6.  **Merge**: Once the plan is approved, merge the pull request into `main`.
7.  **Apply**: Upon merging, GitHub Actions will trigger a `terraform apply` to deploy the changes to Cloudflare.

## Local Usage

While the primary workflow is automated, you can run commands locally.

## Local Usage

While the primary workflow is automated, you can run commands locally.

1.  **Login to Terraform Cloud**:
    ```bash
    terraform login
    ```
2.  **Initialize Terraform**:
    ```bash
    terraform init
    ```
3.  **Run a Plan**:
    ```bash
    terraform plan
    ```