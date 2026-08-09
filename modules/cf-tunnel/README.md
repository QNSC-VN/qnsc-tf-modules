# cf-tunnel

Creates a Cloudflare Tunnel and returns its id, CNAME target and connector token.

```hcl
module "tunnel" {
  source     = "git::https://github.com/QNSC-VN/qnsc-tf-modules.git//modules/cf-tunnel?ref=cf-tunnel-v1.0.0"
  account_id = var.cloudflare_account_id
  name       = "${var.product}-${var.env}"
}
```

| Output | Use |
| :--- | :--- |
| `id` | the tunnel UUID |
| `cname` | CNAME target for the API hostname — pass to `dns-record`, `proxied = true` |
| `token` | `TUNNEL_TOKEN` for the cloudflared sidecar (sensitive) |

## The trade

`token` is a live credential and it lives in Terraform **state**. Acceptable where the
state bucket is KMS-encrypted and readable only by the infra-apply role, which already
holds `AdministratorAccess` — the token grants nothing that reading the state did not
already imply.

A product that cannot accept that keeps creating tunnels out of band and passes the id
in as a variable. Both shapes work.

## Adopting a tunnel that already exists

Import rather than replace, or the hostname's CNAME target changes and every running
connector is left holding a token that no longer authenticates:

```bash
tofu import 'module.tunnel.cloudflare_zero_trust_tunnel_cloudflared.this' '<account_id>/<tunnel_id>'
tofu plan     # expect NO changes
```

The plan is clean because the resource ignores `secret` — an imported tunnel keeps the
one Cloudflare already has. Confirm the plan really is empty before applying; a diff
here means a tunnel replacement and an outage until the next deploy.
