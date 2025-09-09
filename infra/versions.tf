
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.32"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.32"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
