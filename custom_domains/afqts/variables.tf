variable "zone" {}
variable "front_door_name" {}
variable "resource_group_name" {}
variable "domains" {}
variable "environment_tag" {}
variable "environment_short" {}
variable "redirect_rules" {
  default = {}
}
variable "origin_hostname" {}

locals {
  hostname = "${var.domains[0]}.${var.zone}"
}
