
# ICLINIQ-ASSESMENT

This repository implements a **secure-by-default** delivery of a containerized **Node.js (TypeScript + Express)** API on **Google Cloud Run**, backed by **Cloud SQL (PostgreSQL)**, with **private connectivity**, **least-privilege IAM**, **secrets in Google Secret Manager (GSM)**, and **full Infrastructure as Code (Terraform)**. CI/CD is built with **GitHub Actions** using **Workload Identity Federation (OIDC)** (no JSON keys).

> This README describes *what we built and why* from a DevSecOps perspective. It avoids project-specific values so it can be reused in different environments.

---

## 1) High-Level Architecture

```
Client → Cloud Run service (containerized Express app; non-root)
         ↳ Serverless VPC Access Connector
            ↳ Cloud SQL (PostgreSQL, Private IP only via PSA)
Secrets → Google Secret Manager (DB credentials)
Images  → Artifact Registry (regional)
Control → GitHub Actions + OIDC/WIF (ephemeral credentials)
Observe → Cloud Logging + Metrics + Alerting
Manage  → Terraform modules (Run, SQL, VPC, Secrets, Artifact, IAM, Monitoring)
```

**Key Security Choices**
- **Private DB path**: Cloud Run reaches Cloud SQL over VPC; DB has no public IP.
- **Principle of Least Privilege**: separate runtime and deployer service accounts; only minimal roles granted.
- **Keyless CI/CD**: GitHub → GCP auth via OIDC/WIF; no long-lived JSON keys in repo.
- **Hardened runtime**: non-root user, minimal base image, `helmet`, rate-limit, structured logs.
- **IaC**: Terraform defines everything (networking, SQL, Run, secrets, IAM, metrics/alerts).
- **Shift-left security**: linting, tests, SCA/container scans in CI; Terraform fmt/validate/tflint.

---

## 2) Threat Model (at a glance)

| Asset | Threat | Control(s) |
|---|---|---|
| Source code & pipeline | Credential theft, supply chain tampering | OIDC/WIF (no static keys), image scanning, secret scanning, lockfile installs (`npm ci`) |
| Container image | Vulnerable libs, tampering | Multi-stage builds, Trivy scan, provenance/attestations (extendable) |
| Runtime service | RCE, SSRF, noisy neighbors | Non-root, minimal packages, `helmet`, input validation (`zod`), rate limiting |
| Secrets | Exposure in code/logs/CI | GSM + least-privilege access; never printed; masked in CI |
| Data in DB | Public exposure, lateral movement | Private IP only, VPC connector, PSA; DB user scoped to application schema |
| IAM | Excess privileges | Separate SAs; minimal roles; no primitive roles |
| Observability | Blind spots | Structured logs, log-based metrics, CPU/memory alerts |

---

## 3) CI/CD: Security Gates and Flow

**Workflows**
- **CI** (pull requests): Node setup → `npm ci` (lockfile), **lint**, **typecheck/build**, **unit tests**; container **scan**; Terraform **fmt/validate/tflint**; config scan; secret-scan.
- **App CD** (main branch / tags): OIDC auth → build & push image to Artifact Registry → deploy to Cloud Run (either via Terraform variable for image or `gcloud run services update`). Optional signed-image/attestations.
- **Infra CD**: OIDC auth → `terraform init/plan/apply` to converge infra.

**Why OIDC/WIF?**
- Ephemeral, audience-bound credentials; no key sprawl.
- Revocation/control at the identity provider and on GCP IAM binding.

---

## 4) Infrastructure as Code (Terraform)

**Modules provision:**
- **Cloud Run v2** service (no `PORT` env injected manually; Cloud Run sets it).
- **Artifact Registry** repository (regional) for images.
- **VPC** (custom mode), **PSA** reserved range (at least `/24`), **Serverless VPC Access** connector.
- **Cloud SQL (PostgreSQL)**: instance (private IP), database, user.
- **Secret Manager**: DB credentials as secrets + versions; IAM bindings for runtime SA.
- **IAM**: least-privilege roles for runtime SA; deployer SA roles for deployment.
- **Monitoring/Alerting**: log-based metric for app errors; CPU/memory utilization policies; optional Chat/email channels.

**State**
- Local by default; can be switched to **GCS backend** with object versioning (+ optional CMEK) for team use and locking.
- Keep state bucket private; grant minimal roles to CI and admins.

**Drift**
- Terraform is source of truth; avoid out-of-band mutations (e.g., manual public IPs for SQL). If temporary changes are needed, document and revert.

---

## 5) Secrets & Config

- All sensitive values (DB name/user/password, etc.) are stored in **Google Secret Manager**.
- Runtime SA has **read-only** access to required secrets; no secrets committed to VCS.
- App reads secrets via environment variables injected by Cloud Run from GSM.
- CI never prints secrets; logs are redacted; sensitive headers removed from logs.

---

## 6) IAM & Identity

- **Runtime Service Account** (Cloud Run): minimal roles, typically including Secret Manager accessor, Cloud SQL Client, Logging writer, Monitoring metric writer.
- **Deployer Service Account** (GitHub Actions via OIDC/WIF): roles to push to Artifact Registry and update Cloud Run; optionally VPC Access user if needed for connector interactions.
- No primitive roles (Owner/Editor/Viewer). Use predefined or custom roles aligned to least privilege.

