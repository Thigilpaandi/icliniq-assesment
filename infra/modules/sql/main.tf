
variable "project_id"         { type = string }
variable "region"             { type = string }
variable "db_instance_name"   { type = string }
variable "db_tier"            { type = string }
variable "db_version"         { type = string }
variable "private_network_id" { type = string }
variable "db_name"            { type = string }
variable "db_user"            { type = string }
variable "db_password"        { type = string }
variable "deletion_protection" { type = bool }

resource "google_sql_database_instance" "this" {
  name             = var.db_instance_name
  region           = var.region
  database_version = var.db_version
  deletion_protection = var.deletion_protection

  depends_on = [google_service_networking_connection.dep]

  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network_id
    }
    availability_type = "ZONAL"
    backup_configuration {
      enabled = true
    }
  }
}



resource "google_sql_database" "db" {
  name     = var.db_name
  instance = google_sql_database_instance.this.name
}

resource "google_sql_user" "user" {
  instance = google_sql_database_instance.this.name
  name     = var.db_user
  password = var.db_password
}

output "private_ip_address" {
  value = google_sql_database_instance.this.ip_address[0].ip_address
}
