# Changelog

## [4.1.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/observability-v4.0.0...observability-v4.1.0) (2026-07-31)


### Features

* **observability:** stop an idled environment paging about being idle ([#42](https://github.com/QNSC-VN/qnsc-tf-modules/issues/42)) ([47fc8bd](https://github.com/QNSC-VN/qnsc-tf-modules/commit/47fc8bd5a40829379b6720f01da731a7d0fa69b7))

## [4.0.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/observability-v3.0.0...observability-v4.0.0) (2026-07-29)


### ⚠ BREAKING CHANGES

* **observability:** `alb_latency` moves from `count` to `for_each` and is renamed `<name>-<tg>-alb-latency-high`. It now requires `target_group_arns`; callers passing only `alb_arn` lose the latency alarm until they wire it.

### Features

* **observability:** scope the latency alarm per target group and gate it on traffic ([#40](https://github.com/QNSC-VN/qnsc-tf-modules/issues/40)) ([47d1360](https://github.com/QNSC-VN/qnsc-tf-modules/commit/47d136016492faf1c99c8daa826d33ee174d9199))

## [3.0.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/observability-v2.0.0...observability-v3.0.0) (2026-07-28)


### ⚠ BREAKING CHANGES

* **rds,observability:** `observability`'s `rds_instance_id` now rejects an RDS resource id. Any caller passing `aws_db_instance.id` or the rds module's `instance_id` will fail the plan and must pass `identifier` instead — which is the point: those callers' alarms are already dead.

### Bug Fixes

* **rds,observability:** expose the DB identifier and reject the resource id ([#38](https://github.com/QNSC-VN/qnsc-tf-modules/issues/38)) ([063de04](https://github.com/QNSC-VN/qnsc-tf-modules/commit/063de04b4013f3b67f7ca59ad321dc25bd97884e))

## [2.0.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/observability-v1.0.1...observability-v2.0.0) (2026-07-27)


### ⚠ BREAKING CHANGES

* `keep_tagged_count` and `tag_prefix_list` are replaced by `keep_release_count` / `release_tag_prefix` and `keep_build_count` / `build_tag_prefix`. No caller in this organisation passed the removed variables.

### Features

* cost-posture fixes across ecs-cluster, ecs-service, observability, secrets, ecr ([#36](https://github.com/QNSC-VN/qnsc-tf-modules/issues/36)) ([9a2eb3b](https://github.com/QNSC-VN/qnsc-tf-modules/commit/9a2eb3bea6eb3995234cab5938f137b2c69efb0f))

## [1.0.1](https://github.com/QNSC-VN/qnsc-tf-modules/compare/observability-v1.0.0...observability-v1.0.1) (2026-07-16)


### Bug Fixes

* **modules:** satisfy tflint — add version constraints + waf ARN ignore ([a6cd33f](https://github.com/QNSC-VN/qnsc-tf-modules/commit/a6cd33fa84d68480e121e005df01c96edbf3cd67))
* **modules:** satisfy tflint — version constraints + waf ARN ignore ([453d5f2](https://github.com/QNSC-VN/qnsc-tf-modules/commit/453d5f2fc89a50235a9ead5a523efda66cc44609))
