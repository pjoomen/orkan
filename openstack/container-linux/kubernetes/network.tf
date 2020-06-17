resource "dns_aaaa_record_set" "controllers" {
  count = var.controller_count
  zone  = format("%s.", var.dns_zone)
  name  = openstack_compute_instance_v2.controllers[count.index].name
  # ref. https://github.com/terraform-providers/terraform-provider-openstack/issues/337
  addresses = [replace(openstack_compute_instance_v2.controllers[count.index].access_ip_v6, "/\\[|\\]/", "")]
  ttl       = 300
}

resource "dns_aaaa_record_set" "workers" {
  count = var.worker_count
  zone  = format("%s.", var.dns_zone)
  name  = openstack_compute_instance_v2.workers[count.index].name
  # ref. https://github.com/terraform-providers/terraform-provider-openstack/issues/337
  addresses = [replace(openstack_compute_instance_v2.workers[count.index].access_ip_v6, "/\\[|\\]/", "")]
  ttl       = 300
}

resource "dns_a_record_set" "kube-apiserver-vip" {
  zone      = format("%s.", var.dns_zone)
  name      = var.cluster_name
  addresses = [openstack_networking_floatingip_v2.kube-apiserver-vip.address]
  ttl       = 300
}

resource "openstack_networking_floatingip_v2" "kube-apiserver-vip" {
  pool = var.floating_ip_pool
}

resource "openstack_networking_port_v2" "kube-apiserver-vip" {
  name       = "kube-apiserver-vip"
  network_id = var.network_id
}

resource "openstack_networking_floatingip_associate_v2" "kube-apiserver-vip" {
  floating_ip = openstack_networking_floatingip_v2.kube-apiserver-vip.address
  port_id     = openstack_networking_port_v2.kube-apiserver-vip.id
}

resource "openstack_networking_secgroup_v2" "mgmt" {
  name = "mgmt"
  tags = [var.cluster_name]
}

resource "openstack_networking_secgroup_rule_v2" "remote_group_v6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.mgmt.id
  remote_group_id   = openstack_networking_secgroup_v2.mgmt.id
}

resource "openstack_networking_secgroup_rule_v2" "remote_group_v4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.mgmt.id
  remote_group_id   = openstack_networking_secgroup_v2.mgmt.id
}

resource "openstack_networking_secgroup_rule_v2" "ipv6_ssh" {
  direction         = "ingress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.mgmt.id
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.remote_ipv6_prefix
}

resource "openstack_networking_secgroup_v2" "controller" {
  name = "controller"
  tags = [var.cluster_name]
}

resource "openstack_networking_secgroup_rule_v2" "kube-apiserver-vip" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.controller.id
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
}

resource "openstack_networking_secgroup_v2" "ingress" {
  name = "ingress"
}

resource "openstack_networking_secgroup_rule_v2" "ingress-http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.ingress.id
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
}
