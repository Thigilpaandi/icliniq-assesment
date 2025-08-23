
module "network" {
  source                = "./modules/network"
  project_id            = var.project_id
  region                = var.region
  network_name          = var.network_name
  subnet_name           = var.subnet_name
  serverless_connector  = var.serverless_connector
}

module "secrets" {
  source          = "./modules/secrets"
  project_id      = var.project_id
  db_name         = var.db_name
  db_user         = var.db_user
  region                = var.region
}

module "sql" {
  source             = "./modules/sql"
  project_id         = var.project_id
  region             = var.region
  db_instance_name   = var.db_instance_name
  db_tier            = var.db_tier
  db_version         = var.db_version
  private_network_id = module.network.network_id
  db_name            = var.db_name
  db_user            = var.db_user
  db_password        = module.secrets.db_password_value
  deletion_protection = var.deletion_protection
}

module "artifact" {
  source       = "./modules/artifact"
  project_id   = var.project_id
  region       = var.region
  repo_name    = var.artifact_registry_repo
}

module "iam" {
  source               = "./modules/iam"
  project_id           = var.project_id
  runtime_sa_name      = var.runtime_sa_name
  deployer_sa_email    = var.deployer_service_account_email
}

module "run" {
  source                  = "./modules/run"
  project_id              = var.project_id
  region                  = var.region
  service_name            = var.cloud_run_service
  image                   = var.image
  vpc_connector           = module.network.connector_id
  service_account_email   = module.iam.runtime_sa_email
  db_host                 = module.sql.private_ip_address
  db_name_secret          = module.secrets.db_name_secret
  db_user_secret          = module.secrets.db_user_secret
  db_password_secret      = module.secrets.db_password_secret
  ingress                 = var.ingress
  min_instances           = var.min_instances
  max_instances           = var.max_instances
  container_concurrency   = var.container_concurrency
}

module "monitoring" {
  source            = "./modules/monitoring"
  project_id        = var.project_id
  region            = var.region
  service_name      = var.cloud_run_service
  chat_webhook_url  = var.chat_webhook_url
  alert_email       = var.alert_email
}
