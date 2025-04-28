# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "resellio-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "resellio-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = local.location
  network       = google_compute_network.vpc_network.id
}

# VPC Connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  name          = "resellio-vpc-connector"
  region        = local.location
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.8.0.0/28"

  # TODO: can change it for production
  min_instances = 2
  max_instances = 3
}

# Private connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
