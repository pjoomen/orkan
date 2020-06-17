# Controller instances
resource "openstack_networking_port_v2" "controller-ports" {
  count      = var.controller_count
  name       = "${var.cluster_name}-controller-${count.index}"
  tags       = [var.cluster_name]
  network_id = var.network_id
  security_group_ids = [
    openstack_networking_secgroup_v2.mgmt.id,
    openstack_networking_secgroup_v2.controller.id,
  ]
  allowed_address_pairs {
    ip_address = openstack_networking_port_v2.kube-apiserver-vip.all_fixed_ips[0]
  }
}

resource "openstack_networking_port_v2" "controller-vrf-ports" {
  count      = var.controller_count
  name       = "${var.cluster_name}-controller-vrf-${count.index}"
  tags       = [var.cluster_name]
  network_id = var.vrf_networks[element(var.availability_zones, count.index)]
  security_group_ids = [
    "3a4a1481-cfb0-4718-85cb-9bd43026444d",
  ]
  allowed_address_pairs {
    ip_address = var.pod_cidr
  }
  allowed_address_pairs {
    ip_address = var.service_cidr
  }
}

resource "openstack_compute_instance_v2" "controllers" {
  count             = var.controller_count
  name              = "${var.cluster_name}-controller-${count.index}"
  tags              = [var.cluster_name]
  flavor_name       = var.controller_type
  image_name        = var.os_image
  user_data         = element(data.ct_config.controller-ignitions.*.rendered, count.index)
  availability_zone = element(var.availability_zones, count.index)
  network {
    port = element(openstack_networking_port_v2.controller-ports.*.id, count.index)
  }
  network {
    port = element(openstack_networking_port_v2.controller-vrf-ports.*.id, count.index)
  }
  lifecycle {
    ignore_changes = [user_data]
  }
}

# Controller Ignition configs
data "ct_config" "controller-ignitions" {
  count = var.controller_count
  content = element(
    data.template_file.controller-configs.*.rendered,
    count.index,
  )
  pretty_print = false
  snippets     = var.controller_clc_snippets
}

# Controller Container Linux configs
data "template_file" "controller-configs" {
  count = var.controller_count

  template = file("${path.module}/cl/controller.yaml")

  vars = {
    # Cannot use cyclic dependencies on controllers or their DNS records
    etcd_name   = "etcd${count.index}"
    etcd_domain = openstack_networking_port_v2.controller-ports[count.index].all_fixed_ips[0]
    # etcd0=https://cluster-controller-0.example.com,etcd1=https://cluster-controller-1.example.com,...
    etcd_initial_cluster   = join(",", data.template_file.etcds.*.rendered)
    kubeconfig             = indent(10, module.bootstrap.kubeconfig-kubelet)
    ssh_authorized_key     = var.ssh_authorized_key
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
    cluster_domain_suffix  = var.cluster_domain_suffix
    kubelet_image          = var.kubelet_image
    availability_zone      = element(var.availability_zones, count.index)
    hostname               = "${var.cluster_name}-controller-${count.index}"
    eth0_address           = openstack_networking_port_v2.controller-ports[count.index].all_fixed_ips[0]
    eth0_gateway           = cidrhost("${openstack_networking_port_v2.controller-ports[count.index].all_fixed_ips[0]}/24", 1)
    eth1_address           = openstack_networking_port_v2.controller-vrf-ports[count.index].all_fixed_ips[0]
    eth1_gateway           = cidrhost("${openstack_networking_port_v2.controller-vrf-ports[count.index].all_fixed_ips[0]}/26", 1)
    dns_zone               = var.dns_zone
    kube_apiserver_vip     = var.kube_apiserver_vip
    api_virtual_ip         = openstack_networking_port_v2.kube-apiserver-vip.all_fixed_ips[0]
  }
}

data "template_file" "etcds" {
  count    = var.controller_count
  template = "etcd$${index}=https://$${ipaddress}:2380"

  vars = {
    index        = count.index
    cluster_name = var.cluster_name
    dns_zone     = var.dns_zone
    ipaddress    = openstack_networking_port_v2.controller-ports[count.index].all_fixed_ips[0]
  }
}
