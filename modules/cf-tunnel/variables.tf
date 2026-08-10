variable "account_id" {
  type        = string
  description = "Cloudflare account that owns the tunnel."
}

variable "name" {
  type        = string
  description = <<-EOT
    Tunnel name, e.g. "qnsc-kb-develop".

    One tunnel per PRODUCT per ENVIRONMENT, never shared. A tunnel maps a hostname to
    whichever connectors hold its token, so a shared tunnel would let a develop task
    serve production traffic.
  EOT
}

variable "hostname" {
  type        = string
  default     = ""
  description = <<-EOT
    Public hostname this tunnel serves, e.g. "kb-api-dev.qnsc.vn".

    Empty creates NO ingress rule, which leaves the connector answering 503 to everything
    — cloudflared's own warning is "No ingress rules were defined in provided config (if
    any) nor from the cli". Only leave it empty for a tunnel whose routing is managed
    elsewhere.
  EOT
}

variable "service" {
  type        = string
  default     = "http://localhost:8000"
  description = <<-EOT
    Where the connector forwards matching requests. `localhost` is correct for a
    cloudflared sidecar: under ECS awsvpc every container in a task shares one network
    namespace, so the application is reachable without exposing a port.
  EOT
}

variable "config_src" {
  type    = string
  default = "cloudflare"

  description = <<-EOT
    Where the connector gets its routing: "cloudflare" (served by Cloudflare, what this
    module manages) or "local" (a config file or --url on the connector itself).

    ADOPTING AN EXISTING TUNNEL: set this to whatever the tunnel already has, or the
    import produces a diff that rewrites how a working connector is configured. A
    dashboard-created tunnel with a public hostname is normally "cloudflare".

    "local" is almost always wrong for a sidecar handed only TUNNEL_TOKEN — it has no
    local config, so it connects, reports healthy, and returns 503 to everything.
  EOT

  validation {
    condition     = contains(["cloudflare", "local"], var.config_src)
    error_message = "config_src must be \"cloudflare\" or \"local\"."
  }
}
