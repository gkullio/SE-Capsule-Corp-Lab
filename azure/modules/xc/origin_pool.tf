resource "volterra_origin_pool" "capsule_corp_main-pub" {
  name                   = "${var.se_namespace}-capsule-corp-main-pool"
  namespace              = var.se_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"

  origin_servers {
    public_ip {
      ip = var.ubuntu_us_public_ip
    }
}
  port = 8080
  no_tls = true
}

resource "volterra_origin_pool" "capsule_corp_int-pub" {
  name                   = "${var.se_namespace}-capsule-corp-int-pool"
  namespace              = var.se_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"

  origin_servers {
    public_ip {
      ip = var.ubuntu_us_public_ip
    }
}
  port = 8081
  no_tls = true
}