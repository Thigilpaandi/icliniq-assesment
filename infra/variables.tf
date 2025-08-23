
variable "project_id" { type = string }
variable "region"     { type = string  default = "europe-west2" }

variable "network_name"            { type = string default = "primary-vpc" }
variable "subnet_name"             { type = string default = "primary-subnet" }
variable "serverless_connector"    { type = string default = "run-vpc-connector" }
variable "artifact_registry_repo"  { type = string default = "apps" }
variable "cloud_run_service"       { type = string default = "secure-node-api" }

# Database
variable "db_instance_name" { type = string default = "secure-node-db" }
variable "db_tier"          { type = string default = "db-f1-micro" }
variable "db_version"       { type = string default = "POSTGRES_15" }
variable "db_name"          { type = string default = "appdb" }
variable "db_user"          { type = string default = "appuser" }
variable "deletion_protection" { type = bool default = false }

# Deployment
variable "image" { type = string default = null } # e.g. "europe-west2-docker.pkg.dev/PROJECT/apps/secure-node-api:SHA"

# Access/Identity
variable "runtime_sa_name" { type = string default = "run-secure-node-sa" }
variable "deployer_service_account_email" { type = string description = "SA email used by GitHub OIDC to deploy" }

variable "chat_webhook_url" {
  type    = string
  default = null
}

variable "alert_email" {
  type    = string
  default = null
}


# Cloud Run
variable "ingress" { type = string default = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" } # or INGRESS_TRAFFIC_ALL
variable "min_instances" { type = number default = 0 }
variable "max_instances" { type = number default = 4 }
variable "container_concurrency" { type = number default = 80 }
