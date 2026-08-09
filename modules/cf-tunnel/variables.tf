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
