# Worker instances
resource "openstack_networking_port_v2" "worker-ports" {
  count      = var.worker_count
  name       = "${var.cluster_name}-worker-${count.index}"
  network_id = var.network_id
  security_group_ids = [
    openstack_networking_secgroup_v2.worker.id,
    openstack_networking_secgroup_v2.ingress.id,
  ]
  allowed_address_pairs {
    ip_address = openstack_networking_port_v2.ingress.all_fixed_ips[0]
  }
}

resource "openstack_compute_instance_v2" "workers" {
  count             = var.worker_count
  name              = "${var.cluster_name}-worker-${count.index}"
  flavor_name       = var.worker_type
  image_name        = var.os_image
  user_data         = element(data.ct_config.worker-ignitions.*.rendered, count.index)
  availability_zone = element(var.availability_zones, count.index)
  network {
    port = element(openstack_networking_port_v2.worker-ports.*.id, count.index)
  }
  lifecycle {
    ignore_changes = [user_data]
  }
}

# Worker Ignition config
data "ct_config" "worker-ignitions" {
  content      = data.template_file.worker-configs.rendered
  pretty_print = false
  snippets     = var.worker_clc_snippets
}

# Worker Container Linux config
data "template_file" "worker-configs" {
  template = file("${path.module}/cl/worker.yaml.tmpl")

  vars = {
    kubeconfig             = indent(10, module.bootstrap.kubeconfig-kubelet)
    ssh_authorized_key     = var.ssh_authorized_key
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
    cluster_domain_suffix  = var.cluster_domain_suffix
  }
}
