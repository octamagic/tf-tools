terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

# A single-table design keyed by owner (pk) and item name (sk), with a GSI to
# look items up by their type.
module "settings" {
  source = "../.."

  name      = "example-user-settings"
  hash_key  = { name = "pk", type = "S" }
  range_key = { name = "sk", type = "S" }

  attributes = [{ name = "type", type = "S" }]
  global_secondary_indexes = [{
    name            = "by-type"
    hash_key        = "type"
    range_key       = "sk"
    projection_type = "KEYS_ONLY"
  }]

  tags = {
    Team        = "platform"
    Environment = "example"
  }
}

output "table_arn" {
  description = "ARN of the example table."
  value       = module.settings.arn
}
