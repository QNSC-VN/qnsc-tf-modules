"""Stop/start dev resources on a schedule to cut off-hours cost.

Invoked by two EventBridge schedules with {"action": "stop"} or {"action":
"start"}. Targets resources by tag (default AutoStop=true):

  - RDS instances   -> stop / start  (skipped if Multi-AZ -- AWS can't stop those)
  - ECS services    -> desired_count 0 / restore (original kept in a tag)

Startup order: RDS is started first and polled until available before ECS
services are scaled up. This prevents ECS tasks from failing health checks
while waiting for the database to accept connections.

Idempotent and best-effort: logs and continues on per-resource errors so one
failure doesn't block the rest.
"""
import os
import time
import boto3

TAG_KEY = os.environ.get("TAG_KEY", "AutoStop")
TAG_VAL = os.environ.get("TAG_VALUE", "true")
RESTORE_TAG = "AutoStopDesiredCount"  # where we stash the pre-stop ECS count
RDS_WAIT_TIMEOUT = int(os.environ.get("RDS_WAIT_TIMEOUT", "480"))  # seconds
RDS_POLL_INTERVAL = 15  # seconds

rds = boto3.client("rds")
ecs = boto3.client("ecs")
tagging = boto3.client("resourcegroupstaggingapi")


def _tagged(resource_type):
    """Return all resource ARNs matching the AutoStop tag."""
    arns = []
    paginator = tagging.get_paginator("get_resources")
    for page in paginator.paginate(
        TagFilters=[{"Key": TAG_KEY, "Values": [TAG_VAL]}],
        ResourceTypeFilters=[resource_type],
    ):
        arns += [r["ResourceARN"] for r in page["ResourceTagMappingList"]]
    return arns


def _wait_rds_available(ident, timeout=RDS_WAIT_TIMEOUT):
    """Poll until RDS instance is available or timeout is reached."""
    elapsed = 0
    while elapsed < timeout:
        time.sleep(RDS_POLL_INTERVAL)
        elapsed += RDS_POLL_INTERVAL
        status = rds.describe_db_instances(DBInstanceIdentifier=ident)[
            "DBInstances"
        ][0]["DBInstanceStatus"]
        print(f"  [{elapsed}s/{timeout}s] RDS {ident}: {status}")
        if status == "available":
            return True
    print(f"RDS {ident} did not become available within {timeout}s")
    return False


def _handle_rds(action):
    """Stop or start all tagged RDS instances. Returns list of started identifiers."""
    started = []
    for arn in _tagged("rds:db"):
        ident = arn.split(":")[-1]
        try:
            db = rds.describe_db_instances(DBInstanceIdentifier=ident)["DBInstances"][0]
            if db.get("MultiAZ"):
                print(f"skip RDS {ident}: Multi-AZ cannot be stopped")
                continue
            status = db["DBInstanceStatus"]
            if action == "stop" and status == "available":
                rds.stop_db_instance(DBInstanceIdentifier=ident)
                print(f"stopping RDS {ident}")
            elif action == "start" and status == "stopped":
                rds.start_db_instance(DBInstanceIdentifier=ident)
                print(f"starting RDS {ident}")
                started.append(ident)
            else:
                print(f"RDS {ident} already {status}, no-op for {action}")
        except Exception as e:  # noqa: BLE001 - best effort
            print(f"RDS {ident} {action} failed: {e}")
    return started


def _handle_ecs(action):
    """Scale ECS services to 0 (stop) or restore to saved desired count (start)."""
    for arn in _tagged("ecs:service"):
        # arn: .../cluster-name/service-name
        _, _, tail = arn.partition("service/")
        cluster, _, service = tail.partition("/")
        try:
            if action == "stop":
                cur = ecs.describe_services(cluster=cluster, services=[service])["services"][0]
                desired = cur["desiredCount"]
                if desired > 0:
                    ecs.tag_resource(resourceArn=arn, tags=[{"key": RESTORE_TAG, "value": str(desired)}])
                    ecs.update_service(cluster=cluster, service=service, desiredCount=0)
                    print(f"scaled ECS {service} {desired}->0")
            else:  # start
                tags = {t["key"]: t["value"] for t in ecs.list_tags_for_resource(resourceArn=arn)["tags"]}
                restore = int(tags.get(RESTORE_TAG, "1"))
                ecs.update_service(cluster=cluster, service=service, desiredCount=restore)
                print(f"scaled ECS {service} 0->{restore}")
        except Exception as e:  # noqa: BLE001 - best effort
            print(f"ECS {service} {action} failed: {e}")


def handler(event, _context):
    action = (event or {}).get("action", "stop")
    if action not in ("stop", "start"):
        raise ValueError(f"action must be stop|start, got {action!r}")
    print(f"dev-scheduler action={action} tag={TAG_KEY}={TAG_VAL}")

    if action == "stop":
        # Stop order: ECS first (drain connections), then RDS
        _handle_ecs(action)
        _handle_rds(action)
    else:
        # Start order: RDS first, wait until available, then ECS.
        # This prevents ECS tasks from crashing while DB is still warming up.
        started_rds = _handle_rds(action)
        if started_rds:
            print(f"Waiting for {len(started_rds)} RDS instance(s) before starting ECS...")
            for ident in started_rds:
                if not _wait_rds_available(ident):
                    print(f"WARNING: RDS {ident} not available yet -- starting ECS anyway")
        _handle_ecs(action)

    return {"action": action, "ok": True}
