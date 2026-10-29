variable "name" {
  description = "Name of the DynamoDB table."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{3,255}$", var.name))
    error_message = "name must be 3-255 characters of letters, numbers, underscores, dots or hyphens (DynamoDB naming rules)."
  }
}

variable "hash_key" {
  description = "Partition key: attribute name and type (S, N or B)."
  type = object({
    name = string
    type = string
  })

  validation {
    condition     = contains(["S", "N", "B"], var.hash_key.type)
    error_message = "hash_key.type must be S, N or B."
  }
}

variable "range_key" {
  description = "Optional sort key: attribute name and type (S, N or B)."
  type = object({
    name = string
    type = string
  })
  default = null

  validation {
    condition     = var.range_key == null || contains(["S", "N", "B"], try(var.range_key.type, ""))
    error_message = "range_key.type must be S, N or B."
  }
}

variable "attributes" {
  description = "Additional attribute definitions, needed only for keys used by secondary indexes. Key attributes are added automatically."
  type = list(object({
    name = string
    type = string
  }))
  default = []

  validation {
    condition     = alltrue([for a in var.attributes : contains(["S", "N", "B"], a.type)])
    error_message = "Every attribute type must be S, N or B."
  }
}

variable "global_secondary_indexes" {
  description = "Global secondary indexes. Every key named here must appear in attributes (or be a table key). Capacities are only used in PROVISIONED mode."
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = optional(string, "ALL")
    non_key_attributes = optional(list(string))
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  default = []

  validation {
    condition     = alltrue([for g in var.global_secondary_indexes : contains(["ALL", "KEYS_ONLY", "INCLUDE"], g.projection_type)])
    error_message = "projection_type must be ALL, KEYS_ONLY or INCLUDE."
  }
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST (on-demand) or PROVISIONED. On-demand is the default: no capacity planning and no throttling surprises for spiky, low-volume tables."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }

  validation {
    condition     = var.billing_mode != "PROVISIONED" || (var.read_capacity != null && var.write_capacity != null)
    error_message = "PROVISIONED billing requires read_capacity and write_capacity."
  }
}

variable "read_capacity" {
  description = "Provisioned read capacity units. Required (and only used) when billing_mode is PROVISIONED."
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "Provisioned write capacity units. Required (and only used) when billing_mode is PROVISIONED."
  type        = number
  default     = null
}

variable "table_class" {
  description = "STANDARD or STANDARD_INFREQUENT_ACCESS."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.table_class)
    error_message = "table_class must be STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
}

variable "point_in_time_recovery_enabled" {
  description = "Enable continuous backups with point-in-time recovery."
  type        = bool
  default     = true
}

variable "deletion_protection_enabled" {
  description = "Refuse to delete the table until this is switched off. Protects against a bad plan taking the data with it."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key for server-side encryption. When null the table is still encrypted, with the AWS-owned key."
  type        = string
  default     = null
}

variable "ttl_attribute_name" {
  description = "Attribute holding an epoch-seconds expiry. When null, TTL is disabled."
  type        = string
  default     = null
}

variable "stream_view_type" {
  description = "Enable DynamoDB Streams with this view type (KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES). null disables streams."
  type        = string
  default     = null

  validation {
    condition     = var.stream_view_type == null || contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], coalesce(var.stream_view_type, "KEYS_ONLY"))
    error_message = "stream_view_type must be KEYS_ONLY, NEW_IMAGE, OLD_IMAGE or NEW_AND_OLD_IMAGES."
  }
}

variable "tags" {
  description = "Tags to apply to the table."
  type        = map(string)
  default     = {}
}
