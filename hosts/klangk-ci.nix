# NixOS VM "klangk-ci" — GitHub Actions runners for klangk CI.
#
# Runs on keithmoon under libvirtd (qemu/KVM). Two independent
# services.github-runners instances advertise the "nix" label, so GitHub
# load-balances e2e jobs across them. Each runner has its own user so
# their rootless podman instances never share state — the aardvark-dns /
# image-store contention class that plagued the host-runner layout is
# structurally impossible.
#
# Deploy with:
#   nixos-rebuild build-vm --flake /etc/nixos#klangk-ci
#   # or import the produced QEMU script into libvirtd; disk on /steam2.
{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  system.stateVersion = "26.05";

  networking.hostId = "6b61a6ac"; # rand hex, required by nothing here but kept for zfs-readiness
  networking.hostName = "klangk-ci";

  # Registration token via agenix: same fine-grained PAT as the host runner
  # (repo mcdonc/klangk, Administration RW). Identity is the VM's ssh host
  # key (the agenix module default), pinned via klangk-ci-host-key above.
  age.secrets."github-runner-klangk" = {
    file = ../secrets/github-runner-klangk.age;
  };

  # Console-only CI box.
  services.openssh.permitRootLogin = "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [
    # chrism@ednesia — for key extraction + debugging via forwarded port 2222
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
  ];

  # qemu-vm boots /nix/store as an overlay: read-only 9p share of the host
  # store below a tmpfs upper layer (/nix/.rw-store, x-initrd.mount). Paths
  # built inside the VM (devenv shells, image deps) live in the tmpfs; the
  # nix DB lives on the persistent qcow2. Every reboot therefore leaves DB
  # entries whose files vanished — devenv then fails with
  # "opening file '...-devenv-shell.drv': No such file or directory".
  # Prune the ghosts once per boot before jobs run.
  systemd.services.nix-store-reconcile = {
    description = "Prune nix DB entries orphaned by the tmpfs store overlay";
    after = [ "nix-daemon.service" ];
    wants = [ "nix-daemon.service" ];
    before = [ "github-runner-klangk-1.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nix-store --verify --repair";
    };
  };

  # Sizing: one e2e job at a time (each is -n 2 xdist + container stacks).
  # Disk: default 1G is far too small for the runner's podman store + nix
  # roots; 100G virtual (thin qcow2, actual use much smaller).
  virtualisation.diskSize = 102400;
  virtualisation.memorySize = 32768;
  virtualisation.cores = 8;
  virtualisation.graphics = false;
  # Host ssh access: forward host 2222 -> guest 22 (key extraction, debugging).
  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 2222;
      guest.port = 22;
    }
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # devenv builds pass client settings (e.g. 'system'); untrusted users
    # get them silently ignored and the shell realization fails.
    trusted-users = [
      "root"
      "ci-1"
    ];
  };

  # ---------------------------------------------------------------- runners
  # Per-runner service users. Rootless podman is per-user; distinct users
  # mean distinct podman stores, subuid ranges, and aardvark instances.
  users.users.ci-1 = {
    isNormalUser = true; # proper home + login shell for rootless podman
    group = "ci-1";
    createHome = true;
    # Stable uid (referenced by the runners' XDG_RUNTIME_DIR).
    uid = 1101;
    # Persistent user manager: rootless podman's systemd cgroup manager needs
    # the user session bus, and service units have no login session. Lingering
    # keeps /run/user/<uid> + user@<uid>.service alive so crun sd-bus resolves.
    linger = true;
  };
  users.groups.ci-1 = { };

  # SUID wrappers for rootless podman (uid maps). Enabled by default via
  # virtualisation.podman below + wrappers, but explicit for clarity.
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = false;
  };

  # Registration token via agenix: same fine-grained PAT as the host runner
  # (repo mcdonc/klangk, Administration RW). Identity is the VM's ssh host
  # key (the agenix module default), same as every other machine here:
  #   1. boot the VM once, grab /etc/ssh/ssh_host_ed25519_key.pub
  #   2. convert with ssh-to-age, add the age1... key to secrets.nix
  #   3. agenix -e secrets/github-runner-klangk-ci.age (paste PAT) && agenix -r
  # NOTE: requires a persistent VM disk (libvirtd qcow2) — the volatile
  # build-vm disk regenerates the host key every boot.
  # Fixed ssh host key, baked into the closure (single-tenant CI VM: the
  # key guards only a localhost-forwarded ssh port). Pinning the identity in
  # the store means a fresh boot ALWAYS has a readable agenix identity —
  # agenix activation decrypts the runner PAT via age.identityPaths below,
  # so no chicken-and-egg with the key being an agenix output itself.
  environment.etc."ssh/ssh_host_ed25519_key" = {
    source = ../secrets/klangk-ci-host-key.priv;
    mode = "0600";
  };
  # Bootstrap age identity: present in the store from first activation, so
  # agenix can decrypt the runner PAT on a fresh boot (the ssh-host-key path
  # only materializes after the etc snippet, which runs later).
  age.identityPaths = [ "${../secrets/klangk-ci-bootstrap.age.key}" ];

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # Single runner: both e2e workflows share one suite action; one job at
  # a time keeps podman/cgroup state simple (queueing serializes runs).
  services.github-runners.klangk-1 = {
    enable = true;
    url = "https://github.com/mcdonc/klangk";
    tokenFile = config.age.secrets."github-runner-klangk".path;
    extraLabels = [
      "nix"
      "klangk-ci"
    ];
    # Non-ephemeral: the ephemeral restart/re-register cycle between jobs
    # raced the lingering user manager (logind user@<uid>) — the first
    # job's podman userns setup hit newuidmap EPERM intermittently.
    # Keeping the service (and its session) alive removes that window;
    # job hygiene is preserved by checkout wiping the workspace anyway.
    ephemeral = false;
    replace = true;
    user = "ci-1";
    group = "ci-1";
    extraPackages = with pkgs; [
      git
      git-lfs
      devenv
      # SUID helpers: job shells get the runner's constructed PATH (no
      # /run/wrappers/bin), so expose the wrappers via symlinks. The
      # kernel applies SUID on the target, not the symlink.
      (pkgs.runCommand "setuid-wrappers-shims" { } ''
        mkdir -p $out/bin
        ln -s /run/wrappers/bin/newuidmap $out/bin/newuidmap
        ln -s /run/wrappers/bin/newgidmap $out/bin/newgidmap
        ln -s /run/wrappers/bin/fusermount3 $out/bin/fusermount3
      '')
    ];
    # Rootless podman needs the ci user's session bus (systemd cgroup
    # manager); linger keeps it alive, this points jobs at it.
    extraEnvironment = {
      XDG_RUNTIME_DIR = "/run/user/" + toString config.users.users.ci-1.uid;
    };
    serviceOverrides = {
      # Pre-warm the ci user's session before the runner listens: establish
      # the lingering user manager + rootless podman state (pause process,
      # /run/user/<uid> mounts) once at service start, so a job's first
      # userns setup never races logind (the newuidmap EPERM class).
      # `podman unshare true` (not `podman info`): info initializes the DB
      # but never creates the pause process / runs SUID newuidmap — unshare
      # exercises the exact failing path. Without it, the first job after
      # boot runs two concurrent builds (devenv tasks run a b) against
      # cold per-user state and their userns inits race (uid_map EPERM).
      ExecStartPre = [
        "+${pkgs.writeShellScript "warm-podman-session" ''
          runuser -u "ci-1" -- \
            env HOME=/home/ci-1 \
            XDG_RUNTIME_DIR=/run/user/${toString config.users.users.ci-1.uid} \
            podman unshare true >/dev/null 2>&1 || true
        ''}"
      ];
      # Same relaxation set validated on the host runner — podman-in-jobs
      # needs namespaces, writable caches, visible uid_maps.
      # CapabilityBoundingSet: the module default is empty (drop all), which
      # masks the capabilities SUID newuidmap gains on exec — euid 0 with no
      # CAP_SETUID, so every rootless userns setup under the unit fails
      # with "newuidmap: open of uid_map failed: Permission denied".
      # null renders as the bare drop-all line in this nixpkgs, so use
      # systemd's inverted-empty-list idiom (CapabilityBoundingSet=~)
      # instead: retains all capabilities.
      CapabilityBoundingSet = lib.mkForce [ "~" ];
      # ProtectControlGroups: the module default mounts /sys/fs/cgroup
      # read-only in the unit's mount namespace, so crun inside a job
      # cannot mkdir its container cgroups under the user's delegated
      # subtree — "create directory .../crun-buildah-....scope/container:
      # Read-only file system" on the first RUN step of every build.
      ProtectControlGroups = false;
      ProtectSystem = "full";
      ProtectHome = false;
      PrivateUsers = false;
      RestrictNamespaces = false;
      SystemCallFilter = lib.mkForce [ ];
      NoNewPrivileges = false;
      RestrictSUIDSGID = false;
      PrivateDevices = false;
      PrivateMounts = false;
      ProtectProc = "default";
      ProtectHostname = false;
      PrivateTmp = false;
      UMask = lib.mkForce "0022";
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    curl
    # Direct-on-VM test runs (bypassing the GitHub runner chain) need the
    # same toolchain the runner units carry via extraPackages.
    git
    git-lfs
    devenv
  ];
}
