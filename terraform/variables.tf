variable "project_name" {
  description = "Project name"
  type        = string
  default     = "kube-news"
}

variable "environment" {
  description = "Environment name (dev/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "container_image" {
  description = "Container image URI"
  type        = string
}

variable "db_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  sensitive   = true
}

variable "db_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "kubedevnews"
}

variable "app_replicas" {
  description = "Number of replicas for the app"
  type        = number
  validation {
    condition     = var.app_replicas >= 1 && var.app_replicas <= 10
    error_message = "App replicas must be between 1 and 10."
  }
}

variable "app_cpu" {
  description = "CPU allocation for the app (0.25, 0.5, 0.75, 1.0, etc)"
  type        = string
  default     = "0.25"
}

variable "app_memory" {
  description = "Memory allocation for the app (0.5Gi, 1Gi, 1.5Gi, 2Gi, etc)"
  type        = string
  default     = "0.5Gi"
}

variable "db_sku_name" {
  description = "PostgreSQL SKU (B_Standard_B1ms, B_Standard_B2s, etc)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

variable "backup_retention_days" {
  description = "Database backup retention in days"
  type        = number
  default     = 7
}

variable "enable_public_endpoint" {
  description = "Enable public endpoint for PostgreSQL"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
