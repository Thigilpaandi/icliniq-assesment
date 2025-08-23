
# Secure Node.js on Google Cloud Run (DevSecOps + Terraform)

Production-ready starter that deploys a TypeScript/Express API to **Cloud Run**, connects privately to **Cloud SQL (Postgres)** via **Serverless VPC Access**, stores secrets in **Secret Manager**, and provisions everything via **Terraform**. CI/CD uses **GitHub Actions** with **OIDC** (no JSON keys). Monitoring includes **CPU/memory** alerts and a log-based error metric with Google Chat & Email channels.

## Architecture
- Cloud Run (private VPC egress) → Cloud SQL (Private IP)
- Artifact Registry for images
- Secret Manager for DB creds
- Serverless VPC Connector for private connectivity
- Terraform modules for network, SQL, secrets, artifact, IAM, run, monitoring
- GitHub Actions CI (lint, test, Trivy, Terraform validate) & CD (build, push, TF apply)

## Prereqs
- GCP project & billing
- Enable APIs: `run.googleapis.com`, `artifactregistry.googleapis.com`, `secretmanager.googleapis.com`, `sqladmin.googleapis.com`, `vpcaccess.googleapis.com`, `servicenetworking.googleapis.com`, `monitoring.googleapis.com`, `logging.googleapis.com`
- GitHub OIDC to GCP configured (Workload Identity Pool + Provider), and a deployer Service Account with email you pass via `TF_VAR_deployer_service_account_email`.

## Quick start
```bash
# App (local)
cd app
npm ci
npm run build && npm start
# visit http://localhost:8080/healthz
```

```bash
# Terraform (creates VPC, SQL, Secrets, Artifact, SA, Cloud Run, Monitoring)
cd infra
terraform init
terraform apply -var="project_id=YOUR_GCP_PROJECT_ID" -var="deployer_service_account_email=github-deployer@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com"
```

### First deploy via CD
1. Create the Artifact Registry repo once (Terraform handles it).
2. Push to `main`. The CD workflow:
   - Auths via OIDC
   - Builds & pushes image → `${REGION}-docker.pkg.dev/${PROJECT}/apps/secure-node-api:${GITHUB_SHA}`
   - Runs `terraform apply` with `TF_VAR_image` set to that image
   - Outputs the Cloud Run URL

> Default ingress is `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`. For public, set `var.ingress = "INGRESS_TRAFFIC_ALL"` temporarily (or put behind HTTPS LB).

## Secrets
- Stored in `Secret Manager`: `DB_NAME`, `DB_USER`, `DB_PASSWORD`. Values are injected into Cloud Run via env **secret refs**.
- Password generated with `random_password` in Terraform.

## Migrations & seed
Run these from a machine with `psql` and network access (Cloud Run uses private IP; from public you need a Bastion or Cloud SQL Auth Proxy). If you're on a private runner with VPC access:
```bash
./scripts/migrate.sh
./scripts/seed.sh
```

## Alerts
- **Warn**: CPU > 70% -> Google Chat
- **Critical**: CPU or Memory > 80% -> Email
- **Logs-based metric**: counts errors from the service

> Metric type names differ across revisions/regions over time. If policies fail to bind, search “Cloud Run container cpu utilizations metric” and adjust `metric.type` in `modules/monitoring`.

## Security Measures
- OIDC for CI/CD (no long-lived JSON keys)
- Least-privilege roles for runtime SA and deployer SA
- Image scan (Trivy), secret scanning and SAST in CI
- Helmet, rate limits, validation, non-root user, healthcheck

## Variables
See `infra/env/sample.auto.tfvars` for common variables.
