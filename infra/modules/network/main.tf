
variable "project_id" { type = string }
variable "region"     { type = string }
variable "network_name" { type = string }
variable "subnet_name"  { type = string }
variable "serverless_connector" { type = string }

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}


# PSA range (replace your existing one if prefix_length < 24)
resource "google_compute_global_address" "private_service_range" {
  name          = var.subnet_name # e.g., "sql-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 28                             # ✅ /24 minimum
  network       = google_compute_network.vpc.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
  depends_on              = [google_compute_global_address.private_service_range]
  lifecycle {
    prevent_destroy = true
  }
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
