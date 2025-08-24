
# Security Posture

- **Identity:** GitHub Actions OIDC to GCP. No static keys checked in.
- **Least Privilege:** Separate runtime SA and deployer SA. Minimal roles only.
- **Secrets:** Google Secret Manager. Injected into Cloud Run as secret refs; not logged.
- **Networking:** Cloud SQL Private IP with Serverless VPC Access; no public DB.
- **CI Security:** Lint, unit tests, Trivy image scan. Hooks for Semgrep/Gitleaks can be added.
- **Observability:** Log-based error metric + CPU/Memory alerting with Google Chat/Email.
