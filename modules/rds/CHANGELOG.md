# Changelog

## [2.0.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/rds-v1.1.0...rds-v2.0.0) (2026-07-28)


### ⚠ BREAKING CHANGES

* **rds,observability:** `observability`'s `rds_instance_id` now rejects an RDS resource id. Any caller passing `aws_db_instance.id` or the rds module's `instance_id` will fail the plan and must pass `identifier` instead — which is the point: those callers' alarms are already dead.

### Bug Fixes

* **rds,observability:** expose the DB identifier and reject the resource id ([#38](https://github.com/QNSC-VN/qnsc-tf-modules/issues/38)) ([063de04](https://github.com/QNSC-VN/qnsc-tf-modules/commit/063de04b4013f3b67f7ca59ad321dc25bd97884e))
