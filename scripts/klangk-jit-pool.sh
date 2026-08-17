#!/usr/bin/env bash
# klangk JIT runner pool (runs as a systemd service on keithmoon).
#
# Polls the GitHub Actions API for queued klangk jobs carrying the "nix"
# label; for each (up to MAX_VMS at a time) requests a just-in-time runner
# registration token, then boots a fresh disposable klangk-jit VM. The VM's
# guest service executes exactly one job via `run.sh --jitconfig` and powers
# off; this loop reaps the qemu process, deletes the runner registration if
# it somehow survived, and removes the per-job disk.
#
# Injected by the NixOS module (substituted at build time):
#   @vmClosure@  — klangk-jit VM closure (…/bin/run-klangk-jit-vm)
#   @tokenFile@  — age-secret path holding a PAT with repo administration
# Environment (PATH): curl, jq, qemu-img, flock, coreutils.
set -euo pipefail

REPO="mcdonc/klangk"
LABEL="nix"
STATE=/var/lib/klangk-jit-pool
RUN=/run/klangk-jit-pool
MAX_VMS=4
JOB_TIMEOUT_SECS=5400 # 90 min hard kill per job VM
POLL_SECS=20

VM_RUN="@vmClosure@/bin/run-klangk-jit-vm"
TOKEN_FILE="@tokenFile@"

mkdir -p "$STATE" "$RUN/active"

api() {
  # api METHOD path [json body]
  local method=$1 path=$2 body=${3:-}
  local args=(
    -sS --max-time 30 --retry 2
    -X "$method"
    -H "Authorization: Bearer $(cat "$TOKEN_FILE")"
    -H "Accept: application/vnd.github+json"
  )
  if [ -n "$body" ]; then
    args+=(-H "Content-Type: application/json" -d "$body")
  fi
  curl "${args[@]}" "https://api.github.com/repos/$REPO/$path"
}

active_count() {
  find "$RUN/active" -mindepth 1 -maxdepth 1 -type d | wc -l
}

# Remove a finished job's artifacts and record it done. Best-effort runner
# deregistration (a completed JIT runner deregisters itself → 404 is fine).
cleanup_job() {
  local jobid=$1 dir=$2
  local runner_id disk tmpdir
  runner_id=$(cat "$dir/runner_id" 2>/dev/null || true)
  disk=$(cat "$dir/disk" 2>/dev/null || true)
  tmpdir=$(cat "$dir/tmpdir" 2>/dev/null || true)
  if [ -n "$runner_id" ]; then
    api DELETE "actions/runners/$runner_id" >/dev/null 2>&1 || true
  fi
  [ -n "$disk" ] && rm -f -- "$disk"
  [ -n "$tmpdir" ] && rm -rf -- "$tmpdir"
  rm -rf -- "$dir"
  : >"$STATE/done-$jobid"
}

