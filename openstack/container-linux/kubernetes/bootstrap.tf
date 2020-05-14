# Kubernetes assets (kubeconfig, manifests)
module "bootstrap" {
  source = "git::https://github.com/pjoomen/terraform-render-bootstrap.git?ref=5fb2c6181c527278430d6b7a87ef308b1e544e82"

  cluster_name          = var.cluster_name
  api_servers           = [format("%s.%s", var.cluster_name, var.dns_zone)]
  etcd_servers          = data.template_file.controllernames.*.rendered
  asset_dir             = var.asset_dir
  networking            = var.networking
  network_mtu           = var.network_mtu
  pod_cidr              = var.pod_cidr
  service_cidr          = var.service_cidr
  oidc_client_id        = var.oidc_client_id
  cluster_domain_suffix = var.cluster_domain_suffix
}

data "template_file" "controllernames" {
  count    = var.controller_count
  template = "$${cluster_name}-controller-$${index}.$${dns_domain}"

  vars = {
    index        = count.index
    cluster_name = var.cluster_name
    dns_domain   = var.dns_domain
  }
}
