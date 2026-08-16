# Changelog

## [1.3.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/network-v1.2.0...network-v1.3.0) (2026-08-16)


### Features

* **network:** add nat_type variable for fck-nat instance support ([e07ea2a](https://github.com/QNSC-VN/qnsc-tf-modules/commit/e07ea2ae744352cb0c1052aeaa281fe7310bee26))
* **network:** add shared network module ([f60a826](https://github.com/QNSC-VN/qnsc-tf-modules/commit/f60a826fdbd52820015555959492c03e3d0e50d0))
* **network:** optional SSM bastion on the NAT instance ([#74](https://github.com/QNSC-VN/qnsc-tf-modules/issues/74)) ([a9a2352](https://github.com/QNSC-VN/qnsc-tf-modules/commit/a9a2352d67a3e24140e7a96bf2b51f94536aeacc))


### Bug Fixes

* **network,cdn:** ASCII description for nat SG; cdn supports aliases=[] with default cert ([2b0c926](https://github.com/QNSC-VN/qnsc-tf-modules/commit/2b0c9263c5f5c27141afa59ed75082b18772442d))
* **network:** use aws_ami data source for fck-nat instead of SSM community namespace ([61c81c8](https://github.com/QNSC-VN/qnsc-tf-modules/commit/61c81c8c303df0c93d384a0ef2c37072c3ad083b))

## [1.2.0](https://github.com/QNSC-VN/qnsc-tf-modules/compare/network-v1.1.2...network-v1.2.0) (2026-08-16)


### Features

* **network:** optional SSM bastion on the NAT instance ([#74](https://github.com/QNSC-VN/qnsc-tf-modules/issues/74)) ([a9a2352](https://github.com/QNSC-VN/qnsc-tf-modules/commit/a9a2352d67a3e24140e7a96bf2b51f94536aeacc))
