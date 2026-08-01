variable "name" {
  description = "Container name for the sidecar. Must be unique within the task definition."
  type        = string
  default     = "cloudflared"
}

variable "image" {
  description = <<-EOT
    cloudflared image, pinned by tag. NOT `:latest` — the tag is the version, and the
    agent runs with `--no-autoupdate` so the running binary is the reviewed one.
  EOT
  type        = string
  default     = "cloudflare/cloudflared:2026.6.1"
}

variable "tunnel_token_secret_arn" {
  description = <<-EOT
    Secrets Manager reference holding the tunnel's connector token, injected as
    TUNNEL_TOKEN. Accepts either a plain secret ARN or the `<arn>:<key>::` form when
    the value lives inside a bundled JSON secret.

    EMPTY (the default) disables the sidecar entirely — `container_definitions` comes
    back as an empty list — so a stack can adopt this module before a tunnel exists.

    The token is a CREDENTIAL that grants a connector the right to serve the tunnel's
    configured hostnames. It arrives as a secret so it never lands in the task
    definition's plaintext, and it must never be passed as a `--token` command
    argument, where it would appear in `describe-task-definition` output.
  EOT
  type        = string
  default     = ""
}

variable "cpu" {
  description = <<-EOT
    CPU units for the sidecar. 0 means "no reservation" — the container competes for
    the task's pool rather than holding a slice it does not use.

    Deliberately unreserved: cloudflared proxies bytes and is near-idle at this
    traffic, and a reservation would be taken from the app container that actually
    needs it.
  EOT
  type        = number
  default     = 0
}

variable "memory" {
  description = <<-EOT
    Hard memory limit in MiB. 128 is comfortable for a connector at low request
    volume; cloudflared's own guidance is that memory scales with concurrent streams,
    so raise this for a task holding many long-lived SSE connections.
  EOT
  type        = number
  default     = 128
}

variable "app_port" {
  description = "Port the application container listens on. The tunnel forwards to it over the task's shared loopback."
  type        = number
  default     = 3000
}

variable "log_level" {
  description = "cloudflared log level. `info` names the connection and its edge locations at startup, which is what makes a failed handshake diagnosable."
  type        = string
  default     = "info"

  validation {
    condition     = contains(["debug", "info", "warn", "error", "fatal"], var.log_level)
    error_message = "log_level must be one of debug, info, warn, error, fatal."
  }
}

variable "log_group" {
  description = "CloudWatch log group the sidecar writes to. Normally the app's own group, so a failed connection and the request it dropped are in one stream."
  type        = string
}

variable "region" {
  description = "AWS region, for the awslogs driver."
  type        = string
}
