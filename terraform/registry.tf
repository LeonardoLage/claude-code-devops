resource "azurerm_container_registry" "main" {
  name                = replace("${var.project_name}${var.environment}acr", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic" # Free tier for 12 months
  admin_enabled       = true
  tags                = azurerm_resource_group.main.tags
}
