output "container_definitions" {
  description = <<-EOT
    Sidecar container definition(s), ready to pass to `ecs-service`'s
    `additional_containers`. An EMPTY list when `tunnel_token_secret_arn` is unset, so
    the module is a no-op until a tunnel exists.
  EOT
  value = local.enabled ? [
    {
      name    = var.name
      image   = var.image
      command = local.command

      # ESSENTIAL, unlike the observability sidecar — and the difference is the point.
      # A dead collector loses telemetry; a dead connector loses INGRESS, so the task
      # is serving nothing while ECS still counts it as running. Marking it essential
      # means the task dies and is replaced, which is the correct response to losing
      # the only path to the application.
      essential = true

      cpu               = var.cpu
      memory            = var.memory
      memoryReservation = var.memory

      # TUNNEL_TOKEN, never a `--token` argument: command arguments are visible in
      # `aws ecs describe-task-definition`, which every deploy role can read.
      secrets = [
        { name = "TUNNEL_TOKEN", valueFrom = var.tunnel_token_secret_arn },
      ]

      # No `environment` block, deliberately.
      #
      # The metrics listener is set with the `--metrics` FLAG in local.command, not
      # here: this version of cloudflared exposes no TUNNEL_METRICS variable, so an
      # environment entry would be silently ignored and the readiness endpoint would
      # never bind. (`--loglevel` does have TUNNEL_LOGLEVEL, but it is passed as a flag
      # alongside --metrics so the whole invocation reads in one place.)
      #
      # TUNNEL_ORIGIN_CERT is deliberately unset. A token-managed (remote-config)
      # tunnel carries its credentials in the token; pointing at an origin cert makes
      # cloudflared look for a file that does not exist and fail at startup.

      # NO healthCheck, and this is a deliberate omission rather than a gap.
      #
      # The obvious probe is `/ready` on the metrics port, which returns 200 only when
      # the connector holds live edge connections — exactly the "running but not
      # serving" case worth catching. It cannot be expressed here: an ECS healthCheck
      # runs INSIDE the container, and this image is distroless. Verified directly
      # against cloudflare/cloudflared:2026.6.1 —
      #
      #   exec: "/bin/sh": stat /bin/sh: no such file or directory
      #
      # and there is no wget, curl or busybox either. Both CMD and CMD-SHELL forms
      # therefore fail permanently, which would report a perfectly healthy connector as
      # unhealthy and make ECS kill the task in a loop. The same trap is documented on
      # the observability-agent sidecar for the same reason.
      #
      # `essential = true` is the real guard: if the connector exits, the task dies and
      # is replaced. What that does NOT cover is a connector that stays up while its
      # edge connections are gone. Detect that from OUTSIDE the task — a Cloudflare
      # health check or a synthetic probe against the public hostname — which is the
      # same external monitoring that has to replace the ALB target-health alarm.

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.name
        }
      }
    }
  ] : []
}

output "secret_arns" {
  description = <<-EOT
    Secret ARNs the task EXECUTION role must be able to read. Concat into
    `ecs-service`'s `secret_arns`, or the task fails to start with
    ResourceInitializationError.

    When the token lives in a bundled JSON secret, this strips the `:<key>::`
    valueFrom suffix — an IAM statement built from the reference form matches nothing
    while still applying cleanly.
  EOT
  value       = local.enabled ? [join(":", slice(split(":", var.tunnel_token_secret_arn), 0, 7))] : []
}

output "enabled" {
  description = "Whether the sidecar is actually produced. Gate the ALB target-group attachment on the inverse: a task served by a tunnel must not also be an ALB target."
  value       = local.enabled
}

output "origin_url" {
  description = "The origin the tunnel should be configured to forward to, via the task's shared loopback. Set this as the service's origin in the Cloudflare tunnel's public-hostname route."
  value       = "http://127.0.0.1:${var.app_port}"
}
