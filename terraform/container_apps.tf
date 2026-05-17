resource "azurerm_monitor_action_group" "main" {
  name                = "${var.project_name}-${var.environment}-ag"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = substr("${var.project_name}-${var.environment}", 0, 12)
  tags                = azurerm_resource_group.main.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018" # Free tier: 5GB/month
  retention_in_days   = var.environment == "prod" ? 90 : 30
  tags                = azurerm_resource_group.main.tags
}

resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-${var.environment}-ai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  tags                = azurerm_resource_group.main.tags
}

resource "azurerm_container_app_environment" "main" {
  name                           = "${var.project_name}-${var.environment}-cae"
  location                       = azurerm_resource_group.main.location
  resource_group_name            = azurerm_resource_group.main.name
  infrastructure_subnet_id       = azurerm_subnet.container_apps.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  internal_load_balancer_enabled = false
  tags                           = azurerm_resource_group.main.tags
}

resource "azurerm_container_app" "main" {
  name                         = "${var.project_name}-${var.environment}-app"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = azurerm_resource_group.main.tags

  template {
    container {
      name   = var.project_name
      image  = var.container_image
      cpu    = var.app_cpu
      memory = var.app_memory

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }

      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_DATABASE"
        value = var.db_name
      }

      env {
        name        = "DB_USERNAME"
        secret_name = "db-username"
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }

      env {
        name  = "DB_SSL_REQUIRE"
        value = "true"
      }

      liveness_probe {
        http_get {
          path   = "/health"
          port   = 8080
          scheme = "HTTP"
        }
        initial_delay = 15
        interval_seconds = 10
      }

      readiness_probe {
        http_get {
          path   = "/ready"
          port   = 8080
          scheme = "HTTP"
        }
        initial_delay = 10
        interval_seconds = 5
      }
    }

    revision_suffix = "v1"
  }

  scale {
    min_replicas = var.app_min_replicas
    max_replicas = var.app_max_replicas

    rules {
      name = "http"
      http {
        metadata {
          concurrency_target = var.app_concurrent_requests
        }
      }
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 8080
    transport                  = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  secret {
    name  = "db-username"
    value = var.db_admin_username
  }

  secret {
    name  = "db-password"
    value = var.db_admin_password
  }

  registry {
    server            = azurerm_container_registry.main.login_server
    username          = azurerm_container_registry.main.admin_username
    password_secret_ref = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.main.admin_password
  }
}
