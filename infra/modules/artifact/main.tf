
variable "project_id" { type = string }
variable "region"     { type = string }
variable "repo_name"  { type = string }

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.repo_name
  format        = "DOCKER"
  description   = "Application containers"
}

output "repo_id" {
  value = google_artifact_registry_repository.repo.id
}
