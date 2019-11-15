output "kubeconfig-admin" {
  value = module.bootstrap.kubeconfig-admin
}

# Outputs for worker pools

output "kubeconfig" {
  value = module.bootstrap.kubeconfig-kubelet
}

# Outputs for network

output "secgroup_worker" {
  value = openstack_networking_secgroup_v2.worker
}

output "ingress_fixed_ip" {
  value = openstack_networking_port_v2.ingress.all_fixed_ips[0]
}
