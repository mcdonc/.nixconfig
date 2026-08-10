{
  config,
  pkgs,
  lib,
  nixos-hardware,
  inputs,
  options,
  ...
}:

{
  imports = [
    ../users/chrism
    ./roles/workstation.nix
    ./roles/intel.nix
    "${nixos-hardware}/common/pc/ssd"
    ./roles/encryptedzfs.nix
    ./roles/dns/resolved-tls.nix
    ./roles/davinci-resolve/studio.nix
    ./roles/steam.nix
    ./roles/speedtest
    ./roles/idracfanctl.nix
    #./roles/tailscale
    #./roles/rc505
    ./roles/ollama.nix
    ./roles/mailrelayer.nix
    ./roles/zedalerts.nix
    ./roles/journalwatch.nix
    ./roles/nvidiapassthru.nix
    ./roles/dictation.nix
    #./roles/vllm.nix
    #./roles/sudorelax.nix
  ];

  system.stateVersion = "24.05";

  # Podman: enable the NixOS module (provides policy.json, subuid/subgid, etc.)
  # Storage on ext4 — ZFS lacks idmapped mount support, causing
  # storage-chown-by-maps to hang with --userns=keep-id.
  virtualisation.podman.enable = true;
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "overlay";
      graphroot = "/steam2/podman/storage";
      runroot = "/steam2/podman/run";
    };
  };

  # environment.extraInit =
  #   let
  #     cachix-file = config.age.secrets."mcdonc-unhappy-cachix-authtoken".path;
  #   in
  #   ''
  #     export CACHIX_AUTH_TOKEN=$(cat "${cachix-file}"|xargs)
  #   '';

  services.tailscale.enable = true;

  services.ollama.host = "0.0.0.0";
  services.open-webui.host = "0.0.0.0";

  services.idracfanctl.enable = true;
  services.idracfanctl.fan-percent-min = 15;
  services.idracfanctl.fan-percent-max = 65;
  services.idracfanctl.temp-cpu-min = 43;
  services.idracfanctl.temp-cpu-max = 96;

  #services.nix-serve.enable = true;
  #services.nix-serve.secretKeyFile = "/nix-serve-private";

  networking.hostId = "90ca4330";
  networking.hostName = "keithmoon";

  # networking.hosts = {
  #   "127.0.0.1" = [ "rag-logfire.enfoldsystems.net" ];
  # };

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "ehci_pci"
    "megaraid_sas"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ];
  # see prepserver.sh
  boot.initrd.secrets."/key.txt" = /key.txt;
  boot.extraModulePackages = [ ];

  # dont ask for "d/o" credentials
  boot.zfs.requestEncryptionCredentials = lib.mkForce [ "NIXROOT" ];

  fileSystems."/nix" = {
    device = "NIXROOT/nix";
    fsType = "zfs";
  };

  fileSystems."/steam1" = {
    device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG612853H";
    fsType = "ext4";
  };

  fileSystems."/steam2" = {
    device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG619917K";
    fsType = "ext4";
  };

  # # use the VFlash SD card to boot
  # fileSystems."/boot" = lib.mkForce
  #   {
  #     device = "/dev/disk/by-id/usb-iDRAC_VFBOOT_20120731-2-0:0-part1";
  #     fsType = "vfat";
  #   };

  # use the double SD card to boot
  fileSystems."/boot" = lib.mkForce {
    device = "/dev/disk/by-id/usb-DELL_IDSDM_012345678901-0:0";
    fsType = "vfat";
  };

  # note that this is chowned in activationScripts
  boot.zfs.extraPools = [ "d" ];

  # don't run updatedb on these disks
  services.locate.prunePaths = [
    "/d"
    "/steam1"
    "/steam2"
  ];

  # 20 GiB max ARC cache
  boot.kernelParams = [
    "zfs.zfs_arc_max=21474836480"
    # required by wayland, see
    # https://blog.davidedmundson.co.uk/blog/running-kwin-wayland-on-nvidia/
    "nvidia-drm.modeset=1"
  ];

  # Enable OpenGL
  hardware.graphics.enable = true;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];
  # allow changing nvidia fan speed
  services.xserver.deviceSection = ''
    Option    "Coolbits" "4"
  '';

  hardware.nvidia = {
    open = false;
    # Modesetting is required.
    modesetting.enable = true;
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;
    nvidiaSettings = true;

    # package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # services.samba = {
  #   enable = true;
  #   openFirewall = true;
  #   settings = {
  #     global = {
  #       workgroup = "WORKGROUP";
  #       "server string" = "keithmoon";
  #       "netbios name" = "keithmoon";
  #       security = "user";
  #       browseable = "yes";
  #       "smb encrypt" = "required";
  #       # note: localhost is the ipv6 localhost ::1
  #       "hosts allow" = "192.168.1. 127.0.0.1 localhost";
  #       "hosts deny" = "0.0.0.0/0";
  #       "guest account" = "nobody";
  #       "map to guest" = "bad user";
  #       "log level" = "nmbd:0";
  #     };
  #     root = {
  #       path = "/";
  #       browseable = "yes";
  #       writeable = "yes";
  #       "read only" = "no";
  #       "guest ok" = "no";
  #       "create mask" = "0644";
  #       "directory mask" = "0755";
  #       "force user" = "chrism";
  #       "force group" = "users";
  #     };
  #     v = {
  #       path = "/home/chrism/v";
  #       browseable = "yes";
  #       writeable = "yes";
  #       "read only" = "no";
  #       "guest ok" = "no";
  #       "create mask" = "0644";
  #       "directory mask" = "0755";
  #       "force user" = "chrism";
  #       "force group" = "users";
  #     };
  #     homes = {
  #       browseable = "no";
  #       # note: each home will be browseable; the "homes" share will not.
  #       "read only" = "no";
  #       "guest ok" = "no";
  #       "create mask" = "0644";
  #       "directory mask" = "0755";
  #     };
  #   };
  # };

  # # filter out stupid samba nmdb messages from log (doesnt seem to work)
  # systemd.services.samba-nmbd.serviceConfig = {
  #   StandardOutput = "null";
  #   StandardError = "null";
  # };

  # none of this seems to be necessary 7/13/2025.
  #
  # services.avahi = {
  #   # systemd-resolved now handles mDNS publishing except services.  That's why
  #   # publish.enable is false but publish.userServices is true.  Keep an eye
  #   # on systemd.dnssd (service publishing) to totally replace avahi.
  #   enable = true;
  #   #publish.enable = true;
  #   publish.userServices = true;
  #   # ^^ Needed to allow samba to automatically register mDNS records
  #   # without the need for an `extraServiceFile`
  #   nssmdns4 = true;
  #   openFirewall = true;
  # };

  # avahi config is required for samba to work (maybe?  untested)

  # services.samba-wsdd = {
  #   enable = true;
  #   openFirewall = true;
  # };

  system.activationScripts.chrism_home_x = pkgs.lib.stringAfter [ "users" ] ''
    chmod o+x /home/chrism
    mkdir -p /home/chrism/v
    chown chrism:users /home/chrism/v
    # mkdir -p /home/chrism/v/postgresql
    # chown postgres:postgres /home/chrism/v/postgresql
    ln -sf /home/chrism/v /v
    chown chrism:users /steam1
    chown chrism:users /steam2
    chown chrism:users /d
    #chown chrism:users /et
  '';

  # services.postgresql = {
  #   package = pkgs.postgresql_15;
  #   enable = true;
  #   enableTCPIP = true;
  #   settings.port = 5432;
  #   dataDir="/v/postgresql/${config.services.postgresql.package.psqlSchema}";
  #   authentication = pkgs.lib.mkForce ''
  #     # TYPE  DATABASE        USER            ADDRESS                 METHOD
  #     local   all             all                                     trust
  #     host    all             all             127.0.0.1/32            trust
  #     host    all             all             192.168.1.0/24          trust
  #   '';
  # initialScript = pkgs.writeText "postgres-init-script" ''
  #   CREATE ROLE resolve WITH LOGIN PASSWORD 'resolve' CREATEDB;
  # '';
  # };

  # resolve "network->connect"
  # name: videos
  # ip:
  # username: resolve
  # pass:

  services.syncoid = {
    enable = true;
    interval = "*:35"; # run this less often than sanoid (every hour at 35 mins)
    #commonArgs = [ "--debug" ];
    commands = {
      "home-keithmoon" = {
        source = "NIXROOT/home";
        target = "d/home-keithmoon";
        sendOptions = "w c";
      };
      "home-optinix" = {
        sshKey = "/var/lib/syncoid/backup.key";
        source = "backup@optinix.local:NIXROOT/home";
        target = "d/home-optinix";
        sendOptions = "w c";
        extraArgs = [ "--sshoption=StrictHostKeyChecking=off" ];
      };
      "home-thinknix52" = {
        sshKey = "/var/lib/syncoid/backup.key";
        source = "backup@thinknix52.local:NIXROOT/home";
        target = "d/home-thinknix52";
        sendOptions = "w c";
        extraArgs = [ "--sshoption=StrictHostKeyChecking=off" ];
      };
      "home-thinknix50" = {
        sshKey = "/var/lib/syncoid/backup.key";
        source = "backup@thinknix50.local:NIXROOT/home";
        target = "d/home-thinknix50";
        sendOptions = "w c";
        extraArgs = [ "--sshoption=StrictHostKeyChecking=off" ];
      };
      "home-thinknix512" = {
        sshKey = "/var/lib/syncoid/backup.key";
        source = "backup@thinknix512.local:NIXROOT/home";
        target = "d/home-thinknix512";
        sendOptions = "w c";
        extraArgs = [ "--sshoption=StrictHostKeyChecking=off" ];
      };
      # sudo zfs allow backup compression,hold,send,snapshot,mount,destroy NIXROOT/home
    };
    localSourceAllow = options.services.syncoid.localSourceAllow.default ++ [
      "mount"
    ];
    localTargetAllow = options.services.syncoid.localTargetAllow.default ++ [
      "destroy"
    ];
  };

  services.sanoid = {
    enable = true;
    #extraArgs = [ "--debug" ];
    interval = "*:2,32"; # run this more often than syncoid (every 30 mins)
    datasets = {
      "NIXROOT/home" = {
        autoprune = true;
        autosnap = true;
        hourly = 1;
        daily = 1;
        weekly = 1;
        monthly = 1;
        yearly = 0;
      };
      "d/o" = {
        autoprune = true;
        autosnap = true;
        hourly = 0;
        daily = 0;
        weekly = 2;
        monthly = 0;
        yearly = 0;
      };
      # https://github.com/jimsalterjrs/sanoid/wiki/Syncoid#snapshot-management-with-sanoid
      "d/home-keithmoon" = {
        autoprune = true;
        autosnap = false;
        hourly = 4;
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 0;
      };
      "d/home-optinix" = {
        autoprune = true;
        autosnap = false;
        hourly = 4;
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 0;
      };
      "d/home-thinknix52" = {
        autoprune = true;
        autosnap = false;
        hourly = 4;
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 0;
      };
      "d/home-thinknix50" = {
        autoprune = true;
        autosnap = false;
        hourly = 4;
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 0;
      };
      "d/home-thinknix512" = {
        autoprune = true;
        autosnap = false;
        hourly = 4;
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 0;
      };
    };
  };

  # Loopback btrfs volume on ext4 (avoids ZFS double-CoW).
  # Image lives on /steam2; mounted at /steam2/btrfs.
  systemd.services.btrfs-loopback = {
    description = "Mount btrfs loopback image";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ btrfs-progs util-linux coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "mount-btrfs-loopback" ''
        IMG=/steam2/btrfs.img
        MNT=/steam2/btrfs
        if [ ! -f "$IMG" ]; then
          truncate -s 50G "$IMG"
          mkfs.btrfs "$IMG"
        fi
        mkdir -p "$MNT"
        if ! mountpoint -q "$MNT"; then
          mount -o loop "$IMG" "$MNT"
        fi
        chown chrism:users "$MNT"
      '';
      ExecStop = "${pkgs.util-linux}/bin/umount /steam2/btrfs";
    };
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
    cifs-utils
    # used by zfs send/receive
    pv
    mbuffer
    lzop
    zstd
    #inputs.winboat.packages.x86_64-linux.winboat
    #freerdp # for winboat
    inputs.herdr.packages."${pkgs.stdenv.hostPlatform.system}".default
    input-leap
    matchbox # for screenrecordings
  ];

  # services.pulseaudio.enable = lib.mkForce true;
  # services.pipewire.enable = lib.mkForce false;
  # services.pipewire.jack.enable = lib.mkForce false;
  # services.pipewire.alsa.enable = lib.mkForce false;
  # services.pipewire.pulse.enable = lib.mkForce false;

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "65536";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }
    {
      domain = "*";
      type = "hard";
      item = "core";
      value = "0";
    }
  ];

  systemd.services.klangk = {
    description = "Klangk (test deployment, #1546)";
    after = [ "network.target" ];
    # Auto-start disabled: won't start at boot or on-rebuild, but remains
    # manually startable via `systemctl start klangk`.
    wantedBy = lib.mkForce [ ];
    serviceConfig = {
      # Self-contained checkout at /tmp/temp-klangk (shallow clone of main).
      # `devenv shell -- klangkd` runs klangkd with the checkout's full
      # devenv toolchain on PATH (nginx, podman, etc.) — dotenv is disabled
      # (-O dotenv.enable:bool false), so no .env is loaded; config comes only
      # from /tmp/temp-klangk/state/klangkd.yaml (+ devenv.nix's infra env for
      # state_dir/data_dir). Serves browser :28997 + egress :28995.
      ExecStart = "${pkgs.devenv}/bin/devenv --quiet -O dotenv.enable:bool false shell -- klangkd --config /tmp/temp-klangk/state/klangkd.yaml";
      Environment = "DEVENV_TUI=false";
      User = "chrism";
      Group = "users";
      WorkingDirectory = "/tmp/temp-klangk";
      # nginx's config opens `access_log /dev/stdout; error_log stderr;` by
      # path (/proc/self/fd/1). Under systemd the inherited stdout fd is a
      # journald socket that can't be reopened by path, so nginx fails with
      # `open() "/dev/stdout" failed`. Route the unit's stdout/stderr to a
      # real file so /dev/stdout resolves to an openable regular file.
      StandardOutput = "append:/tmp/temp-klangk/state/klangkd.stdout.log";
      StandardError = "append:/tmp/temp-klangk/state/klangkd.stderr.log";
      Restart = "on-failure";
      RestartSec = 5;
    };
    path = [ "/run/wrappers" ];
  };

  # --- #1546: declarative NixOS container that acts as a non-localhost HTTPS
  # reverse proxy in front of the klangk service above. The container has its
  # own network namespace + a non-loopback veth IP (10.100.0.2), so klangk's
  # nginx sees $remote_addr=10.100.0.2 — faithfully simulating a proxy on a
  # separate host. It terminates TLS (self-signed cert) and reverse-proxies to
  # the host's klangk browser listener (0.0.0.0:28997) reached via the host
  # bridge IP (10.100.0.1). KLANGK_TRUSTED_PROXY_CIDRS in the klangkd config
  # includes 10.100.0.0/24 so X-Forwarded-* / X-Real-IP are honored.
  #
  # Caddy is used (not nginx) because the NixOS nginx module emits a duplicate
  # Host header on the upstream request (HTTP/2 :authority + proxy_set_header
  # Host interaction) that the klangk upstream correctly rejects with 400 per
  # RFC 7230 §5.4. Caddy's reverse_proxy sends a single, well-formed Host.
  # The point of #1546 is to validate klangk's proxy-trust behavior behind an
  # *arbitrary* well-behaved proxy, not to debug a specific proxy's quirks.
  containers.klangk-proxy = {
    # Manual start only (matches the klangk service's wantedBy = []).
    autoStart = false;
    privateNetwork = true;
    hostAddress = "10.100.0.1";
    localAddress = "10.100.0.2";
    # The container reaches the host's klangk browser listener directly at
    # 10.100.0.1:28997 (klangk binds 0.0.0.0, option a, #1546).
    bindMounts = {
      "/etc/klangk-proxy/certs" = {
        hostPath = "/tmp/temp-klangk/state/certs";
        isReadOnly = true;
      };
    };
    config =
      { config, pkgs, ... }:
      {
        services.caddy = {
          enable = true;
          # Self-signed internal cert (Caddy's tls internal) terminates HTTPS
          # on :443. reverse_proxy forwards to the host bridge IP. Caddy sets
          # X-Forwarded-For / X-Forwarded-Proto / a single Host by default.
          config = ''
            :443 {
              tls /etc/klangk-proxy/certs/klangk-test.crt /etc/klangk-proxy/certs/klangk-test.key
              reverse_proxy 10.100.0.1:28997 {
                header_up X-Forwarded-Proto https
                header_up X-Real-IP {remote_host}
              }
            }
          '';
        };
        networking.firewall.allowedTCPPorts = [ 443 ];
      };
  };

  systemd.services.soliplex = {
    description = "Soliplex";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.devenv}/bin/devenv processes up";
      Environment = "DEVENV_TUI=false";
      User = "chrism";
      Group = "users";
      WorkingDirectory = "/home/chrism/projects/soliplex/devenv";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  environment.etc."security/limits.conf".text = ''
    # set soft and hard nofile for all users
    * soft nofile 65536
    * hard nofile 1048576
    # disable core dumps
    * hard core 0
  '';

}
