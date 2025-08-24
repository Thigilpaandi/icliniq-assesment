
variable "project_id" { type = string }
variable "db_name"    { type = string }
variable "db_user"    { type = string }
variable "region"     { type = string }

resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "google_secret_manager_secret" "db_name" {
  secret_id  = "DB_NAME"
  replication {
  user_managed {
    replicas {
      location = var.region
    }
  }
}
}

resource "google_secret_manager_secret_version" "db_name_v" {
  secret      = google_secret_manager_secret.db_name.id
  secret_data = var.db_name
}

resource "google_secret_manager_secret" "db_user" {
  secret_id  = "DB_USER"
  replication {
  user_managed {
    replicas {
      location = var.region
    }
  }
}
}

resource "google_secret_manager_secret_version" "db_user_v" {
  secret      = google_secret_manager_secret.db_user.id
  secret_data = var.db_user
}

resource "google_secret_manager_secret" "db_password" {
  secret_id  = "DB_PASSWORD"
  replication {
  user_managed {
    replicas {
      location = var.region
    }
  }
}
}

resource "google_secret_manager_secret_version" "db_password_v" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

output "db_name_secret" {
  value = google_secret_manager_secret.db_name.id
}

output "db_user_secret" {
  value = google_secret_manager_secret.db_user.id
}

output "db_password_secret" {
  value = google_secret_manager_secret.db_password.id
}

output "db_password_value" {
  value     = random_password.db_password.result
  sensitive = true
}
