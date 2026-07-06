#!/usr/bin/env bash
# =============================================================================
# dev-env.sh — operator helper for the dev-scheduler cost-saver.
#
# Ships with this shared module: it drives the RDS + ECS resources that any
# product's dev-scheduler manages (rally, opshub, ...). Select the target with
# PREFIX (the "<product>-<env>" name prefix). The env auto-stops at 20:00 and
# auto-starts at 08:00 (Mon-Fri, Asia/Ho_Chi_Minh) via two EventBridge
# schedules + a tag-driven Lambda; this script lets you drive it manually and
# toggle those schedules.
#
# Usage:
#   ./dev-env.sh start        # bring the env UP now (RDS -> wait -> ECS)
#   ./dev-env.sh stop         # take the env DOWN now (ECS -> RDS)
#   ./dev-env.sh status       # show RDS / ECS / schedule state
#   ./dev-env.sh auto-off     # DISABLE the auto stop/start schedules
#   ./dev-env.sh auto-on      # RE-ENABLE the auto stop/start schedules
#
# Target selection (env overrides):
#   PREFIX   resource name prefix   (default: rally-develop)
#   REGION   AWS region             (default: ap-southeast-1)
#
# Examples:
#   ./dev-env.sh start                       # rally develop
#   PREFIX=opshub-develop ./dev-env.sh start # opshub develop
#
# Requires: awscli v2, python3. Uses your current AWS credentials.
# =============================================================================
set -euo pipefail

PREFIX="${PREFIX:-rally-develop}"
REGION="${REGION:-ap-southeast-1}"
STOP_SCHED="${PREFIX}-dev-stop"
START_SCHED="${PREFIX}-dev-start"

aws() { command aws --region "$REGION" "$@"; }

RESTORE_TAG="AutoStopDesiredCount"  # same tag the dev-scheduler Lambda uses

ecs_service_arns() {
  aws ecs list-services --cluster "$PREFIX" --query 'serviceArns' --output text 2>/dev/null || true
}

# Bring the env UP: start RDS, wait until available, then restore ECS counts.
# Done directly (not via the Lambda) because the Lambda's 120s timeout is too
# short for a cold RDS start, which would leave ECS scaled to 0.
start() {
  local st
  st="$(aws rds describe-db-instances --db-instance-identifier "$PREFIX" \
        --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo missing)"
  if [[ "$st" == "stopped" ]]; then
    echo ">> starting RDS ${PREFIX}"
    aws rds start-db-instance --db-instance-identifier "$PREFIX" >/dev/null
  else
    echo ">> RDS ${PREFIX}: ${st}"
  fi
  echo ">> waiting for RDS to become available (can take a few minutes)..."
  aws rds wait db-instance-available --db-instance-identifier "$PREFIX"
  echo ">> RDS available"
  local arn svc restore
  for arn in $(ecs_service_arns); do
    svc="${arn##*/}"
    restore="$(aws ecs list-tags-for-resource --resource-arn "$arn" \
               --query "tags[?key=='${RESTORE_TAG}'].value | [0]" --output text 2>/dev/null || true)"
    [[ -z "$restore" || "$restore" == "None" ]] && restore=1
    echo ">> scaling ECS ${svc} -> ${restore}"
    aws ecs update-service --cluster "$PREFIX" --service "$svc" --desired-count "$restore" >/dev/null
  done
  echo "Done. ECS tasks should pass ALB health in ~1-2 min."
}

# Take the env DOWN: stash each ECS desired count in a tag, scale to 0, stop RDS.
stop() {
  local arn svc desired
  for arn in $(ecs_service_arns); do
    svc="${arn##*/}"
    desired="$(aws ecs describe-services --cluster "$PREFIX" --services "$svc" \
               --query 'services[0].desiredCount' --output text 2>/dev/null || echo 0)"
    if [[ "$desired" =~ ^[0-9]+$ && "$desired" -gt 0 ]]; then
      aws ecs tag-resource --resource-arn "$arn" --tags "key=${RESTORE_TAG},value=${desired}" >/dev/null
      aws ecs update-service --cluster "$PREFIX" --service "$svc" --desired-count 0 >/dev/null
      echo ">> scaled ECS ${svc} ${desired}->0"
    fi
  done
  local st
  st="$(aws rds describe-db-instances --db-instance-identifier "$PREFIX" \
        --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo missing)"
  if [[ "$st" == "available" ]]; then
    echo ">> stopping RDS ${PREFIX}"
    aws rds stop-db-instance --db-instance-identifier "$PREFIX" >/dev/null
  else
    echo ">> RDS ${PREFIX}: ${st} (no stop needed)"
  fi
}

# Re-apply a schedule with a new State (EventBridge update-schedule replaces the
# whole definition, so we read the current one and only flip State).
set_state() {
  local name="$1" state="$2"
  local j; j="$(aws scheduler get-schedule --name "$name")"
  local expr tz ftw target
  expr="$(printf '%s' "$j" | python3 -c 'import sys,json;print(json.load(sys.stdin)["ScheduleExpression"])')"
  tz="$(printf '%s' "$j"   | python3 -c 'import sys,json;print(json.load(sys.stdin)["ScheduleExpressionTimezone"])')"
  ftw="$(printf '%s' "$j"  | python3 -c 'import sys,json;print(json.dumps(json.load(sys.stdin)["FlexibleTimeWindow"]))')"
  target="$(printf '%s' "$j" | python3 -c 'import sys,json;print(json.dumps(json.load(sys.stdin)["Target"]))')"
  aws scheduler update-schedule --name "$name" --state "$state" \
    --schedule-expression "$expr" --schedule-expression-timezone "$tz" \
    --flexible-time-window "$ftw" --target "$target" >/dev/null
  echo "   ${name} -> ${state}"
}

status() {
  echo "== RDS =="
  aws rds describe-db-instances --db-instance-identifier "$PREFIX" \
    --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo "  (not found)"
  echo "== ECS services (cluster ${PREFIX}) =="
  local svcs; svcs="$(aws ecs list-services --cluster "$PREFIX" --query 'serviceArns' --output text 2>/dev/null || true)"
  if [[ -n "$svcs" ]]; then
    aws ecs describe-services --cluster "$PREFIX" --services $svcs \
      --query 'services[].{name:serviceName,desired:desiredCount,running:runningCount}' --output table
  else
    echo "  (no services)"
  fi
  echo "== Schedules =="
  for s in "$STOP_SCHED" "$START_SCHED"; do
    aws scheduler get-schedule --name "$s" \
      --query '{name:Name,state:State,cron:ScheduleExpression,tz:ScheduleExpressionTimezone}' --output table 2>/dev/null || true
  done
}

case "${1:-}" in
  start)    start ;;
  stop)     stop ;;
  status)   status ;;
  auto-off) set_state "$STOP_SCHED" DISABLED; set_state "$START_SCHED" DISABLED
            echo "Auto stop/start DISABLED. Env stays in its current state until you run 'auto-on'." ;;
  auto-on)  set_state "$STOP_SCHED" ENABLED; set_state "$START_SCHED" ENABLED
            echo "Auto stop/start RE-ENABLED (stop 20:00 / start 08:00, Mon-Fri, Asia/Ho_Chi_Minh)." ;;
  *) echo "Usage: $0 {start|stop|status|auto-off|auto-on}   (PREFIX=${PREFIX} REGION=${REGION})" >&2; exit 2 ;;
esac
