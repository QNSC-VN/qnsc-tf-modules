# Changelog

## [2.1.1](https://github.com/QNSC-VN/qnsc-tf-modules/compare/rds-v2.1.0...rds-v2.1.1) (2026-08-13)


### Bug Fixes

* **rds:** do not put the product CMK on the exported log groups ([#72](https://github.com/QNSC-VN/qnsc-tf-modules/issues/72)) ([e00a043](https://github.com/QNSC-VN/qnsc-tf-modules/commit/e00a043aa8c13d7b39098fd5769abb1ae110c8bc))

## [2.1.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/rds-v2.0.0...rds-v2.1.0) (2026-08-13)


### Features

* **rds:** manage retention on the exported log groups ([#70](https://github.com/QNSC-VN/qnsc-tf-modules/issues/70)) ([c35f966](https://github.com/QNSC-VN/qnsc-tf-modules/commit/c35f966596b0608446eb994a1f7869d3eb1df9f2))

## [2.0.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/rds-v1.1.0...rds-v2.0.0) (2026-07-28)


### ⚠ BREAKING CHANGES

* **rds,observability:** `observability`'s `rds_instance_id` now rejects an RDS resource id. Any caller passing `aws_db_instance.id` or the rds module's `instance_id` will fail the plan and must pass `identifier` instead — which is the point: those callers' alarms are already dead.

### Bug Fixes

* **rds,observability:** expose the DB identifier and reject the resource id ([#38](https://github.com/QNSC-VN/qnsc-tf-modules/issues/38)) ([063de04](https://github.com/QNSC-VN/qnsc-tf-modules/commit/063de04b4013f3b67f7ca59ad321dc25bd97884e))
