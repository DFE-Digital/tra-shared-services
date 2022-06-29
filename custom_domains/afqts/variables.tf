variable "zone" {}
variable "front_door_name" {}
variable "resource_group_name" {}
variable "domains" {}
variable "environment_tag" {}
variable "ruleset_name" {}

locals {
  default_tags = {
    "Parent Business": "Teacher Training and Qualifications",
    "Portfolio": "Early Years and Schools Group",
    "Product": "Database of Qualified Teachers",
    "Service": "Teacher Training and Qualifications",
    "Service Line": "Teaching Workforce",
    "Service Offering": "Database of Qualified Teachers"
  }
  tags = merge(
    local.default_tags,
    { "Environment" = var.environment_tag }
  )
}
