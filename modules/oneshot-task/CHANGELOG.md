# Changelog

## [2.0.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/oneshot-task-v1.0.1...oneshot-task-v2.0.0) (2026-07-27)


### ⚠ BREAKING CHANGES

* `keep_tagged_count` and `tag_prefix_list` are replaced by `keep_release_count` / `release_tag_prefix` and `keep_build_count` / `build_tag_prefix`. No caller in this organisation passed the removed variables.

### Features

* cost-posture fixes across ecs-cluster, ecs-service, observability, secrets, ecr ([#36](https://github.com/QNSC-VN/qnsc-tf-modules/issues/36)) ([9a2eb3b](https://github.com/QNSC-VN/qnsc-tf-modules/commit/9a2eb3bea6eb3995234cab5938f137b2c69efb0f))

## [1.0.1](https://github.com/QNSC-VN/qnsc-tf-modules/compare/oneshot-task-v1.0.0...oneshot-task-v1.0.1) (2026-07-16)


### Bug Fixes

* **modules:** satisfy tflint — add version constraints + waf ARN ignore ([a6cd33f](https://github.com/QNSC-VN/qnsc-tf-modules/commit/a6cd33fa84d68480e121e005df01c96edbf3cd67))
* **modules:** satisfy tflint — version constraints + waf ARN ignore ([453d5f2](https://github.com/QNSC-VN/qnsc-tf-modules/commit/453d5f2fc89a50235a9ead5a523efda66cc44609))