# Reap dead or timed-out job VMs.
reap() {
  local dir jobid pid started age runner_id
  for dir in "$RUN/active"/*; do
    [ -d "$dir" ] || continue
    jobid=$(basename "$dir")
    pid=$(cat "$dir/pid" 2>/dev/null || true)
    started=$(cat "$dir/started" 2>/dev/null || echo 0)
    age=$(( $(date +%s) - started ))
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      if [ "$age" -ge "$JOB_TIMEOUT_SECS" ]; then
        echo "pool: job $jobid exceeded ${JOB_TIMEOUT_SECS}s; killing VM pid $pid"
        kill "$pid" 2>/dev/null || true
        sleep 2
        kill -9 "$pid" 2>/dev/null || true
      else
        continue
      fi
    fi
    echo "pool: reaping job $jobid (age ${age}s)"
    cleanup_job "$jobid" "$dir"
  done
}

# First queued job carrying the label that we haven't already handled.
next_queued_job() {
  local run_ids run_id jobs_json job
  run_ids=$(api GET "actions/runs?status=queued&per_page=30" |
    jq -r '.workflow_runs[]?.id' 2>/dev/null) || return 0
  for run_id in $run_ids; do
    jobs_json=$(api GET "actions/runs/$run_id/jobs") || continue
    for job in $(echo "$jobs_json" |
      jq -r '.jobs[]? | select(.status == "queued") | select((.labels | index("'"$LABEL"'")) != null) | .id'); do
      if [ ! -e "$STATE/done-$job" ] && [ ! -d "$RUN/active/$job" ]; then
        echo "$job"
        return 0
      fi
    done
  done
  return 0
}

dispatch() {
  local jobid=$1
  local dir="$RUN/active/$jobid"
  local disk="$STATE/overlay-$jobid.qcow2"
  local ts name reg token runner_id pid

  # mkdir is atomic: guards double dispatch across loop iterations.
  if ! mkdir "$dir" 2>/dev/null; then
    return 0
  fi

  ts=$(date +%s)
  name="jit-$jobid-$ts"
  echo "pool: dispatching job $jobid as $name"

  reg=$(api POST "actions/runners/generate-jitconfig" \
    "{\"name\":\"$name\",\"runner_group_id\":1,\"labels\":[\"$LABEL\"]}") || {
    echo "pool: jitconfig request failed for job $jobid" >&2
    rm -rf "$dir"
    return 0
  }
  token=$(echo "$reg" | jq -r '.encoded_jit_config // empty')
  runner_id=$(echo "$reg" | jq -r '.runner.id // empty')
  if [ -z "$token" ] || [ -z "$runner_id" ]; then
    echo "pool: jitconfig response unusable for job $jobid: $reg" >&2
    rm -rf "$dir"
    return 0
  fi

  printf '%s' "$runner_id" >"$dir/runner_id"
  printf '%s' "$disk" >"$dir/disk"
  printf '%s' "$ts" >"$dir/started"

  # Overlay rootfs: fresh copy-on-write of nothing (the store comes over 9p
  # from the host); the sparse image is created on demand by the run script.
  rm -f -- "$disk"

  # Per-job TMPDIR: qemu-vm.nix shares $TMPDIR/xchg as a 9p mount at
  # /tmp/xchg inside the guest. Writing the JIT token there makes it
  # available to the guest runner script without fw_cfg. Each job gets its
  # own TMPDIR so concurrent VMs don't collide.
  local tmpdir
  tmpdir=$(mktemp -d "$RUN/vm-$jobid.XXXXXX")
  mkdir -p "$tmpdir/xchg"
  printf '%s' "$token" >"$tmpdir/xchg/jitconfig"
  # Copy the host's nix DB so the guest can see all host store paths
  # (visible read-only over 9p but not in the guest's empty DB). The
  # guest boot service replaces its DB with this copy — the VM's own
  # closure paths are re-registered via regInfo at initrd time, so they
  # survive the replacement.
  cp /nix/var/nix/db/db.sqlite "$tmpdir/xchg/host-nix-db.sqlite"
  printf '%s' "$tmpdir" >"$dir/tmpdir"

  # USE_TMPDIR=1 tells the qemu-vm.nix run script to reuse our TMPDIR
  # instead of creating a fresh one (it checks both vars).
  USE_TMPDIR=1 TMPDIR="$tmpdir" NIX_DISK_IMAGE="$disk" "$VM_RUN" >"$RUN/console-$jobid.log" 2>&1 &
  printf '%s' "$!" >"$dir/pid"

  echo "pool: job $jobid dispatched (runner $runner_id), console $RUN/console-$jobid.log"
}

# Delete offline jit-* runners left over from crashed pools/VMs.
prune_stale_runners() {
  local id name status
  while IFS=$'\t' read -r id name status; do
    [ -n "$id" ] || continue
    if [ "$status" = "offline" ] && [[ "$name" == jit-* ]]; then
      echo "pool: pruning stale runner $name ($id)"
      api DELETE "actions/runners/$id" >/dev/null 2>&1 || true
    fi
  done < <(api GET "actions/runners?per_page=100" |
    jq -r '.runners[]? | [.id, .name, .status] | @tsv' 2>/dev/null || true)
}

echo "pool: starting (max $MAX_VMS VMs, poll ${POLL_SECS}s)"
prune_stale_runners

while true; do
  reap
  if [ "$(active_count)" -lt "$MAX_VMS" ]; then
    jobid=$(next_queued_job)
    if [ -n "$jobid" ]; then
      dispatch "$jobid"
      continue # dispatch again immediately if slots remain
    fi
  fi
  sleep "$POLL_SECS"
done
