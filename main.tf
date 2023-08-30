module "core" {
  source = "./modules/core"
  prefix = "${var.prefix}"
}

module "bastion" {
  source = "./modules/bastion"
  prefix = "${var.prefix}"
}