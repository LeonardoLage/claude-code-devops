output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource Group name"
}

output "environment" {
  value       = var.environment
  description = "Environment name"
}

output "container_app_url" {
  value       = "https://${azurerm_container_app.main.ingress[0].fqdn}"
  description = "Container App FQDN with HTTPS"
}

output "container_app_fqdn" {
  value       = azurerm_container_app.main.ingress[0].fqdn
  description = "Container App FQDN"
}

output "postgres_fqdn" {
  value       = azurerm_postgresql_flexible_server.main.fqdn
  description = "PostgreSQL server FQDN"
}

output "postgres_connection_string" {
  value       = "postgresql://${var.db_admin_username}:****@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.db_name}"
  description = "PostgreSQL connection string (password masked)"
  sensitive   = true
}

output "container_registry_login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "Container Registry login server"
}

output "container_registry_admin_username" {
  value       = azurerm_container_registry.main.admin_username
  description = "Container Registry admin username"
  sensitive   = true
}

output "key_vault_id" {
  value       = azurerm_key_vault.main.id
  description = "Key Vault ID"
}

output "key_vault_name" {
  value       = azurerm_key_vault.main.name
  description = "Key Vault name"
}

output "application_insights_instrumentation_key" {
  value       = azurerm_application_insights.main.instrumentation_key
  description = "Application Insights instrumentation key"
  sensitive   = true
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.main.id
  description = "Log Analytics Workspace ID"
}

output "log_analytics_workspace_name" {
  value       = azurerm_log_analytics_workspace.main.name
  description = "Log Analytics Workspace name"
}
