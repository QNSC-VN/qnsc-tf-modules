# cloudflare-turnstile

A Cloudflare **Turnstile** widget (bot / CAPTCHA challenge) for a public form —
e.g. the qnsc-landing contact form. The edge-side counterpart to the app's
server-side verification.

Provisioned **centrally in the platform** (where the Cloudflare provider + admin
token already live for `edge` / `storage`), so the Turnstile admin scope is not
copied into every product's CI — the same centralization rule the
[`cf-r2`](../cf-r2) buckets follow.

The widget exposes two values:

| Output | Sensitivity | Where it goes |
|--------|-------------|---------------|
| `sitekey` | **public** | baked into the client (`PUBLIC_TURNSTILE_SITEKEY` or hardcoded — it appears in page HTML anyway) |
| `secret` | **sensitive** | set **out-of-band** as the Pages `TURNSTILE_SECRET` env var (same handling as `RESEND_API_KEY`) — never committed, never injected into app config from Terraform |

This keeps the platform convention: **non-secret config may be Terraform-managed;
secrets are provisioned out-of-band and never live in an app's config/state.**

> **Provider major:** requires the Cloudflare provider **v4** (the resource
> schema here is v4). Instantiate from a v4 stack (`edge`); bump to v5 when that
> stack migrates (see the org-wide v4→v5 migration).

## Usage

```hcl
module "landing_turnstile" {
  source = "git::https://github.com/quynhonsemiconductor/qnsc-tf-modules.git//modules/cloudflare-turnstile?ref=cloudflare-turnstile-v1.0.0"

  account_id = var.cloudflare_account_id
  name       = "qnsc-landing"
  domains    = [var.certificate_domain, "www.${var.certificate_domain}"]
  mode       = "managed"
}
```

Then, out-of-band (once, like any other Pages secret):

```sh
# sitekey is public — read it and bake into the client
tofu output -raw landing_turnstile_sitekey

# secret — set it directly on the Pages project, never through app config
wrangler pages secret put TURNSTILE_SECRET --project-name qnsc-landing
# (paste the value from `tofu output -raw landing_turnstile_secret`)
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `account_id` | string | — | Cloudflare account ID that owns the widget. |
| `name` | string | — | Widget name shown in the dashboard. |
| `domains` | list(string) | — | Allowed hostnames (e.g. `["qnsc.vn","www.qnsc.vn"]`). Add `localhost` only for local testing. |
| `mode` | string | `managed` | `managed`, `non-interactive`, or `invisible`. |
| `region` | string | `world` | Widget region. |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `sitekey` | no | Public sitekey — bake into the client. |
| `secret` | **yes** | Set out-of-band as Pages `TURNSTILE_SECRET`. |
