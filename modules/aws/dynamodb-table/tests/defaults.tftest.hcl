# `terraform test` suite for aws/dynamodb-table. Runs against a mocked AWS
# provider, so it needs no credentials and creates nothing. See docs/TESTING.md.

mock_provider "aws" {}

variables {
  name     = "tf-tools-test-table"
  hash_key = { name = "pk", type = "S" }
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.this.billing_mode == "PAY_PER_REQUEST"
    error_message = "On-demand billing must be the default; provisioned capacity throttles the first traffic spike a new table sees."
  }

  assert {
    condition     = one(aws_dynamodb_table.this.point_in_time_recovery).enabled
    error_message = "Point-in-time recovery must be on by default; it is the only way back from a bad write or an accidental delete."
  }

  assert {
    condition     = aws_dynamodb_table.this.deletion_protection_enabled
    error_message = "Deletion protection must be on by default so a destructive plan cannot take the data with it."
  }

  assert {
    condition     = one(aws_dynamodb_table.this.server_side_encryption).enabled
    error_message = "Server-side encryption must be enabled by default."
  }

  assert {
    condition     = aws_dynamodb_table.this.hash_key == "pk" && length(aws_dynamodb_table.this.attribute) == 1
    error_message = "The partition key must be wired through and declared exactly once as an attribute."
  }

  # stream_enabled, ttl and range_key are not asserted absent here: the provider
  # marks them Optional+Computed, so they read as unknown at plan time. See the
  # "known limits" section of docs/TESTING.md.
}

run "range_key_ttl_and_kms_are_wired" {
  command = plan

  variables {
    range_key          = { name = "sk", type = "S" }
    ttl_attribute_name = "expires_at"
    kms_key_arn        = "arn:aws:kms:us-east-1:111122223333:key/abc"
    stream_view_type   = "NEW_AND_OLD_IMAGES"
  }

  assert {
    condition     = aws_dynamodb_table.this.range_key == "sk" && length(aws_dynamodb_table.this.attribute) == 2
    error_message = "A sort key must be wired through and declared as an attribute."
  }

  assert {
    condition     = one(aws_dynamodb_table.this.ttl).attribute_name == "expires_at" && one(aws_dynamodb_table.this.ttl).enabled
    error_message = "ttl_attribute_name must enable TTL on that attribute."
  }

  assert {
    condition     = one(aws_dynamodb_table.this.server_side_encryption).kms_key_arn == "arn:aws:kms:us-east-1:111122223333:key/abc"
    error_message = "A supplied KMS key must be used for encryption."
  }

  assert {
    condition     = aws_dynamodb_table.this.stream_enabled && aws_dynamodb_table.this.stream_view_type == "NEW_AND_OLD_IMAGES"
    error_message = "stream_view_type must enable streams with that view."
  }
}

run "global_secondary_index_is_wired_and_attributes_deduplicated" {
  command = plan

  variables {
    range_key  = { name = "sk", type = "S" }
    attributes = [{ name = "sk", type = "S" }, { name = "owner", type = "S" }]
    global_secondary_indexes = [{
      name            = "by-owner"
      hash_key        = "owner"
      range_key       = "sk"
      projection_type = "KEYS_ONLY"
    }]
  }

  assert {
    condition     = one(aws_dynamodb_table.this.global_secondary_index).hash_key == "owner" && one(aws_dynamodb_table.this.global_secondary_index).projection_type == "KEYS_ONLY"
    error_message = "A global secondary index must be created with the requested keys and projection."
  }

  assert {
    condition     = length(aws_dynamodb_table.this.attribute) == 3
    error_message = "Attributes must be deduplicated by name: pk, sk and owner, with sk declared once even though the caller repeated it."
  }
}

run "provisioned_capacity_is_wired" {
  command = plan

  variables {
    billing_mode   = "PROVISIONED"
    read_capacity  = 5
    write_capacity = 10
  }

  assert {
    condition     = aws_dynamodb_table.this.read_capacity == 5 && aws_dynamodb_table.this.write_capacity == 10
    error_message = "Provisioned capacities must reach the table in PROVISIONED mode."
  }
}

# --- input validation -------------------------------------------------------

run "rejects_unknown_billing_mode" {
  command = plan
  variables {
    billing_mode = "ON_DEMAND"
  }
  expect_failures = [var.billing_mode]
}

run "rejects_provisioned_without_capacity" {
  command = plan
  variables {
    billing_mode = "PROVISIONED"
  }
  # The cross-variable check lives on var.billing_mode.
  expect_failures = [var.billing_mode]
}

run "rejects_bad_key_type" {
  command = plan
  variables {
    hash_key = { name = "pk", type = "STRING" }
  }
  expect_failures = [var.hash_key]
}
