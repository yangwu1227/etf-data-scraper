variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "profile" {
  description = "The AWS credentials profile to use for deployment"
  type        = string
}

variable "stack_name" {
  description = "The name of the stack, used for tagging and resource identification"
  type        = string
}

variable "s3_ecr_terraform_state_bucket" {
  description = "The S3 key of the Terraform state file containing outputs from the ecr and S3 deployments"
  type        = string
}

variable "s3_ecr_terraform_state_key" {
  description = "The S3 key of the Terraform state file containing outputs from the ecr and S3 deployments"
  type        = string
}

variable "github_username" {
  description = "GitHub username"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}
