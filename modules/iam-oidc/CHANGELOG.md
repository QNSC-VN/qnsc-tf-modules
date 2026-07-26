# Changelog

## [2.1.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/iam-oidc-v2.0.1...iam-oidc-v2.1.0) (2026-07-26)


### Features

* **iam-oidc:** grant deploy roles secret metadata reads ([#32](https://github.com/QNSC-VN/qnsc-tf-modules/issues/32)) ([eedc168](https://github.com/QNSC-VN/qnsc-tf-modules/commit/eedc1685c47fe1ffe2598049f36295870fd94ac4))

## [2.0.1](https://github.com/QNSC-VN/qnsc-tf-modules/compare/iam-oidc-v2.0.0...iam-oidc-v2.0.1) (2026-07-16)


### Bug Fixes

* **iam-oidc:** grant ecr:DescribeImages to ecr-push role ([#21](https://github.com/QNSC-VN/qnsc-tf-modules/issues/21)) ([041c4ea](https://github.com/QNSC-VN/qnsc-tf-modules/commit/041c4ea19026e87007829986222ea49e1e13f100))

## [2.0.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/iam-oidc-v1.3.0...iam-oidc-v2.0.0) (2026-07-16)


### ⚠ BREAKING CHANGES

* **iam-oidc:** removes the web_deploy_environments input, the web_deploy IAM role/policy, and the web_deploy_role_arns output. Cut as iam-oidc-v2.0.0.

### Features

* **iam-oidc:** grant ecs:ListTasks to deploy role ([2a6291d](https://github.com/QNSC-VN/qnsc-tf-modules/commit/2a6291d56f59fffc408d1db4cffabf646e29add5))


### Code Refactoring

* **iam-oidc:** drop dead web-deploy (S3+CloudFront) roles ([#14](https://github.com/QNSC-VN/qnsc-tf-modules/issues/14)) ([71aedf6](https://github.com/QNSC-VN/qnsc-tf-modules/commit/71aedf6adff283dc98ba1ceb0ec2c74469ddcff2))
