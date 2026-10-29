# `aws/dynamodb-table`

A DynamoDB table with the safe defaults turned on: on-demand billing, point-in-time
recovery, server-side encryption and deletion protection. Keys are declared as attributes
for you; extra attributes are only needed for secondary-index keys.

## Usage

Key-value table with a sort key:

```hcl
module "user_settings" {
  source = "../../modules/aws/dynamodb-table"

  name      = "user-settings"
  hash_key  = { name = "pk", type = "S" }
  range_key = { name = "sk", type = "S" }

  tags = { Team = "platform" }
}
```

With a global secondary index, TTL and a customer-managed key:

```hcl
module "sessions" {
  source = "../../modules/aws/dynamodb-table"

  name      = "sessions"
  hash_key  = { name = "session_id", type = "S" }
  range_key = { name = "created_at", type = "N" }

  attributes = [{ name = "user_id", type = "S" }]
  global_secondary_indexes = [{
    name      = "by-user"
    hash_key  = "user_id"
    range_key = "created_at"
  }]

  ttl_attribute_name = "expires_at"
  kms_key_arn        = aws_kms_key.data.arn
}
```

Grant application roles access to `module.<name>.arn` and, when they query an index,
`"${module.<name>.arn}/index/*"`.

See [`examples/basic`](examples/basic) for a runnable example.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.40 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.71.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Additional attribute definitions, needed only for keys used by secondary indexes. Key attributes are added automatically. | <pre>list(object({<br/>    name = string<br/>    type = string<br/>  }))</pre> | `[]` | no |
| <a name="input_billing_mode"></a> [billing\_mode](#input\_billing\_mode) | PAY\_PER\_REQUEST (on-demand) or PROVISIONED. On-demand is the default: no capacity planning and no throttling surprises for spiky, low-volume tables. | `string` | `"PAY_PER_REQUEST"` | no |
| <a name="input_deletion_protection_enabled"></a> [deletion\_protection\_enabled](#input\_deletion\_protection\_enabled) | Refuse to delete the table until this is switched off. Protects against a bad plan taking the data with it. | `bool` | `true` | no |
| <a name="input_global_secondary_indexes"></a> [global\_secondary\_indexes](#input\_global\_secondary\_indexes) | Global secondary indexes. Every key named here must appear in attributes (or be a table key). Capacities are only used in PROVISIONED mode. | <pre>list(object({<br/>    name               = string<br/>    hash_key           = string<br/>    range_key          = optional(string)<br/>    projection_type    = optional(string, "ALL")<br/>    non_key_attributes = optional(list(string))<br/>    read_capacity      = optional(number)<br/>    write_capacity     = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_hash_key"></a> [hash\_key](#input\_hash\_key) | Partition key: attribute name and type (S, N or B). | <pre>object({<br/>    name = string<br/>    type = string<br/>  })</pre> | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key for server-side encryption. When null the table is still encrypted, with the AWS-owned key. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the DynamoDB table. | `string` | n/a | yes |
| <a name="input_point_in_time_recovery_enabled"></a> [point\_in\_time\_recovery\_enabled](#input\_point\_in\_time\_recovery\_enabled) | Enable continuous backups with point-in-time recovery. | `bool` | `true` | no |
| <a name="input_range_key"></a> [range\_key](#input\_range\_key) | Optional sort key: attribute name and type (S, N or B). | <pre>object({<br/>    name = string<br/>    type = string<br/>  })</pre> | `null` | no |
| <a name="input_read_capacity"></a> [read\_capacity](#input\_read\_capacity) | Provisioned read capacity units. Required (and only used) when billing\_mode is PROVISIONED. | `number` | `null` | no |
| <a name="input_stream_view_type"></a> [stream\_view\_type](#input\_stream\_view\_type) | Enable DynamoDB Streams with this view type (KEYS\_ONLY, NEW\_IMAGE, OLD\_IMAGE, NEW\_AND\_OLD\_IMAGES). null disables streams. | `string` | `null` | no |
| <a name="input_table_class"></a> [table\_class](#input\_table\_class) | STANDARD or STANDARD\_INFREQUENT\_ACCESS. | `string` | `"STANDARD"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the table. | `map(string)` | `{}` | no |
| <a name="input_ttl_attribute_name"></a> [ttl\_attribute\_name](#input\_ttl\_attribute\_name) | Attribute holding an epoch-seconds expiry. When null, TTL is disabled. | `string` | `null` | no |
| <a name="input_write_capacity"></a> [write\_capacity](#input\_write\_capacity) | Provisioned write capacity units. Required (and only used) when billing\_mode is PROVISIONED. | `number` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the table. Grant application roles access to this and, for index queries, to "<arn>/index/*". |
| <a name="output_id"></a> [id](#output\_id) | ID (name) of the table. |
| <a name="output_name"></a> [name](#output\_name) | Name of the table. |
| <a name="output_stream_arn"></a> [stream\_arn](#output\_stream\_arn) | ARN of the table stream, or null when streams are disabled. |
<!-- END_TF_DOCS -->
