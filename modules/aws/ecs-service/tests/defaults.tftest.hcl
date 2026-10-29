# `terraform test` suite for aws/ecs-service. Runs against a mocked AWS provider,
# so it needs no credentials and creates nothing. See docs/TESTING.md.

mock_provider "aws" {}

variables {
  name        = "tf-tools-test-service"
  cluster_arn = "arn:aws:ecs:us-east-1:111122223333:cluster/example"
  subnet_ids  = ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]
  container_definitions = jsonencode([
    { name = "app", image = "nginx:latest", essential = true }
  ])
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = one(aws_ecs_service.this.deployment_circuit_breaker).enable && one(aws_ecs_service.this.deployment_circuit_breaker).rollback
    error_message = "The deployment circuit breaker with rollback must be on by default; without it a broken release keeps launching failing tasks until someone notices."
  }

  assert {
    condition     = one(aws_ecs_service.this.network_configuration).assign_public_ip == false
    error_message = "Tasks must not get public IPs by default; reach them through a load balancer."
  }

  assert {
    condition     = aws_ecs_service.this.enable_execute_command == false
    error_message = "ECS Exec must be opt-in; it is an interactive shell into production containers."
  }

  assert {
    condition     = one(aws_ecs_task_definition.this.runtime_platform).cpu_architecture == "X86_64" && one(aws_ecs_task_definition.this.runtime_platform).operating_system_family == "LINUX"
    error_message = "The runtime platform must default to Linux on X86_64, which matches images built without an explicit target."
  }

  assert {
    condition     = aws_ecs_task_definition.this.network_mode == "awsvpc"
    error_message = "Fargate tasks require awsvpc networking."
  }

  assert {
    condition     = length(aws_ecs_service.this.load_balancer) == 0
    error_message = "No load balancer block should be created unless a target group is supplied."
  }
}

run "arm64_and_circuit_breaker_off_are_wired" {
  command = plan

  variables {
    cpu_architecture           = "ARM64"
    deployment_circuit_breaker = { enable = false, rollback = false }
  }

  assert {
    condition     = one(aws_ecs_task_definition.this.runtime_platform).cpu_architecture == "ARM64"
    error_message = "cpu_architecture must reach the task definition."
  }

  assert {
    condition     = one(aws_ecs_service.this.deployment_circuit_breaker).enable == false
    error_message = "The circuit breaker must be switchable off for callers that manage rollbacks themselves."
  }
}

run "load_balancer_is_wired" {
  command = plan

  variables {
    target_group_arn  = "arn:aws:elasticloadbalancing:us-east-1:111122223333:targetgroup/example/0123456789abcdef"
    lb_container_name = "app"
    lb_container_port = 8080
  }

  assert {
    condition     = one(aws_ecs_service.this.load_balancer).container_port == 8080 && one(aws_ecs_service.this.load_balancer).container_name == "app"
    error_message = "A supplied target group must register the named container and port."
  }
}

# --- input validation -------------------------------------------------------

run "rejects_unknown_launch_type" {
  command = plan
  variables {
    launch_type = "EXTERNAL"
  }
  expect_failures = [var.launch_type]
}

run "rejects_unknown_cpu_architecture" {
  command = plan
  variables {
    cpu_architecture = "RISCV"
  }
  expect_failures = [var.cpu_architecture]
}

run "rejects_target_group_without_container" {
  command = plan
  variables {
    target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:111122223333:targetgroup/example/0123456789abcdef"
  }
  expect_failures = [aws_ecs_service.this]
}

run "latest_revision_tracking_is_opt_in" {
  command = plan

  assert {
    condition     = length(data.aws_ecs_task_definition.latest) == 0
    error_message = "Without track_latest_task_definition the service must pin Terraform's own task definition and not read the live family."
  }
}

run "latest_revision_tracking_reads_the_live_family" {
  command = plan

  variables {
    track_latest_task_definition = true
  }

  assert {
    condition     = length(data.aws_ecs_task_definition.latest) == 1
    error_message = "track_latest_task_definition must read the family's newest ACTIVE revision so pipeline-registered revisions survive the next apply."
  }
}
