
output "cloud_run_uri" {
  value = module.run.service_uri
}

output "artifact_repository" {
  value = module.artifact.repo_id
}
