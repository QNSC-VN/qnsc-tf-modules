# Changelog

## [2.1.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/secrets-v2.0.0...secrets-v2.1.0) (2026-07-31)


### Features

* **secrets:** optionally bundle a secret set into one JSON secret ([#48](https://github.com/QNSC-VN/qnsc-tf-modules/issues/48)) ([ad2c10d](https://github.com/QNSC-VN/qnsc-tf-modules/commit/ad2c10dcc9df7281582ec55a2e2575374b252dd4))

## [2.0.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/secrets-v1.1.0...secrets-v2.0.0) (2026-07-27)


### ⚠ BREAKING CHANGES

* `keep_tagged_count` and `tag_prefix_list` are replaced by `keep_release_count` / `release_tag_prefix` and `keep_build_count` / `build_tag_prefix`. No caller in this organisation passed the removed variables.

### Features

* cost-posture fixes across ecs-cluster, ecs-service, observability, secrets, ecr ([#36](https://github.com/QNSC-VN/qnsc-tf-modules/issues/36)) ([9a2eb3b](https://github.com/QNSC-VN/qnsc-tf-modules/commit/9a2eb3bea6eb3995234cab5938f137b2c69efb0f))

## [1.1.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/secrets-v1.0.0...secrets-v1.1.0) (2026-07-16)


### Features

* **dns-record:** adopt orphaned records via allow_overwrite ([#4](https://github.com/QNSC-VN/qnsc-tf-modules/issues/4)) ([e93b1ed](https://github.com/QNSC-VN/qnsc-tf-modules/commit/e93b1ed72b81aa23327f0139efcfd62bc9b6008f))
