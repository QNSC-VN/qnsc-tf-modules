# Changelog

## [1.0.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/observability-alerts-v0.1.0...observability-alerts-v1.0.0) (2026-08-29)


### ⚠ BREAKING CHANGES

* **observability-alerts:** grafana_url and grafana_auth variables are removed. The root module must configure the grafana provider now.

### Bug Fixes

* **observability-alerts:** remove internal provider block, inherit from root ([#105](https://github.com/QNSC-VN/qnsc-tf-modules/issues/105)) ([f1e2567](https://github.com/QNSC-VN/qnsc-tf-modules/commit/f1e256730b65dd3e12e4b8faddd5c50c6b0e52ce))

## 0.1.0 (2026-08-28)


### Features

* **observability-alerts:** new module for Grafana Alerting rule groups ([#103](https://github.com/QNSC-VN/qnsc-tf-modules/issues/103)) ([7f16c80](https://github.com/QNSC-VN/qnsc-tf-modules/commit/7f16c80911c1240654aba44373d819b44ac3471b))
