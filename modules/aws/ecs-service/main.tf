locals {
  family = var.family != null ? var.family : var.name

  # With tracking on, follow the newest ACTIVE revision so that revisions
  # registered outside Terraform (a deploy pipeline swapping the image) are not
  # rolled back on the next apply. max() keeps Terraform's own revision when it
  # is the newer one, so config changes still deploy.
  task_definition = (
    var.track_latest_task_definition
    ? "${aws_ecs_task_definition.this.family}:${max(aws_ecs_task_definition.this.revision, data.aws_ecs_task_definition.latest[0].revision)}"
    : aws_ecs_task_definition.this.arn
  )
}

data "aws_ecs_task_definition" "latest" {
  count = var.track_latest_task_definition ? 1 : 0

  task_definition = aws_ecs_task_definition.this.family

  # Defer the read until the family exists; without this the first plan looks
  # the family up before anything has been registered and fails.
  depends_on = [aws_ecs_task_definition.this]
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.family
  requires_compatibilities = [var.launch_type]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  container_definitions    = var.container_definitions

  runtime_platform {
    operating_system_family = var.operating_system_family
    cpu_architecture        = var.cpu_architecture
  }

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_arn
  task_definition = local.task_definition
  desired_count   = var.desired_count
  launch_type     = var.launch_type

  enable_execute_command = var.enable_execute_command

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  deployment_circuit_breaker {
    enable   = var.deployment_circuit_breaker.enable
    rollback = var.deployment_circuit_breaker.rollback
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.lb_container_name
      container_port   = var.lb_container_port
    }
  }

  lifecycle {
    precondition {
      condition     = var.target_group_arn == null || (var.lb_container_name != null && var.lb_container_port != null)
      error_message = "When target_group_arn is set, lb_container_name and lb_container_port are required."
    }
  }

  tags = var.tags
}
