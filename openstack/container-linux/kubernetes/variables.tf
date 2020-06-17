variable "cluster_name" {
  type        = string
  description = "Unique cluster name"
}

variable "dns_zone" {
  type        = string
  description = "DNS Zone (e.g. google-cloud.example.com)"
}

variable "ca_private_key" {
  # type        = string
  description = "The private key to use for the Certificate Authority"
}

variable "ca_certificate" {
  # type        = string
  description = "The self-signed certicate to use for the Certificate Authority"
}

# OpenStack

variable "network_id" {
  type        = string
  description = "The id of the OpenStack network to use (openstack network list)"
}

variable "vrf_networks" {
  type        = map(string)
  description = "A map of the AZ specific networks to use for the secondary interface"
}

variable "remote_ipv6_prefix" {
  type        = string
  description = "The remote IPv6 prefix allowed to access the nodes"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones available to OpenStack"
}

variable "floating_ip_pool" {
  type        = string
  description = "Subnet to use for assignment of floating ip"
}

variable "kube_apiserver_vip" {
  type        = string
  description = "The container to use for providing a Kubeserver API Virtual IP"
}

# instances

variable "kubelet_image" {
  type        = string
  description = "The Kubelet container image to use"
  default     = "docker://quay.io/poseidon/kubelet:v1.18.3-4-g57fa88a"
}

variable "controller_count" {
  type        = number
  description = "Number of controllers (i.e. masters)"
  default     = 1
}

variable "worker_count" {
  type        = number
  description = "Number of workers"
  default     = 1
}

variable "controller_type" {
  type        = string
  default     = "m1.medium"
  description = "Machine type for controllers (see `openstack flavor list`)"
}

variable "worker_type" {
  type        = string
  default     = "m1.medium"
  description = "Machine type for controllers (see `openstack flavor list`)"
}

variable "os_image" {
  type        = string
  description = "Container Linux image for instances (e.g. coreos-stable)"
  default     = "coreos-stable"
}

variable "controller_clc_snippets" {
  type        = list(string)
  description = "Controller Container Linux Config snippets"
  default     = []
}

variable "worker_clc_snippets" {
  type        = list(string)
  description = "Worker Container Linux Config snippets"
  default     = []
}

# configuration

variable "ssh_authorized_key" {
  type        = string
  description = "SSH public key for user 'core'"
}

variable "asset_dir" {
  type        = string
  description = "Absolute path to a directory where generated assets should be placed (contains secrets)"
}

variable "networking" {
  type        = string
  description = "Choice of networking provider (flannel or calico)"
  default     = "calico"
}

variable "network_mtu" {
  type        = number
  description = "CNI interface MTU (applies to calico only)"
  default     = 1480
}

variable "pod_cidr" {
  type        = string
  description = "CIDR IPv4 range to assign Kubernetes pods"
  default     = "10.2.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = <<EOD
CIDR IPv4 range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for coredns.
EOD
  default     = "10.3.0.0/16"
}

variable "oidc_client_id" {
  type        = string
  description = "The OIDC client ID to use for authorization against Google."
}

variable "eu_gcr_auth" {
  type        = string
  description = "Authentication token for eu.gcr.io."
}

# unofficial, undocumented, unsupported

variable "cluster_domain_suffix" {
  type        = string
  description = "Queries for domains with the suffix will be answered by coredns. Default is cluster.local (e.g. foo.default.svc.cluster.local) "
  default     = "cluster.local"
}
