# Infrastructure & deployment (AWS)

Deployment notes for the AI alarm clock backend. The mobile app ships through the App Store
and Google Play; this document covers the **server-side** infrastructure only.

> All secrets are sourced from **AWS Secrets Manager** at runtime — never baked into images,
> task definitions, or git. `GEMINI_API_KEY` lives here and is injected into the API/worker
> tasks only.

---

## Target architecture

```
                         Internet
                            │
                            ▼
                  ┌───────────────────┐
                  │  CloudFront + WAF │   TLS termination, edge caching,
                  │  (ACM cert)       │   rate/bot rules, geo/IP allow-deny
                  └─────────┬─────────┘
                            ▼
                  ┌───────────────────┐
                  │  ALB (HTTPS)      │   health checks → /health
                  └─────────┬─────────┘
                            ▼
        ┌─────────────────────────────────────────────┐
        │            ECS Fargate (private subnets)     │
        │   ┌──────────────┐      ┌──────────────────┐ │
        │   │  API service │      │  worker service  │ │
        │   │  (NestJS)    │      │ (queues/push/AI) │ │
        │   └──────┬───────┘      └────────┬─────────┘ │
        └──────────┼───────────────────────┼───────────┘
                   │                        │
     ┌─────────────┼────────────┬───────────┼─────────────┐
     ▼             ▼            ▼            ▼             ▼
┌─────────┐  ┌───────────┐ ┌────────┐  ┌──────────┐ ┌──────────────┐
│   RDS   │  │ElastiCache│ │   S3   │  │ Secrets  │ │   Gemini /   │
│Postgres │  │  Redis    │ │private │  │ Manager  │ │   FCM (out)  │
│Multi-AZ │  │           │ │bucket  │  │          │ │              │
└─────────┘  └───────────┘ └────────┘  └──────────┘ └──────────────┘
```

---

## Components

- **CloudFront + AWS WAF** — public entry point. WAF provides managed rule sets, rate-based
  rules, and IP/geo controls; CloudFront terminates TLS (ACM cert) and fronts the ALB.
- **Application Load Balancer** — routes to the ECS API service, health-checking `GET /health`.
- **ECS Fargate** — two services in private subnets:
  - **API service** — the NestJS HTTP API (auth, alarms, missions, IAP, presigned URLs).
  - **Worker service** — background jobs: push fan-out (FCM), scheduled AI generation, and
    receipt-revalidation, consuming the Redis-backed queue.
  Scale each independently via target-tracking (CPU/req-count) auto-scaling.
- **RDS for PostgreSQL (Multi-AZ)** — primary datastore. Automated backups, PITR, storage
  encryption (KMS), TLS-only connections; reachable only from the ECS security group.
- **ElastiCache for Redis** — caching, rate-limit counters, and the job queue.
- **S3 (private bucket)** — user media. Block Public Access on; access via short-TTL
  presigned URLs issued by the API. Optionally front read traffic with CloudFront + OAC.
- **Secrets Manager** — DB creds, JWT secrets, `GEMINI_API_KEY`, Firebase service account,
  IAP shared secrets. Injected into ECS task definitions as `secrets` (never `environment`).
- **CloudWatch** — logs, metrics, and alarms (API 5xx, latency, queue depth, RDS CPU/conns).

---

## Networking & security

- VPC with public subnets (ALB/NAT) and private subnets (ECS, RDS, ElastiCache).
- Security groups: ALB → API task; API/worker task → RDS:5432 and Redis:6379 only.
- Least-privilege IAM task roles: S3 scoped to the bucket prefix; Secrets Manager scoped to
  the app's secret ARNs; SES/FCM as needed.
- Enforce TLS everywhere; encrypt RDS, ElastiCache, and S3 at rest with KMS.

---

## CI/CD — GitHub Actions

Recommended pipeline (`.github/workflows/`):

1. **CI (on PR):** `npm ci` → lint → `npm test` → `npm run build` for `apps/backend`;
   `flutter analyze` + `flutter test` for `apps/mobile`.
2. **Build & push (on merge to `main`):** build the backend Docker image, tag with the git
   SHA, push to **Amazon ECR** (use OIDC — no long-lived AWS keys in GitHub).
3. **Deploy:** render the ECS task definition with the new image, run `migration:run` as a
   one-off ECS task, then `aws ecs update-service --force-new-deployment` for API + worker
   (rolling deploy; CodeDeploy blue/green optional).
4. **Post-deploy:** smoke-test `GET /health` through CloudFront; auto-rollback on failed
   health checks / CloudWatch alarms.

Promote dev → staging → prod with environment-scoped secrets and separate AWS accounts.

---

## Notes

- Run DB migrations as a **separate task** before rotating the service, so schema changes are
  applied exactly once and predate the new code.
- Keep the mobile `API_BASE_URL` pointed at the CloudFront domain in release builds.
- IaC: codify the above with Terraform or AWS CDK; this README is the reference design.