---

## 7) Network Security

- **Private Service Access (PSA)** and a **reserved range** (≥ `/24`) enable Cloud SQL’s private IP.
- **Serverless VPC Access Connector** provides egress from Cloud Run into the VPC.
- DB has **no public IP**; traffic never leaves Google’s network.
- Ingress policy for Cloud Run can be restricted based on environment (internal/LB vs public), with IAM gating by default.

---

## 8) Application Security Posture

- **Express** hardened with `helmet`, **rate limiting**, and structured logs (`pino-http`).
- **Validation** with `zod` on request bodies.
- **Error handling** returns minimal details; sensitive data never logged.
- **Health endpoints** (`/healthz`) are lightweight and side-effect free.
- Server binds to `0.0.0.0` and **listens on the `PORT`** provided by Cloud Run (no hardcoding).

---

## 9) Observability & Alerts

- **Cloud Logging**: structured logs; request IDs via Cloud Run.
- **Log-based metric** for app errors to drive alerting.
- **Alert Policies** (examples used):
  - **Warning** when CPU/memory utilization exceeds a threshold for a short window.
  - **Critical** when higher thresholds are sustained.
- **Notification channels**: Google Chat webhook and/or email (optional via variables).
- Extend with SLOs (availability/latency) and error budgets as needed.

---

## 10) Secure Verification Checklist (Post-Deploy)

1. **Auth** — Test with an **identity token whose audience equals the Cloud Run URL** (tokens are host-scoped).
2. **Health** — `GET /healthz` returns `200`.
3. **App routes** — e.g., `GET /api/v1/items` (expect list), `POST /api/v1/items` (create, then list again).
4. **Logs** — Tail revision logs and confirm startup log lines and structured request logs.
5. **DB** — Prove connectivity with a simple `SELECT now()` endpoint or one-time migration/bootstrapping of required tables.
6. **Alerts** — Verify channels exist; (optionally) simulate thresholds in a test environment.

> If you see an HTML 404 from Google when calling an endpoint, it usually means the request never reached the container (most often: audience/token host mismatch).

---

## 11) Operations & Governance

- **Rollbacks**: shift Cloud Run traffic to previous revision or redeploy a known-good image.
- **Secret rotation**: rotate GSM versions and trigger a new revision or use runtime reload logic.
- **Patching**: rebuild image to pick up OS and npm dependency updates; CI scans gate merges.
- **Backups/DR**: enable SQL automated backups and PITR; document RTO/RPO targets.
- **Access reviews**: periodically audit IAM bindings (runtime/deployer SAs, state bucket, etc.).



## 13) How to Reuse in Another Project (no hard-coded values)

- Parameterize **project/region/names** via Terraform variables and CI environment inputs.
- Keep **state** in a dedicated GCS bucket with versioning (and encryption) per environment.
- Reuse the same **WIF provider** pattern for GitHub Actions; bind repo/ref conditions to limit scope.
- Adjust **ingress**, **autoscaling**, and **alerts** to match the environment’s risk profile.

---

## 14) Repository Layout (generic)

```
app/                      # Node.js service (TypeScript)
  src/
    index.ts              # Express app with healthz + routes
    db.ts                 # pg pool (reads env from GSM)
    routes.ts             # REST endpoints with validation
  Dockerfile              # multi-stage build, non-root runtime
  package.json / tsconfig.json

infra/                    # Terraform root + modules
  main.tf / variables.tf / outputs.tf
  modules/
    artifact/             # Artifact Registry
    iam/                  # runtime + deployer IAM
    network/              # VPC, PSA (/24), VPC connector
    run/                  # Cloud Run v2 service config
    secrets/              # GSM secrets
    sql/                  # Cloud SQL + DB + user
    monitoring/           # log metric + alert policies

.github/workflows/
  ci.yml                  # lint/test/scan + tf checks
  app-cd.yml              # build/push + deploy
  tf-cd.yml               # terraform apply
```

---

12) CI (Pull Request) Jobs — What runs on each PR

All CI jobs are signal-first and non-blocking (every step uses continue-on-error: true). Findings are surfaced to developers without hard-failing the PR, and a concise sticky PR comment summarizes the results.

Jobs

gitleaks
Scans the repository for potential secrets and adds a short status line to the summary.

node-ci (runs in app/)
Sets up Node 20, runs npm ci from the lockfile, then:

lint (only if a script exists),

TypeScript compile check (only if config/script present),

unit tests (only if a script exists),

npm audit (high severity and above, non-blocking).
Each step reports its outcome to the summary.

container-scan
Builds the Docker image from app/Dockerfile (no push) and scans it with Trivy.
The Actions Summary shows a compact table, plus counts of CRITICAL/HIGH issues.

terraform-checks (runs in infra/)
Executes terraform fmt -check, init -backend=false, and validate, then runs tfsec (soft-fail) to surface Terraform security findings.

pr-summary
Aggregates the mini-summaries from each job, writes them to the Actions Summary, and posts/updates a sticky PR comment (marked with <!-- ci-quick-summary -->).

Purpose: provide fast, actionable feedback (lint/test/security) without blocking iteration; enforcement/policy can be added later if desired.
