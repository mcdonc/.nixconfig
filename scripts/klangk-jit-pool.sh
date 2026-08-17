#!/usr/bin/env bash
# klangk JIT runner pool (runs as a systemd service on keithmoon).
#
# Polls the GitHub Actions API for queued jobs carrying the "nix" label;
# boots fresh disposable klangk-jit VMs (up to MAX_VMS) so GitHub can
# assign jobs to them. The pool does NOT track which job goes to which
# VM — the JIT runner picks up whatever GitHub assigns.
#
# Injected by the NixOS module (substituted at build time):
#   @vmClosure@  — klangk-jit VM closure (…/bin/run-klangk-jit-vm)
#   @tokenFile@  — age-secret path holding a PAT with repo administration
# Environment (PATH): curl, jq, qemu-img, flock, coreutils.
set -euo pipefail

REPO="mcdonc/klangk"
LABEL="nix"
RUN=/run/klangk-jit-pool
MAX_VMS=4
VM_TIMEOUT_SECS=3600 # 60 min hard kill per VM
POLL_SECS=20

VM_RUN="@vmClosure@/bin/run-klangk-jit-vm"
TOKEN_FILE="@tokenFile@"

mkdir -p "$RUN/active"

api() {
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
  find "$RUN/active" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l
}

# Count queued jobs with our label across all queued workflow runs.
queued_job_count() {
  local count=0 run_ids run_id jobs_json n
  run_ids=$(api GET "actions/runs?status=queued&per_page=30" |
    jq -r '.workflow_runs[]?.id' 2>/dev/null) || { echo 0; return; }
  for run_id in $run_ids; do
    jobs_json=$(api GET "actions/runs/$run_id/jobs") || continue
    n=$(echo "$jobs_json" |
      jq '[.jobs[]? | select(.status == "queued") | select((.labels | index("'"$LABEL"'")) != null)] | length' 2>/dev/null) || continue
    count=$((count + n))
  done
  echo "$count"
}

cleanup_vm() {
  local dir=$1 vmid
  vmid=$(basename "$dir")
  local runner_id disk tmpdir pid
  runner_id=$(cat "$dir/runner_id" 2>/dev/null || true)
  disk=$(cat "$dir/disk" 2>/dev/null || true)
  tmpdir=$(cat "$dir/tmpdir" 2>/dev/null || true)
  pid=$(cat "$dir/pid" 2>/dev/null || true)
  if [ -n "$runner_id" ]; then
    api DELETE "actions/runners/$runner_id" >/dev/null 2>&1 || true
  fi
  [ -n "$disk" ] && rm -f -- "$disk"
  [ -n "$tmpdir" ] && rm -rf -- "$tmpdir"
  rm -rf -- "$dir"
  echo "pool: reaped VM $vmid (pid $pid)"
}

# Reap dead or timed-out VMs.
reap() {
  local dir vmid pid started age
  for dir in "$RUN/active"/*; do
    [ -d "$dir" ] || continue
    vmid=$(basename "$dir")
    pid=$(cat "$dir/pid" 2>/dev/null || true)
    started=$(cat "$dir/started" 2>/dev/null || echo 0)
    age=$(( $(date +%s) - started ))

    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      if [ "$age" -ge "$VM_TIMEOUT_SECS" ]; then
        echo "pool: VM $vmid exceeded ${VM_TIMEOUT_SECS}s; killing pid $pid"
        kill "$pid" 2>/dev/null || true
        sleep 2
        kill -9 "$pid" 2>/dev/null || true
      else
        continue
      fi
    fi
    cleanup_vm "$dir"
  done
}

# Boot one VM with a fresh JIT token.
boot_vm() {
  local vmid ts name dir disk reg token runner_id tmpdir

  ts=$(date +%s)
  vmid="vm-$ts-$$-$RANDOM"
  dir="$RUN/active/$vmid"
  disk="$RUN/$vmid.qcow2"
  name="jit-$vmid"

  mkdir -p "$dir"

  reg=$(api POST "actions/runners/generate-jitconfig" \
    "{\"name\":\"$name\",\"runner_group_id\":1,\"labels\":[\"$LABEL\"]}") || {
    echo "pool: jitconfig request failed" >&2
    rm -rf "$dir"
    return 0
  }
  token=$(echo "$reg" | jq -r '.encoded_jit_config // empty')
  runner_id=$(echo "$reg" | jq -r '.runner.id // empty')
  if [ -z "$token" ] || [ -z "$runner_id" ]; then
    echo "pool: jitconfig response unusable: $(echo "$reg" | head -c 200)" >&2
    rm -rf "$dir"
    return 0
  fi

  printf '%s' "$runner_id" >"$dir/runner_id"
  printf '%s' "$disk" >"$dir/disk"
  printf '%s' "$ts" >"$dir/started"

  rm -f -- "$disk"

  tmpdir=$(mktemp -d "$RUN/$vmid.XXXXXX")
  mkdir -p "$tmpdir/xchg"
  printf '%s' "$token" >"$tmpdir/xchg/jitconfig"
  cp /nix/var/nix/db/db.sqlite "$tmpdir/xchg/host-nix-db.sqlite"
  printf '%s' "$tmpdir" >"$dir/tmpdir"

  USE_TMPDIR=1 TMPDIR="$tmpdir" NIX_DISK_IMAGE="$disk" "$VM_RUN" >"$RUN/console-$vmid.log" 2>&1 &
  printf '%s' "$!" >"$dir/pid"

  echo "pool: booted $vmid (runner $runner_id, pid $!)"
}

# Delete offline jit-* runners left over from crashed pools/VMs.
prune_stale_runners() {
  local id name runner_status
  while IFS=$'\t' read -r id name runner_status; do
    [ -n "$id" ] || continue
    if [ "$runner_status" = "offline" ] && [[ "$name" == jit-* ]]; then
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

  active=$(active_count)
  if [ "$active" -lt "$MAX_VMS" ]; then
    queued=$(queued_job_count)
    # Boot VMs for queued jobs, up to available slots.
    need=$((queued > (MAX_VMS - active) ? (MAX_VMS - active) : queued))
    if [ "$need" -gt 0 ]; then
      echo "pool: $queued queued jobs, $active active VMs, booting $need"
      for _ in $(seq 1 "$need"); do
        boot_vm
      done
      continue
    fi
  fi

  sleep "$POLL_SECS"
done
