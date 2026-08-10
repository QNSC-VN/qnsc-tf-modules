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
