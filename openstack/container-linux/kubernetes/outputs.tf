# Outputs for controlplane

output "kubeconfig_admin" {
  value = module.bootstrap.kubeconfig-admin
}

output "apiserver_url" {
  value = format(
    "https://%s.%s:6443/",
    var.cluster_name,
    var.dns_zone
  )
}

output "client_certificate" {
  value = module.bootstrap.admin_cert
}

output "client_key" {
  value = module.bootstrap.admin_key
}

output "cluster_ca_certificate" {
  value = module.bootstrap.admin_ca_cert
}

# Outputs for worker pools

output "kubeconfig" {
  value = module.bootstrap.kubeconfig-kubelet
}

# Outputs for network

output "secgroup_worker" {
  value = openstack_networking_secgroup_v2.mgmt
}

# Outputs for created VMs

output "instance_names" {
  value = concat(
    openstack_compute_instance_v2.controllers.*.name,
    openstack_compute_instance_v2.workers.*.name
  )
}

output "dns_zone" {
  value = var.dns_zone
}
