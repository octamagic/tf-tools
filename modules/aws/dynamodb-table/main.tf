locals {
  provisioned = var.billing_mode == "PROVISIONED"

  # Key attributes are always declared; extra attributes exist only for index keys.
  # Deduplicate by name so a caller may list a key attribute again without error.
  key_attributes = concat(
    [var.hash_key],
    var.range_key != null ? [var.range_key] : [],
  )
  attributes = [
    for name, defs in { for a in concat(local.key_attributes, var.attributes) : a.name => a... } : defs[0]
  ]
}

resource "aws_dynamodb_table" "this" {
  name         = var.name
  billing_mode = var.billing_mode
  table_class  = var.table_class

  hash_key  = var.hash_key.name
  range_key = var.range_key != null ? var.range_key.name : null

  read_capacity  = local.provisioned ? var.read_capacity : null
  write_capacity = local.provisioned ? var.write_capacity : null

  dynamic "attribute" {
    for_each = local.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
      read_capacity      = local.provisioned ? global_secondary_index.value.read_capacity : null
      write_capacity     = local.provisioned ? global_secondary_index.value.write_capacity : null
    }
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  # Tables are always encrypted at rest. `enabled = true` selects a customer-managed
  # or AWS-managed KMS key; without it DynamoDB uses the AWS-owned key.
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  dynamic "ttl" {
    for_each = var.ttl_attribute_name != null ? [1] : []
    content {
      attribute_name = var.ttl_attribute_name
      enabled        = true
    }
  }

  stream_enabled   = var.stream_view_type != null
  stream_view_type = var.stream_view_type

  deletion_protection_enabled = var.deletion_protection_enabled

  tags = var.tags
}
