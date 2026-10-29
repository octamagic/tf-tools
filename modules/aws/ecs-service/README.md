# `aws/ecs-service`

A Fargate (or EC2) ECS service plus its task definition. You bring the cluster, networking,
and IAM roles (compose with `aws/iam-role`); this module runs your containers.

Container definitions are passed as a JSON string (the standard escape hatch) so you keep
full control of the container spec.

Deployments use the ECS circuit breaker with rollback by default, so a release whose tasks
cannot start or fail their health checks is rolled back to the previous task definition
instead of looping forever. The task's CPU architecture defaults to `X86_64`; set
`cpu_architecture = "ARM64"` for images built for Graviton.

## Usage

Set `track_latest_task_definition = true` when a deploy pipeline registers new task
definition revisions (for example an ECS deploy action swapping the image). The service
then follows the newest ACTIVE revision, so Terraform does not roll a deploy back on its
next apply, while a revision Terraform registers itself still wins because it is newer.


```hcl
module "api" {
  source = "../../modules/aws/ecs-service"

  name        = "orders-api"
  cluster_arn = aws_ecs_cluster.main.arn

  cpu    = "512"
  memory = "1024"

  execution_role_arn = module.execution_role.arn
  task_role_arn      = module.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/orders:latest"
      essential = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/orders-api"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.api.id]

  target_group_arn  = aws_lb_target_group.api.arn
  lb_container_name = "app"
  lb_container_port = 8080

  desired_count = 3
  tags          = { Team = "platform" }
}
```

See [`examples/basic`](examples/basic) for a runnable example.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.40 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.58.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_task_definition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP to tasks (needed for public-subnet Fargate without NAT). | `bool` | `false` | no |
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | ARN (or name) of the ECS cluster to run in. | `string` | n/a | yes |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | Container definitions as a JSON string (e.g. via jsonencode([...])). | `string` | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Task-level CPU units (e.g. "256", "512", "1024"). | `string` | `"256"` | no |
| <a name="input_cpu_architecture"></a> [cpu\_architecture](#input\_cpu\_architecture) | CPU architecture of the task: X86\_64 or ARM64. Must match the image; ARM64 (Graviton) is cheaper for images built for it. | `string` | `"X86_64"` | no |
| <a name="input_deployment_circuit_breaker"></a> [deployment\_circuit\_breaker](#input\_deployment\_circuit\_breaker) | Stop a deployment whose tasks keep failing to start or pass health checks, and roll back to the last working task definition. | <pre>object({<br/>    enable   = optional(bool, true)<br/>    rollback = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | Maximum percent during deployments. | `number` | `200` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | Minimum healthy percent during deployments. | `number` | `100` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Number of task copies to run. | `number` | `1` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Enable ECS Exec (SSM) for the service. | `bool` | `false` | no |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | Task execution role ARN (pulls images, writes logs). | `string` | `null` | no |
| <a name="input_family"></a> [family](#input\_family) | Task definition family. Defaults to the service name when null. | `string` | `null` | no |
| <a name="input_launch_type"></a> [launch\_type](#input\_launch\_type) | Launch type: FARGATE or EC2. | `string` | `"FARGATE"` | no |
| <a name="input_lb_container_name"></a> [lb\_container\_name](#input\_lb\_container\_name) | Container name to attach to the load balancer (required with target\_group\_arn). | `string` | `null` | no |
| <a name="input_lb_container_port"></a> [lb\_container\_port](#input\_lb\_container\_port) | Container port to attach to the load balancer (required with target\_group\_arn). | `number` | `null` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Task-level memory in MiB (e.g. "512", "1024"). | `string` | `"512"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the ECS service. | `string` | n/a | yes |
| <a name="input_operating_system_family"></a> [operating\_system\_family](#input\_operating\_system\_family) | Operating system family of the task, e.g. LINUX or WINDOWS\_SERVER\_2022\_CORE. | `string` | `"LINUX"` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Security groups for the awsvpc network interface. | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnets for the awsvpc network interface. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the service and task definition. | `map(string)` | `{}` | no |
| <a name="input_target_group_arn"></a> [target\_group\_arn](#input\_target\_group\_arn) | Optional ALB/NLB target group ARN to register tasks with. | `string` | `null` | no |
| <a name="input_task_role_arn"></a> [task\_role\_arn](#input\_task\_role\_arn) | Task role ARN (permissions for the application). | `string` | `null` | no |
| <a name="input_track_latest_task_definition"></a> [track\_latest\_task\_definition](#input\_track\_latest\_task\_definition) | Run whichever ACTIVE revision of the task family is newest, whether Terraform or a deploy pipeline registered it. Lets CI roll a new image by registering a revision without the next apply reverting it; Terraform still wins whenever it registers a newer revision itself. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | ID/ARN of the ECS service. |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the ECS service. |
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | ARN of the task definition (current revision). |
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | Task definition family. |
| <a name="output_task_definition_revision"></a> [task\_definition\_revision](#output\_task\_definition\_revision) | Current task definition revision number. |
<!-- END_TF_DOCS -->
