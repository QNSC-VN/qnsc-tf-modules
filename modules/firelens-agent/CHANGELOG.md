# Changelog

## [0.2.2](https://github.com/QNSC-VN/qnsc-tf-modules/compare/firelens-agent-v0.2.1...firelens-agent-v0.2.2) (2026-08-30)


### Bug Fixes

* unblock a stack's first-ever apply from empty state ([#114](https://github.com/QNSC-VN/qnsc-tf-modules/issues/114)) ([ed98a68](https://github.com/QNSC-VN/qnsc-tf-modules/commit/ed98a68cc65473b2ba3f300c2e334c6bca879b3e))

## [0.2.1](https://github.com/QNSC-VN/qnsc-tf-modules/compare/firelens-agent-v0.2.0...firelens-agent-v0.2.1) (2026-08-28)


### Bug Fixes

* **firelens-agent:** stamp OTel resource attrs on log records, fix logs_body_key ([#100](https://github.com/QNSC-VN/qnsc-tf-modules/issues/100)) ([f666391](https://github.com/QNSC-VN/qnsc-tf-modules/commit/f66639170e40d9e7b10d4d0e321f27be94d7c794))

## [0.2.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/firelens-agent-v0.1.3...firelens-agent-v0.2.0) (2026-08-28)


### Features

* **firelens-agent:** drop CloudWatch dual-write, Grafana-only for logs ([#98](https://github.com/QNSC-VN/qnsc-tf-modules/issues/98)) ([dfba356](https://github.com/QNSC-VN/qnsc-tf-modules/commit/dfba356c2377179df2ef88b18e4fa4419b57203b))

## [0.1.3](https://github.com/QNSC-VN/qnsc-tf-modules/compare/firelens-agent-v0.1.2...firelens-agent-v0.1.3) (2026-08-27)


### Bug Fixes

* **firelens-agent:** fix \$message Terraform escaping bug (real crash) ([#96](https://github.com/QNSC-VN/qnsc-tf-modules/issues/96)) ([9b00109](https://github.com/QNSC-VN/qnsc-tf-modules/commit/9b001092cc3d126e938374f0b93e5b723c83f3ae))

## [0.1.2](https://github.com/QNSC-VN/qnsc-tf-modules/compare/firelens-agent-v0.1.1...firelens-agent-v0.1.2) (2026-08-27)


### Bug Fixes

* **firelens-agent:** pin a real init version, fix opentelemetry output field names ([#94](https://github.com/QNSC-VN/qnsc-tf-modules/issues/94)) ([6c67d33](https://github.com/QNSC-VN/qnsc-tf-modules/commit/6c67d336d3aba0857f1f222bead06943a5ed7cd7))

## [0.1.1](https://github.com/QNSC-VN/qnsc-tf-modules/compare/firelens-agent-v0.1.0...firelens-agent-v0.1.1) (2026-08-27)


### Bug Fixes

* **firelens-agent:** Fargate does not support config-file-type s3 ([#90](https://github.com/QNSC-VN/qnsc-tf-modules/issues/90)) ([0532c68](https://github.com/QNSC-VN/qnsc-tf-modules/commit/0532c682f7dfc24ac2d73bf871e12ee5fc08be07))

## 0.1.0 (2026-08-27)


### Features

* **ecs-service:** add execution_s3_bucket_arns, mirroring the existing ([108dced](https://github.com/QNSC-VN/qnsc-tf-modules/commit/108dced3d5a4d104d20eddcc4843813a474fe0b8))
* **firelens-agent:** FireLens log router, dual-write to CloudWatch and Grafana ([#86](https://github.com/QNSC-VN/qnsc-tf-modules/issues/86)) ([108dced](https://github.com/QNSC-VN/qnsc-tf-modules/commit/108dced3d5a4d104d20eddcc4843813a474fe0b8))
