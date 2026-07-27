# Changelog

## [2.0.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/ecs-cluster-v1.0.0...ecs-cluster-v2.0.0) (2026-07-27)


### ⚠ BREAKING CHANGES

* `keep_tagged_count` and `tag_prefix_list` are replaced by `keep_release_count` / `release_tag_prefix` and `keep_build_count` / `build_tag_prefix`. No caller in this organisation passed the removed variables.

### Features

* cost-posture fixes across ecs-cluster, ecs-service, observability, secrets, ecr ([#36](https://github.com/QNSC-VN/qnsc-tf-modules/issues/36)) ([9a2eb3b](https://github.com/QNSC-VN/qnsc-tf-modules/commit/9a2eb3bea6eb3995234cab5938f137b2c69efb0f))
