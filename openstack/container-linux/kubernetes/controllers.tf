# Controller instances
resource "openstack_networking_port_v2" "controller-ports" {
  count              = var.controller_count
  name               = "${var.cluster_name}-controller-${count.index}"
  network_id         = var.network_id
  security_group_ids = [
    openstack_networking_secgroup_v2.worker.id,
    openstack_networking_secgroup_v2.controller.id,
  ]
  allowed_address_pairs {
    ip_address = openstack_networking_port_v2.kube-apiserver-vip.all_fixed_ips[0]
  }
}

resource "openstack_compute_instance_v2" "controllers" {
  count             = var.controller_count
  name              = "${var.cluster_name}-controller-${count.index}"
  flavor_name       = var.controller_type
  image_name        = var.os_image
  user_data         = element(data.ct_config.controller-ignitions.*.rendered, count.index)
  availability_zone = element(var.availability_zones, count.index)
  network {
    port = element(openstack_networking_port_v2.controller-ports.*.id, count.index)
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

  template = file("${path.module}/cl/controller.yaml.tmpl")

  vars = {
    # Cannot use cyclic dependencies on controllers or their DNS records
    etcd_name   = "etcd${count.index}"
    etcd_domain = "${var.cluster_name}-controller-${count.index}.${var.dns_domain}"
    # etcd0=https://cluster-controller-0.example.com,etcd1=https://cluster-controller-1.example.com,...
    etcd_initial_cluster   = join(",", data.template_file.etcds.*.rendered)
    kubeconfig             = indent(10, module.bootstrap.kubeconfig-kubelet)
    ssh_authorized_key     = var.ssh_authorized_key
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
    cluster_domain_suffix  = var.cluster_domain_suffix
    kube_apiserver_vip     = var.kube_apiserver_vip
    api_virtual_ip         = openstack_networking_port_v2.kube-apiserver-vip.all_fixed_ips[0]
  }
}

data "template_file" "etcds" {
  count    = var.controller_count
  template = "etcd$${index}=https://$${cluster_name}-controller-$${index}.$${dns_domain}:2380"

  vars = {
    index        = count.index
    cluster_name = var.cluster_name
    dns_domain   = var.dns_domain
  }
}
