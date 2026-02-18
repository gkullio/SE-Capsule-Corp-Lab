# Generate random text for unique storage account names
resource "random_id" "storage" {
  for_each    = var.sites
  byte_length = 4
}

# Create storage accounts for boot diagnostics
resource "azurerm_storage_account" "storage" {
  for_each                        = var.sites
  name                            = "diag${random_id.storage[each.key].hex}"
  location                        = each.value.location
  resource_group_name             = each.value.rg_name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
}

