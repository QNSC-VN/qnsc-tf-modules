# qnsc-tf-modules

Shared, versioned OpenTofu/Terraform modules for all QNSC products.

This is the infrastructure counterpart to [`qnsc-gitops`](https://github.com/QNSC-VN/qnsc-gitops)
(shared CI actions): reusable Terraform building blocks live here once, are
versioned per module, and are consumed by every product's `*-infra` repo. Fixes
and improvements made here propagate to all products on their next version bump —
no copy-paste drift.

---

## Module catalog

The canonical list of shared modules, their **current version**, and the pin to
use. Bump a consumer by changing its `?ref=<module>-vX.Y.Z`.

### Core infrastructure

| Module | Latest | Pin | Purpose |
| :----- | :----- | :-- | :------ |
| [`network`](modules/network) | `v1.0.0` | `network-v1.0.0` | VPC, 3-tier subnets, NAT, SGs, VPC endpoints (toggleable), flow logs |
| [`rds`](modules/rds) | `v1.0.0` | `rds-v1.0.0` | PostgreSQL, RDS-managed password, Perf Insights, param group, enhanced monitoring |
| [`cache`](modules/cache) | `v1.0.0` | `cache-v1.0.0` | Valkey ElastiCache: serverless (prod) or node (dev cost mode) |
| [`ecs-cluster`](modules/ecs-cluster) | `v1.0.0` | `ecs-cluster-v1.0.0` | ECS cluster + Fargate capacity providers + Container Insights |
| [`ecs-service`](modules/ecs-service) | `v1.0.0` | `ecs-service-v1.0.0` | Fargate service: task def, IAM, ALB, circuit breaker, CPU+mem autoscaling |
| [`ecr`](modules/ecr) | `v1.0.0` | `ecr-v1.0.0` | ECR repositories + lifecycle + optional repo policy |
| [`messaging`](modules/messaging) | `v1.0.0` | `messaging-v1.0.0` | Data-driven SQS (DLQs) + SNS topics + subscriptions |
| [`cdn`](modules/cdn) | `v1.0.0` | `cdn-v1.0.0` | S3 + CloudFront for SPA hosting (OAC, HTTPS, SPA routing) |

### Security & access

| Module | Latest | Pin | Purpose |
| :----- | :----- | :-- | :------ |
| [`iam-oidc`](modules/iam-oidc) | `v1.0.0` | `iam-oidc-v1.0.0` | GitHub OIDC deploy roles (per-env, ecr-push, infra plan/apply) |
| [`secrets`](modules/secrets) | `v1.0.0` | `secrets-v1.0.0` | Secrets Manager (empty secrets) + SSM Parameter Store |
| [`waf`](modules/waf) | `v1.0.0` | `waf-v1.0.0` | WAFv2: managed rules + rate limit + logging + ALB association |
| [`alb-logs`](modules/alb-logs) | `v1.0.0` | `alb-logs-v1.0.0` | S3 bucket + policy for ALB access logs (prod forensics) |

### Operations & cost

| Module | Latest | Pin | Purpose |
| :----- | :----- | :-- | :------ |
| [`dev-scheduler`](modules/dev-scheduler) | `v1.0.0` | `dev-scheduler-v1.0.0` | Off-hours stop RDS + scale ECS to 0 (dev cost saver) |

> **Updating versions:** [Renovate](https://docs.renovatebot.com/) opens PRs when
> a module gets a new tag (consumer repos carry a `renovate.json`). Bump tags via
> `release-please` on merge to `main`.

---

## Usage

Reference a module by git source pinned to a **per-module version tag**:

```hcl
module "cdn" {
  source = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/cdn?ref=cdn-v1.0.0"
  # ... inputs
}
```

> **Pin to a tag** (`?ref=cdn-v1.0.0`) in committed environments. Use `?ref=main`
> only for testing on a branch. Upgrades should be deliberate.

---

## Versioning

Each module is versioned **independently** with a prefixed tag:
`cdn-v1.0.0`, `network-v1.2.0`, etc. This lets a product adopt a new `network`
without being forced to take a new `rds`.

- Backward-compatible additions → minor bump (`cdn-v1.1.0`)
- Breaking input/output changes → major bump (`cdn-v2.0.0`)

---

## Contributing

- One module per directory under `modules/`.
- Every module declares its own `versions.tf` (provider/version constraints) and
  carries a `README.md` documenting inputs/outputs.
- CI runs `tofu fmt -check`, `tofu validate`, and `tflint` on every PR.
- Changes require review (see [`CODEOWNERS`](.github/CODEOWNERS)).
- After merge, tag the module: `git tag cdn-vX.Y.Z && git push origin cdn-vX.Y.Z`.

---

## License

Proprietary and confidential. © QNSC — Quy Nhon Semiconductor. See [`LICENSE`](./LICENSE).
