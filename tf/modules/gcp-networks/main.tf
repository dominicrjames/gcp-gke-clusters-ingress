
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
resource "google_compute_network" "vpc_network" {
  name = var.vpc_network_name
  auto_create_subnetworks = false
}


# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "subnetwork" {
  for_each = var.subnetworks
  provider      = google-beta

  name          = each.key
  ip_cidr_range = each.value.cidr
  region        = var.subnetwork_region
  network       = google_compute_network.vpc_network.name

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = each.value.pods_cidr
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = each.value.services_cidr
  }

  # https://cloud.google.com/sdk/gcloud/reference/compute/networks/subnets/create#--purpose
  purpose       = each.value.purpose
}


# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "firewall-all-internal" {

  name       = "${google_compute_network.vpc_network.name}-allow-internal"
  network    = google_compute_network.vpc_network.name
  direction  = "INGRESS"
  priority   = 1000

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.firewall_internal_allow_cidr]
}

resource "google_compute_firewall" "firewall-allow-ssh" {

  name    = "${google_compute_network.vpc_network.name}-ext-ssh-allow"
  network = google_compute_network.vpc_network.name
  direction  = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["pubjumpbox"]
}
