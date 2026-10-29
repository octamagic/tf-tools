variable "name" {
  description = "Name of the ECS service."
  type        = string
}

variable "family" {
  description = "Task definition family. Defaults to the service name when null."
  type        = string
  default     = null
}

variable "cluster_arn" {
  description = "ARN (or name) of the ECS cluster to run in."
  type        = string
}

variable "container_definitions" {
  description = "Container definitions as a JSON string (e.g. via jsonencode([...]))."
  type        = string
}

variable "launch_type" {
  description = "Launch type: FARGATE or EC2."
  type        = string
  default     = "FARGATE"

  validation {
    condition     = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "launch_type must be FARGATE or EC2."
  }
}

variable "cpu" {
  description = "Task-level CPU units (e.g. \"256\", \"512\", \"1024\")."
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Task-level memory in MiB (e.g. \"512\", \"1024\")."
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of task copies to run."
  type        = number
  default     = 1
}

variable "execution_role_arn" {
  description = "Task execution role ARN (pulls images, writes logs)."
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "Task role ARN (permissions for the application)."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnets for the awsvpc network interface."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups for the awsvpc network interface."
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign a public IP to tasks (needed for public-subnet Fargate without NAT)."
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "Optional ALB/NLB target group ARN to register tasks with."
  type        = string
  default     = null
}

variable "lb_container_name" {
  description = "Container name to attach to the load balancer (required with target_group_arn)."
  type        = string
  default     = null
}

variable "lb_container_port" {
  description = "Container port to attach to the load balancer (required with target_group_arn)."
  type        = number
  default     = null
}

variable "cpu_architecture" {
  description = "CPU architecture of the task: X86_64 or ARM64. Must match the image; ARM64 (Graviton) is cheaper for images built for it."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}

variable "operating_system_family" {
  description = "Operating system family of the task, e.g. LINUX or WINDOWS_SERVER_2022_CORE."
  type        = string
  default     = "LINUX"
}

variable "deployment_circuit_breaker" {
  description = "Stop a deployment whose tasks keep failing to start or pass health checks, and roll back to the last working task definition."
  type = object({
    enable   = optional(bool, true)
    rollback = optional(bool, true)
  })
  default = {}
}

variable "enable_execute_command" {
  description = "Enable ECS Exec (SSM) for the service."
  type        = bool
  default     = false
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployments."
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Maximum percent during deployments."
  type        = number
  default     = 200
}

variable "tags" {
  description = "Tags to apply to the service and task definition."
  type        = map(string)
  default     = {}
}

variable "track_latest_task_definition" {
  description = "Run whichever ACTIVE revision of the task family is newest, whether Terraform or a deploy pipeline registered it. Lets CI roll a new image by registering a revision without the next apply reverting it; Terraform still wins whenever it registers a newer revision itself."
  type        = bool
  default     = false
}
