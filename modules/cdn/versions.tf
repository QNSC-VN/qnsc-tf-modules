# Shared modules declare their own provider requirements so consumers get a
# clear constraint rather than relying on the root module's configuration.
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
