# qnsc-tf-modules

Shared, versioned OpenTofu/Terraform modules for all QNSC products.

This is the infrastructure counterpart to [`qnsc-gitops`](https://github.com/QNSC-VN/qnsc-gitops)
(shared CI actions): reusable Terraform building blocks live here once, are
versioned per module, and are consumed by every product's `*-infra` repo. Fixes
and improvements made here propagate to all products on their next version bump —
no copy-paste drift.

---

## Available modules

| Module | Status | Description |
| :----- | :----- | :---------- |
| [`cdn`](modules/cdn) | ✅ available | S3 + CloudFront for SPA hosting (OAC, HTTPS, SPA routing) |
| `ecr` | ⏳ planned | ECR repositories with lifecycle policies |
| [`ecs-cluster`](modules/ecs-cluster) | ✅ available | ECS cluster + Fargate capacity providers + Container Insights |
| `ecs-service` | ⏳ planned | Reusable task def + service + ALB rule + autoscaling |
| `network` | ⏳ planned | VPC, subnets, NAT, security groups, endpoints |
| `rds` | ⏳ planned | RDS PostgreSQL + Secrets Manager |
| `messaging` | ⏳ planned | SQS queues (with DLQs) + SNS topics |
| `secrets` | ⏳ planned | Secrets Manager + SSM scaffolding |
| `waf` | ⏳ planned | WAF v2 WebACL (common rules + rate limiting) |
| `iam-oidc` | ⏳ planned | GitHub OIDC provider + deploy roles |

Migration of the remaining modules from product repos is tracked in
[`qnsc-infra/docs/shared-modules-migration.md`](https://github.com/QNSC-VN/qnsc-infra/blob/main/docs/shared-modules-migration.md).

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
