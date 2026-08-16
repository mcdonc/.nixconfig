# NixOS VM "klangk-ci" — GitHub Actions runners for klangk CI.
#
# Runs on keithmoon under libvirtd (qemu/KVM). Four independent
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

let
  # Runner indices — each gets a dedicated user (ci-N), uid (1100+N),
  # group, and github-runner service. Rootless podman is per-user, so
  # distinct users mean distinct podman stores and no contention.
  runnerIndices = [ 1 2 3 4 ];

  mkUser = idx: {
    name = "ci-${toString idx}";
    value = {
      isNormalUser = true;
      group = "ci-${toString idx}";
      createHome = true;
      uid = 1100 + idx;
      linger = true;
    };
  };

  mkGroup = idx: {
    name = "ci-${toString idx}";
    value = { };
  };

  mkRunner = idx:
    let
      user = "ci-${toString idx}";
      uid = toString (1100 + idx);
    in
    {
      name = "klangk-${toString idx}";
      value = {
        enable = true;
        url = "https://github.com/mcdonc/klangk";
        tokenFile = config.age.secrets."github-runner-klangk".path;
        extraLabels = [
          "nix"
          "klangk-ci"
        ];
        ephemeral = false;
        replace = true;
        user = user;
        group = user;
        extraPackages = with pkgs; [
          git
          git-lfs
          devenv
          (pkgs.runCommand "setuid-wrappers-shims" { } ''
            mkdir -p $out/bin
            ln -s /run/wrappers/bin/newuidmap $out/bin/newuidmap
            ln -s /run/wrappers/bin/newgidmap $out/bin/newgidmap
            ln -s /run/wrappers/bin/fusermount3 $out/bin/fusermount3
          '')
        ];
        extraEnvironment = {
          XDG_RUNTIME_DIR = "/run/user/${uid}";
          DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${uid}/bus";
        };
        serviceOverrides = {
          ExecStartPre = [
            "+${pkgs.writeShellScript "warm-podman-session-${user}" ''
              runuser -u "${user}" -- \
                env HOME=/home/${user} \
                XDG_RUNTIME_DIR=/run/user/${uid} \
                DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${uid}/bus \
                podman unshare true >/dev/null 2>&1 || true
            ''}"
          ];
          CapabilityBoundingSet = lib.mkForce [ "~" ];
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
    };

in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  system.stateVersion = "26.05";

  networking.hostId = "6b61a6ac";
  networking.hostName = "klangk-ci";

  age.secrets."github-runner-klangk" = {
    file = ../secrets/github-runner-klangk.age;
  };

  # Console-only CI box.
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  # Sizing: four concurrent e2e jobs, each with xdist workers + container
  # stacks. The host (keithmoon) has 72 cores / 128G RAM.
  virtualisation.diskSize = 102400;
  virtualisation.memorySize = 65536;
  virtualisation.cores = 32;
  virtualisation.graphics = false;
  virtualisation.writableStoreUseTmpfs = false;
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
    trusted-users = [ "root" ] ++ map (i: "ci-${toString i}") runnerIndices;
  };

  # ---------------------------------------------------------------- runners
  # Per-runner service users. Rootless podman is per-user; distinct users
  # mean distinct podman stores, subuid ranges, and aardvark instances.
  users.users = builtins.listToAttrs (map mkUser runnerIndices) // {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
    ];
  };
  users.groups = builtins.listToAttrs (map mkGroup runnerIndices);

  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = false;
  };

  virtualisation.containers.storage.settings = { };

  # Pin each ci user's rootless podman graphroot to their home on ext4.
  # The GitHub runner sets HOME=/run/github-runner/klangk-N (on tmpfs),
  # so without this podman defaults graphroot to tmpfs. Overlay-on-tmpfs
  # in a user namespace triggers "VFS: Mount too revealing" on kernel
  # 6.12+ because tmpfs lacks idmapped-mount support — every podman
  # build RUN step fails with "mount proc to proc: Operation not
  # permitted". Pinning to ext4 avoids this entirely.
  system.activationScripts.podman-ci-storage = lib.stringAfter [ "users" ] (
    builtins.concatStringsSep "\n" (map (idx:
      let
        user = "ci-${toString idx}";
        uid = toString (1100 + idx);
        confDir = "/home/${user}/.config/containers";
        storageConf = pkgs.writeText "ci-${toString idx}-storage.conf" ''
          [storage]
          driver = "overlay"
          graphroot = "/home/${user}/.local/share/containers/storage"
          runroot = "/run/user/${uid}/containers"
        '';
      in ''
        install -d -o ${uid} -g ${uid} ${confDir}
        install -o ${uid} -g ${uid} -m 644 ${storageConf} ${confDir}/storage.conf
      ''
    ) runnerIndices)
  );

  environment.etc."ssh/ssh_host_ed25519_key" = {
    source = ../secrets/klangk-ci-host-key.priv;
    mode = "0600";
  };
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

  services.github-runners = builtins.listToAttrs (map mkRunner runnerIndices);

  environment.systemPackages = with pkgs; [
    vim
    curl
    git
    git-lfs
    devenv
  ];
}
