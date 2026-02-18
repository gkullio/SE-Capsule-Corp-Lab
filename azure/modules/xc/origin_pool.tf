resource "volterra_origin_pool" "capsule_corp_main" {
  name                   = "${var.se_namespace}-capsule-corp-main-pool"
  namespace              = var.se_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"

  origin_servers {
    private_ip {
      ip = "10.245.0.4"
      site_locator {
      site {
        name = module.smsv2.us_site_name
      }
    }
    inside_network = true
  }
}
  port = 8080
  no_tls = true
}

