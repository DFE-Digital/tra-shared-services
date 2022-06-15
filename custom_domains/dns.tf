module "dns" {
    # depends_on = [azurerm_resource_group.dns]
    source = "git::https://github.com/DFE-Digital/bat-infrastructure.git//dns/zones?ref=556-spike-azure-dns-front-door"
    hosted_zone = var.hosted_zone
}
