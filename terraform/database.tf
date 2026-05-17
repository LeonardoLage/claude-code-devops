resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-${var.environment}-db"
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  database_charset       = "UTF8"
  database_collation     = "en_US.utf8"

  delegated_subnet_id             = azurerm_subnet.database.id
  private_dns_zone_id             = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled   = var.enable_public_endpoint

  sku_name   = var.db_sku_name
  version    = "15"
  storage_mb = var.db_storage_mb

  backup_retention_days        = var.enable_backup ? var.backup_retention_days : 1
  geo_redundant_backup_enabled = false

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name            = var.db_name
  server_id       = azurerm_postgresql_flexible_server.main.id
  charset         = "UTF8"
  collation       = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_container_apps" {
  name             = "AllowContainerApps"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}
