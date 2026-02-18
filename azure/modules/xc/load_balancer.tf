resource "volterra_http_loadbalancer" "appProxy" {
  name      = "${var.se_namespace}-capsule-corp-main-page"
  namespace = var.se_namespace

  advertise_on_public_default_vip = true
  disable_api_definition          = true
  no_challenge                    = true

  domains = ["${var.se_namespace}-cap-corp-main.${var.delegated_dns_domain}"]
  
  source_ip_stickiness = true

  ############### Uncomment this section if you want to use HTTPS Auto Cert ################
  ############### Then comment out the http block ################
  https_auto_cert {
    add_hsts             = true
    default_loadbalancer = false
    port                 = "443"
    http_redirect        = true
  }

  ############### Attach a Default Pool to the Load Balancer ################
  default_route_pools {
    pool {
      namespace = var.se_namespace
      name      = volterra_origin_pool.capsule_corp_main-pub.name
    }
  }
  ############################################################################

  enable_malicious_user_detection = false
  service_policies_from_namespace = false
  disable_trust_client_ip_headers = true
  user_id_client_ip               = true

  disable_client_side_defense = true

  disable_bot_defense = true
  enable_threat_mesh  = false

  more_option {
    request_headers_to_add {
      name   = "geo-country"
      value  = "$[geoip_country]"
      append = false
    }
    request_headers_to_add {
      name   = "Access-Control-Allow-Origin"
      value  = "*"
      append = false
    }
  }/*
  routes {
    simple_route {
      http_method = "ANY"
      path {
        prefix = "/"
      }
      headers {
        name  = "Host"
        exact = "${var.my_name}-juice.${var.delegated_dns_domain}"
      }
      origin_pools {
        pool {
          namespace = var.namespace
          name      = volterra_origin_pool.juice_origin.name
        }
        weight   = 1
        priority = 1
      }
    }
  }
  routes {
    simple_route {
      http_method = "ANY"
      path {
        prefix = "/"
      }
      headers {
        name  = "Host"
        exact = "${var.my_name}-dvwa.${var.delegated_dns_domain}"
      }
      origin_pools {
        pool {
          namespace = var.namespace
          name      = volterra_origin_pool.dvwa_origin.name
        }
        weight   = 1
        priority = 1
      }
    }
  }
  routes {
    simple_route {
      http_method = "ANY"
      path {
        prefix = "/"
      }
      headers {
        name  = "Host"
        exact = "${var.my_name}-demoapp.${var.delegated_dns_domain}"
      }
      origin_pools {
        pool {
          namespace = var.namespace
          name      = volterra_origin_pool.demoapp_origin.name
        }
        weight   = 1
        priority = 1
      }
    }
  }*/
}

