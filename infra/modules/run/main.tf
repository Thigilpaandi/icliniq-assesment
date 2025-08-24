
variable "project_id"            { type = string }
variable "region"                { type = string }
variable "service_name"          { type = string }
variable "image"                 { type = string }
variable "vpc_connector"         { type = string }
variable "service_account_email" { type = string }
variable "db_host"               { type = string }
variable "db_name_secret"        { type = string }
variable "db_user_secret"        { type = string }
variable "db_password_secret"    { type = string }
variable "ingress"               { type = string }
variable "min_instances"         { type = number }
variable "max_instances"         { type = number }
variable "container_concurrency" { type = number }

resource "google_cloud_run_v2_service" "svc" {
  name     = var.service_name
  location = var.region
  ingress  = var.ingress

  template {
    service_account = var.service_account_email
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    containers {
      image = var.image != null ? var.image : "us-docker.pkg.dev/cloudrun/container/hello" # placeholder until CD sets real image
      resources {
        limits = { cpu = "1", memory = "512Mi" }
      }
      startup_probe {
        # Use HTTP to your fast health endpoint
        http_get {
          path = "/healthz"
          port = 8080
        }
        initial_delay_seconds = 0
        period_seconds        = 10
        timeout_seconds       = 5
        failure_threshold     = 24  # ~4 minutes (24 * 10s)
      }

      

      env {
        name = "DB_HOST"
        value = var.db_host
      }
      env {
        name = "DB_NAME"
        value_source {
          secret_key_ref {
            secret  = var.db_name_secret
            version = "latest"
          }
        }
      }
      env {
        name = "DB_USER"
        value_source {
          secret_key_ref {
            secret  = var.db_user_secret
            version = "latest"
          }
        }
      }
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = var.db_password_secret
            version = "latest"
          }
        }
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
    }
    vpc_access {
      connector = var.vpc_connector
      egress = "ALL_TRAFFIC"
    }
    max_instance_request_concurrency = var.container_concurrency
  }
}

output "service_uri" {
  value = google_cloud_run_v2_service.svc.uri
}
