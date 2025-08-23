
variable "project_id" { type = string }
variable "region"     { type = string }
variable "network_name" { type = string }
variable "subnet_name"  { type = string }
variable "serverless_connector" { type = string }

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  private_ip_google_access = true
}

# Private Service Connect / Service Networking for Cloud SQL Private IP
resource "google_compute_global_address" "private_ip" {
  name          = "${var.network_name}-psc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}

resource "google_vpc_access_connector" "serverless" {
  name   = var.serverless_connector
  region = var.region
  network = google_compute_network.vpc.name
  ip_cidr_range = "10.8.0.0/28"
}

output "network_id" {
  value = google_compute_network.vpc.id
}

output "connector_id" {
  value = google_vpc_access_connector.serverless.id
}
