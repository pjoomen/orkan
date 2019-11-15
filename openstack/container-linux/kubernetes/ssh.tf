locals {
  # format assets for distribution
  assets_bundle = [
    # header with the unpack location
    for key, value in module.bootstrap.assets_dist :
    format("##### %s\n%s", key, value)
  ]
}

# Secure copy assets to controllers.
resource "null_resource" "copy-controller-secrets" {
  count = var.controller_count

  depends_on = [
    module.bootstrap,
  ]

  connection {
    type    = "ssh"
    host    = element(openstack_compute_instance_v2.controllers.*.access_ip_v6, count.index)
    user    = "core"
    timeout = "15m"
  }

  provisioner "file" {
    content     = join("\n", local.assets_bundle)
    destination = "$HOME/assets"
  }

  provisioner "file" {
    content     = "{\"auths\":{\"https://eu.gcr.io\":{\"auth\":\"${var.eu_gcr_auth}\"}}}"
    destination = "$HOME/config.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /opt/bootstrap/layout",
      "sudo mkdir -p /var/lib/kubelet",
      "sudo mv $HOME/config.json /var/lib/kubelet/config.json",
      "sudo chown root: /var/lib/kubelet/config.json",
      "sudo chown 400 /var/lib/kubelet/config.json",
    ]
  }
}

# Secure copy kubeconfig to all workers. Activates kubelet.service.
resource "null_resource" "copy-worker-secrets" {
  count = var.worker_count

  connection {
    type    = "ssh"
    host    = element(openstack_compute_instance_v2.workers.*.access_ip_v6, count.index)
    user    = "core"
    timeout = "15m"
  }

  provisioner "file" {
    content     = module.bootstrap.kubeconfig-kubelet
    destination = "$HOME/kubeconfig"
  }

  provisioner "file" {
    content     = "{\"auths\":{\"https://eu.gcr.io\":{\"auth\":\"${var.eu_gcr_auth}\"}}}"
    destination = "$HOME/config.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv $HOME/kubeconfig /etc/kubernetes/kubeconfig",
      "sudo mkdir -p /var/lib/kubelet",
      "sudo mv $HOME/config.json /var/lib/kubelet/config.json",
      "sudo chown root: /var/lib/kubelet/config.json",
      "sudo chown 400 /var/lib/kubelet/config.json",
    ]
  }
}

# Connect to a controller to perform one-time cluster bootstrap.
resource "null_resource" "bootstrap" {
  depends_on = [
    null_resource.copy-controller-secrets,
    null_resource.copy-worker-secrets,
  ]

  connection {
    type    = "ssh"
    host    = element(openstack_compute_instance_v2.controllers.*.access_ip_v6, 0)
    user    = "core"
    timeout = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl start bootstrap",
    ]
  }
}
