module "domains" {
  source              = "git::https://github.com/DFE-Digital/terraform-modules.git//domains/environment_domains"
  zone                = var.zone
  front_door_name     = var.front_door_name
  resource_group_name = var.resource_group_name
  domains             = var.domains
  tags                = local.tags
}

data "azurerm_cdn_frontdoor_profile" "main" {
  name                = var.front_door_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_cdn_frontdoor_rule_set" "ruleset" {
  name                     = var.ruleset_name
  cdn_frontdoor_profile_id = data.azurerm_cdn_frontdoor_profile.main.id
}

# TODO: Create rule
# TODO: Associate rule to route
