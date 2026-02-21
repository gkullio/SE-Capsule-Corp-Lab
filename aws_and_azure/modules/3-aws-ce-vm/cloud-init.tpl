#cloud-config
write_files:
  - path: /etc/vpm/user_data
    permissions: "644"
    owner: root
    content: |
      token: ${token}
      slo_ip: ${slo_ip}
      #slo_gateway: Un-comment and set default gateway for SLO when static IP is needed.
