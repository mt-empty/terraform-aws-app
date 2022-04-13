

# terraform-aws

- [terraform-aws](#terraform-aws)
  - [Repository Setup](#repository-setup)
    - [Running pre-commit hooks manually](#running-pre-commit-hooks-manually)
    - [Architecture](#architecture)
  - [3 backend deployment options](#3-backend-deployment-options)
    - [AWS Cloudformation](#aws-cloudformation)
    - [Terraform](#terraform)
      - [TODO:](#todo)
    - [Terraform using serverless modules](#terraform-using-serverless-modules)
  - [Frontend](#frontend)


## Repository Setup

Before you commit, please configure pre-commit with:

`pre-commit install`

### Running pre-commit hooks manually

`pre-commit run --all-files`

### Architecture

![](./architecture.png)


## 3 backend deployment options

### AWS Cloudformation

Completed

### Terraform

Everything from scratch using only providers modules(without importing community modules)

#### TODO:
- [ ] follow [terraform naming convention](https://www.terraform-best-practices.com/naming)
- [ ] Cognito authorization

### Terraform using serverless modules

Work in progress

## Frontend

Work in progress
