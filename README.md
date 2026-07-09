# qnsc-tf-modules

Shared, versioned OpenTofu/Terraform modules for all QNSC products.

This is the infrastructure counterpart to [`qnsc-ci`](https://github.com/QNSC-VN/qnsc-ci)
(shared CI actions): reusable Terraform building blocks live here once, are
versioned per module, and are consumed by every product's `*-infra` repo. Fixes
and improvements made here propagate to all products on their next version bump —
no copy-paste drift.

---

## Module catalog

The canonical list of shared modules, their **current version**, and the pin to
use. Bump a consumer by changing its `?ref=<module>-vX.Y.Z`.

> **This table is the source of truth for the version to pin.** When a module is
> re-tagged, update its **Latest** here in the same PR. If the table and the git
> tags disagree, the git tags win — but that's a bug to fix here.

### Core infrastructure

| Module | Latest | Pin | Purpose |
| :----- | :----- | :-- | :------ |
| [`network`](modules/network) | `v1.1.2` | `network-v1.1.2` | VPC, 3-tier subnets, NAT (gateway/fck-nat), SGs, VPC endpoints (toggleable), flow logs |
| [`rds`](modules/rds) | `v1.1.0` | `rds-v1.1.0` | PostgreSQL, RDS-managed password, Perf Insights, param group, enhanced monitoring |
| [`cache`](modules/cache) | `v1.0.0` | `cache-v1.0.0` | Valkey ElastiCache: serverless (prod) or node (dev cost mode) |
| [`ecs-cluster`](modules/ecs-cluster) | `v1.0.0` | `ecs-cluster-v1.0.0` | ECS cluster + Fargate capacity providers + Container Insights |
| [`ecs-service`](modules/ecs-service) | `v1.3.0` | `ecs-service-v1.3.0` | Fargate service: task def, IAM, ALB host/path rules, sidecars, circuit breaker, autoscaling |
| [`ecr`](modules/ecr) | `v1.1.0` | `ecr-v1.1.0` | ECR repositories + lifecycle + optional repo policy |
| [`messaging`](modules/messaging) | `v1.0.0` | `messaging-v1.0.0` | Data-driven SQS (DLQs) + SNS topics + subscriptions |
| [`alb`](modules/alb) | `v1.0.0` | `alb-v1.0.0` | Shared ALB: HTTPS listener + HTTP→HTTPS redirect (host-routed per product) |
| [`app-bucket`](modules/app-bucket) | `v1.0.0` | `app-bucket-v1.0.0` | Private KMS-encrypted S3 for app files (uploads/attachments) + CORS + lifecycle |

### Web, DNS & edge

| Module | Latest | Pin | Purpose |
| :----- | :----- | :-- | :------ |
| [`pages-web`](modules/pages-web) | `v1.0.0` | `pages-web-v1.0.0` | Cloudflare Pages project for the SPA (replaces the removed `cdn` module) |
| [`dns-record`](modules/dns-record) | `v1.1.0` | `dns-record-v1.1.0` | Single Cloudflare DNS record on `qnsc.vn` (adopt-on-conflict) |
| [`cf-edge`](modules/cf-edge) | `v1.0.0` | `cf-edge-v1.0.0` | Cloudflare edge rulesets: rate-limit + custom rules + optional managed WAF |

### Security & access

| Module | Latest | Pin | Purpose |
| :----- | :----- | :-- | :------ |
| [`iam-oidc`](modules/iam-oidc) | `v1.3.0` | `iam-oidc-v1.3.0` | GitHub OIDC deploy roles (per-env, ecr-push, infra plan/apply) |
| [`secrets`](modules/secrets) | `v1.0.0` | `secrets-v1.0.0` | Secrets Manager (empty secrets) + SSM Parameter Store |
| [`waf`](modules/waf) | `v1.1.0` | `waf-v1.1.0` | WAFv2: managed rules + rate limit + logging + ALB association |
| [`alb-logs`](modules/alb-logs) | `v1.0.0` | `alb-logs-v1.0.0` | S3 bucket + policy for ALB access logs (prod forensics) |

### Operations & cost

| Module | Latest | Pin | Purpose |
| :----- | :----- | :-- | :------ |
| [`dev-scheduler`](modules/dev-scheduler) | `v1.1.0` | `dev-scheduler-v1.1.0` | Off-hours stop RDS + scale ECS to 0 (dev cost saver) |
| [`oneshot-task`](modules/oneshot-task) | `v1.0.0` | `oneshot-task-v1.0.0` | Standalone Fargate task def (migrations/backfills) run via `ecs run-task` |
| [`observability`](modules/observability) | `v1.0.0` | `observability-v1.0.0` | CloudWatch alarms + dashboard (available; wire on at SLA — not yet adopted) |

> **Removed:** the `cdn` module (S3 + CloudFront SPA hosting) was retired in favour
> of [`pages-web`](modules/pages-web) (Cloudflare Pages). Old `cdn-v1.*` tags remain
> for history but must not be used in new stacks.

> **Updating versions:** update the **Latest** column above in the same PR that
> re-tags a module. [Renovate](https://docs.renovatebot.com/) then opens bump PRs
> in consumer repos (they carry a `renovate.json`) so products pick up the new pin.

---

## Usage

Reference a module by git source pinned to a **per-module version tag**:

```hcl
module "api" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/ecs-service?ref=ecs-service-v1.3.0"
  # ... inputs
}
```

> **Pin to a tag** (`?ref=ecs-service-v1.3.0`) in committed environments. Use
> `?ref=main` only for testing on a branch. Upgrades should be deliberate.

---

## Versioning

Each module is versioned **independently** with a prefixed tag:
`ecs-service-v1.3.0`, `network-v1.1.2`, etc. This lets a product adopt a new
`network` without being forced to take a new `rds`.

- Backward-compatible additions → minor bump (`network-v1.1.0` → `network-v1.2.0`)
- Breaking input/output changes → major bump (`network-v2.0.0`)

---

## Contributing

- One module per directory under `modules/`.
- Every module declares its own `versions.tf` (provider/version constraints) and
  carries a `README.md` documenting inputs/outputs.
- CI runs `tofu fmt -check`, `tofu validate`, and `tflint` on every PR.
- Changes require review (see [`CODEOWNERS`](.github/CODEOWNERS)).
- After merge, tag the module: `git tag <module>-vX.Y.Z && git push origin <module>-vX.Y.Z`, and update the **Latest** column in the catalog table above in the same PR.

---

## License

Proprietary and confidential. © QNSC — Quy Nhon Semiconductor. See [`LICENSE`](./LICENSE).
