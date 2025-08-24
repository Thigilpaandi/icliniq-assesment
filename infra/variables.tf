########################
# Core / Environment
########################

variable "project_id" {
  description = "GCP project ID to deploy into."
  type        = string
}

variable "region" {
  description = "GCP region (e.g., europe-west2, asia-south1)."
  type        = string
  default     = "europe-west2"
}

########################
# Networking
########################

variable "network_name" {
  description = "VPC network name."
  type        = string
  default     = "primary-vpc"
}

variable "subnet_name" {
  description = "Subnet name."
  type        = string
  default     = "primary-subnet"
}

variable "serverless_connector" {
  description = "Serverless VPC connector name for Cloud Run egress."
  type        = string
  default     = "run-vpc-connector"
}

########################
# Artifact Registry / Service
########################

variable "artifact_registry_repo" {
  description = "Artifact Registry repository ID to store Docker images."
  type        = string
  default     = "apps"
}

variable "cloud_run_service" {
  description = "Cloud Run service name."
  type        = string
  default     = "secure-node-api"
}

########################
# Database (Cloud SQL)
########################

variable "db_instance_name" {
  description = "Cloud SQL instance name."
  type        = string
  default     = "secure-node-db"
}

variable "db_tier" {
  description = "Cloud SQL machine tier (e.g., db-f1-micro, db-custom-1-3840)."
  type        = string
  default     = "db-f1-micro"
}

variable "db_version" {
  description = "Cloud SQL engine/version (e.g., POSTGRES_15, POSTGRES_14)."
  type        = string
  default     = "POSTGRES_15"
}

variable "db_name" {
  description = "Application database name."
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Application database user."
  type        = string
  default     = "appuser"
}

variable "deletion_protection" {
  description = "Enable deletion protection on Cloud SQL instance."
  type        = bool
  default     = false
}

########################
# Deployment
########################

variable "image" {
  description = "Container image to deploy (e.g., europe-west2-docker.pkg.dev/PROJECT/apps/secure-node-api:SHA)."
  type        = string
  default     = null
}

########################
# Access / Identity
########################

variable "runtime_sa_name" {
  description = "Service account name for Cloud Run runtime."
  type        = string
  default     = "run-secure-node-sa"
}

variable "deployer_service_account_email" {
  description = "Service account email used by GitHub OIDC for deploys (impersonation target)."
  type        = string
}

########################
# Notifications / Monitoring
########################

variable "chat_webhook_url" {
  description = "Google Chat webhook for warning notifications (optional)."
  type        = string
  default     = null
}

variable "alert_email" {
  description = "Email address for critical alert policies (optional)."
  type        = string
  default     = null
}

########################
# Cloud Run settings
########################

variable "ingress" {
  description = "Ingress policy for Cloud Run (INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER or INGRESS_TRAFFIC_ALL)."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"

  validation {
    condition     = contains(["INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER", "INGRESS_TRAFFIC_ALL"], var.ingress)
    error_message = "ingress must be one of: INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER, INGRESS_TRAFFIC_ALL."
  }
}

variable "min_instances" {
  description = "Minimum number of Cloud Run instances."
  type        = number
  default     = 0


}

variable "max_instances" {
  description = "Maximum number of Cloud Run instances."
  type        = number
  default     = 4


}

variable "container_concurrency" {
  description = "Maximum number of concurrent requests per instance."
  type        = number
  default     = 80


}
