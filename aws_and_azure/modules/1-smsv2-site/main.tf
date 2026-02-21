locals {
  site_tokens = flatten([
    for site_key, site in var.sites : [
      for i in range(var.instance_count) : {
        key       = "${site_key}-${i}"
        site_key  = site_key
        index     = i
        name      = "${site.name}-token-${i}"
        site_name = site.name
      }
    ]
  ])
}

resource "volterra_securemesh_site_v2" "site" {
  for_each = var.sites
  name     = each.value.name
  labels = {
    "ves.io/siteName" = "cap-lab-gage"
    "kulland/region"  = each.value.region_label
  }
  namespace          = var.namespace
  annotations        = {}
  description        = "cap corp lab site"
  enable_ha          = var.ha
  block_all_services = false

  admin_user_credentials {
    ssh_key = file(var.ssh_key)
    admin_password {
      clear_secret_info {
        url = "string:///${base64encode(var.admin_password)}"
      }
    }
  }
  dynamic "azure" {
    for_each = each.value.cloud == "azure" ? [1] : []
    content {
      not_managed {}
    }
  }

  dynamic "aws" {
    for_each = each.value.cloud == "aws" ? [1] : []
    content {
      not_managed {}
    }
  }

    dns_ntp_config {
      f5_dns_default = true
      f5_ntp_default = true
    }

    f5_proxy = true

    load_balancing {
      vip_vrrp_mode = "VIP_VRRP_DISABLE"
    }

    local_vrf {
      default_config     = true
      default_sli_config = true
    }

    logs_streaming_disabled = true
    no_forward_proxy        = true
    no_network_policy       = true
    no_s2s_connectivity_sli = true

    site_mesh_group_on_slo {
      sm_connection_public_ip = true
    }

    offline_survivability_mode {
      enable_offline_survivability_mode = true
    }

    performance_enhancement_mode {
      perf_mode_l7_enhanced = true
    }

    re_select {
      geo_proximity = true
    }

    software_settings {
      os {
        operating_system_version = var.os
      }
      sw {
        volterra_software_version = var.sw
      }
    }

    tunnel_dead_timeout = 0
    tunnel_type         = "IPSEC"

    upgrade_settings {
      kubernetes_upgrade_drain {
        enable_upgrade_drain {
          drain_max_unavailable_node_count = 1
          drain_node_timeout              = 300
        }
      }
    }
  }

resource "volterra_token" "token" {
  for_each   = { for t in local.site_tokens : t.key => t }
  name       = each.value.name
  namespace  = var.namespace
  site_name  = volterra_securemesh_site_v2.site[each.value.site_key].name
  type       = "1"
  depends_on = [volterra_securemesh_site_v2.site]
}

