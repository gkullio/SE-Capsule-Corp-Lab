output "token_ids" {
  description = "Map of site key to list of token IDs"
  value = {
    for site_key in keys(var.sites) : site_key => [
      for t_key, t in volterra_token.token : t.id
      if startswith(t_key, "${site_key}-")
    ]
  }
}

output "cluster_name" {
  description = "Map of site key to cluster name"
  value = {
    for key, site in volterra_securemesh_site_v2.site : key => site.name
  }
}

output "site_names" {
  description = "List of full site names"
  value       = [for site in volterra_securemesh_site_v2.site : site.name]
}

output "us_site_name" {
  description = "Full name of the US site"
  value       = volterra_securemesh_site_v2.site["us"].name
}

output "in_site_name" {
  description = "Full name of the India site"
  value       = volterra_securemesh_site_v2.site["in"].name
}
