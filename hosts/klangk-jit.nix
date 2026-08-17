# NixOS VM "klangk-jit" — disposable per-job GitHub Actions runner.
#
# The klangk-jit-pool service on keithmoon boots one fresh copy of this VM
# for every queued e2e job (label "nix"): it passes a just-in-time runner
# token via qemu fw_cfg (opt/klangk/jitconfig, a host-side file the pool
# rewrites under a start lock), boots with a brand-new sparse qcow2 rootfs
# (the nix store arrives read-only over 9p from the host, with a writable
# overlay on the fresh rootfs), the runner below executes exactly one job
# (ephemeral JIT registration), and the VM powers off. No state survives a
# job — stale sessions, leaked podman state, and ghost nix DB entries are
# structurally impossible.
#
# There is no services.github-runners instance here: registration happens
# per job through the JIT config handed in by the pool.
{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:

let
  # Single runner user. Rootless podman is per-user; every job gets a
  # fresh VM, so one user suffices.
  runnerUser = "ci";
  runnerUid = 1101;
  runnerUidStr = toString runnerUid;

  # Read the JIT token from /tmp/xchg/jitconfig — the pool writes it into a
  # per-job TMPDIR before booting the VM; qemu-vm.nix shares $TMPDIR/xchg as
  # a 9p mount at /tmp/xchg inside the guest. This is more reliable than
  # fw_cfg (which silently failed to expose the entry under by_name). Empty
  # (or absent) means a tokenless boot (pool smoke test): power off immediately.
  jitRunnerScript = pkgs.writeShellScript "klangk-jit-runner" ''
    set -euo pipefail
    echo "klangk-jit: runner script starting (pid $$)"
    token="$(cat /tmp/xchg/jitconfig 2>/dev/null || true)"
    if [ -z "''${token// /}" ]; then
      echo "klangk-jit: no jitconfig token present; nothing to do"
      exit 0
    fi
    echo "klangk-jit: token present (length ''${#token}); configuring runner"
    mkdir -p /home/${runnerUser}/runner
    cd /home/${runnerUser}/runner
    exec ${pkgs.github-runner}/bin/run.sh --jitconfig "$token"
  '';
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  system.stateVersion = "26.05";

  networking.hostId = "6b61a6ad";
  networking.hostName = "klangk-jit";

  users.users.root.password = ""; # serial-console debugging only (per-job VM, no network ingress)
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  # Sizing per concurrent e2e job (xdist workers + container stacks). The
  # pool caps concurrency (MAX_VMS) against keithmoon's 72 cores / 128G.
  virtualisation.diskSize = 51200;
  virtualisation.memorySize = 49152;
  virtualisation.cores = 24;
  virtualisation.graphics = false;
  # Persist the store overlay on the (per-job, disposable) rootfs instead
  # of tmpfs; the nix DB and store upper layer then live and die together.
  virtualisation.writableStoreUseTmpfs = false;
  # No forwarded ports: concurrent per-job VMs would collide, and the job
  # log reaches GitHub through the runner's own connection. qemu's user
  # networking provides outbound access.
  virtualisation.forwardPorts = [ ];

  # Token passing: the pool writes the JIT token into $TMPDIR/xchg/jitconfig
  # before boot; qemu-vm.nix shares $TMPDIR/xchg as a 9p mount at /tmp/xchg
  # inside the guest. No fw_cfg needed.

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      runnerUser
    ];
  };

  users.users.${runnerUser} = {
    isNormalUser = true;
    group = runnerUser;
    createHome = true;
    uid = runnerUid;
    # Rootless podman's systemd cgroup manager needs the user session bus
    # (DBUS_SESSION_BUS_ADDRESS below); linger keeps user@<uid> alive.
    linger = true;
  };
  users.groups.${runnerUser} = { };

  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = false;
  };

  # systemd 260+ defaults to hidepid=invisible for user@UID services, which
  # makes the kernel reject proc mounts inside nested user namespaces
  # ("VFS: Mount too revealing" → crun "mount proc: Operation not
  # permitted"). hidepid=0 is safe on a single-tenant throwaway CI VM.
  boot.specialFileSystems."/proc".options = [ "hidepid=0" ];

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    devenv
  ];

  # One JIT registration per boot: run.sh --jitconfig executes exactly one
  # job, then exits (GitHub deregisters the runner). Power off afterwards
  # either way — success or failure — so the pool reaps the VM.
  systemd.services.klangk-jit-runner = {
    description = "klangk JIT ephemeral GitHub Actions runner (one job per boot)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    # Warm the ci user's rootless podman session once before the runner
    # listens, so the job's first userns setup (pause process, SUID
    # newuidmap) never races logind.
    serviceConfig.ExecStartPre = "+${pkgs.writeShellScript "warm-podman-jit" ''
      echo "klangk-jit: warming podman session"
      runuser -u ${runnerUser} -- \
        env HOME=/home/${runnerUser} \
        XDG_RUNTIME_DIR=/run/user/${runnerUidStr} \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${runnerUidStr}/bus \
        /run/current-system/sw/bin/podman unshare true >/dev/null 2>&1 || true
      echo "klangk-jit: podman warm done"
    ''}";

    serviceConfig = {
      User = runnerUser;
      Group = runnerUser;
      Type = "simple";
      # Must exist before the unit starts: systemd chdir()s here before
      # running ANY command (incl. ExecStartPre), so it cannot be the
      # runner dir (that is created by the ExecStart script itself).
      WorkingDirectory = "/home/${runnerUser}";
      # Service stdout/stderr → serial console: systemd opens ttyS0 as root
      # before dropping privileges, so the ci user's output reaches the
      # pool's qemu console log.
      StandardOutput = "tty";
      StandardError = "tty";
      TTYPath = "/dev/ttyS0";
      TTYReset = false;
      TTYVHangup = false;
      # /run/wrappers/bin first: the SUID newuidmap/newgidmap wrappers must
      # shadow any non-SUID copies. This unit carries no systemd sandbox
      # restrictions — podman-in-jobs needs namespaces, delegated cgroups,
      # and full capabilities for its SUID helpers.
      Environment = [
        "PATH=/run/wrappers/bin:/run/current-system/sw/bin"
        "HOME=/home/${runnerUser}"
        "XDG_RUNTIME_DIR=/run/user/${runnerUidStr}"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${runnerUidStr}/bus"
      ];
      ExecStart = "${jitRunnerScript}";
      ExecStopPost = [
        "+/run/current-system/sw/bin/systemctl"
        "poweroff"
      ];
      Restart = "no";
      # One job (plus image builds) fits comfortably; guard runaway logs.
      LogRateLimitIntervalSec = "0";
    };
  };
}
