args@{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    ../users/chrism
    ./roles/intel.nix
    "${nixos-hardware}/common/pc/ssd"
    ./roles/encryptedzfs.nix
    ./roles/dnsovertls/resolvedonly.nix
    ./roles/davinci-resolve/studio.nix
    ./roles/steam.nix
    ./roles/speedtest
    #./roles/tailscale
    ./roles/idracfanctl.nix
    ./roles/peerix.nix
    #./roles/idracfanctl2.nix
    #./roles/aws.nix
    #(
    #  import ./roles/macos-ventura.nix (
    #    args // {mem="20G"; cores=4; enable=true;}
    #  )
    #)
    ../common.nix
  ];

  system.stateVersion = "24.05";

  #services.idracfanctl.enable = true;
  #services.idracfanctl.fan-percent-min = 50;

  networking.hostId = "90ca4330";
  networking.hostName = "keithmoon";

  boot.initrd.availableKernelModules = [
    "ahci" "xhci_pci" "ehci_pci" "megaraid_sas" "usb_storage" "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  # see prepserver.sh
  boot.initrd.secrets."/key.txt" = /key.txt;
  boot.extraModulePackages = [ ];

  # dont ask for "d/o" credentials
  boot.zfs.requestEncryptionCredentials = lib.mkForce [ "NIXROOT" ];

  fileSystems."/nix" =
    { device = "NIXROOT/nix";
      fsType = "zfs";
    };

  #fileSystems."/et" =
  #  { device = "et";
  #    fsType = "zfs";
  #  };

  fileSystems."/steam1" =
    { device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG612853H";
      #label="STEAM1";
      fsType = "ext4";
    };

  fileSystems."/steam2" =
    { device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG619917K";
      #label="STEAM2";
      fsType = "ext4";
    };

  # # use the VFlash SD card to boot
  # fileSystems."/boot" = lib.mkForce
  #   {
  #     device = "/dev/disk/by-id/usb-iDRAC_VFBOOT_20120731-2-0:0-part1";
  #     fsType = "vfat";
  #   };

  # use the double SD card to boot
  fileSystems."/boot" = lib.mkForce
    {
      device = "/dev/disk/by-id/usb-DELL_IDSDM_012345678901-0:0";
      fsType = "vfat";
    };

  # note that this is chowned in activationScripts
  boot.zfs.extraPools = [ "d" ];

  # don't run updatedb on these disks
  services.locate.prunePaths = [ "/d" "/steam1" "/steam2" ];

  # 32 GB max ARC cache
  boot.kernelParams = [
    "zfs.zfs_arc_max=34359738368"
    # required by wayland, see
    # https://blog.davidedmundson.co.uk/blog/running-kwin-wayland-on-nvidia/
    "nvidia-drm.modeset=1"
  ];

  # Enable OpenGL
  hardware.graphics.enable = true;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];
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

  services.samba = {
    enable = true;
    # package = pkgs.samba4Full; # doesn't work on 25.05 due to ceph
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "keithmoon";
        "netbios name" = "keithmoon";
        security = "user";
        browseable = "yes";
        "smb encrypt" = "required";
        # note: localhost is the ipv6 localhost ::1
        "hosts allow" = "192.168.1. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      root = {
        path = "/";
        browseable = "yes";
        writeable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "chrism";
        "force group" = "users";
      };
      v = {
        path = "/home/chrism/v";
        browseable = "yes";
        writeable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "chrism";
        "force group" = "users";
      };
      homes = {
        browseable = "no";
        # note: each home will be browseable; the "homes" share will not.
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  services.avahi = {
    publish.enable = true;
    publish.userServices = true;
    # ^^ Needed to allow samba to automatically register mDNS records
    # (without the need for an `extraServiceFile`
    #nssmdns4 = true;
    # ^^ Not one hundred percent sure if this is needed- if it aint broke,
    # don't fix it
    enable = true;
    openFirewall = true;
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  system.activationScripts.chrism_home_x = pkgs.lib.stringAfter [ "users" ]
    ''
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
    commonArgs = [ "--debug" ];
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
        extraArgs = ["--sshoption=StrictHostKeyChecking=off"];
      };
      "home-thinknix52" = {
        sshKey = "/var/lib/syncoid/backup.key";
        source = "backup@thinknix52.local:NIXROOT/home";
        target = "d/home-thinknix52";
        sendOptions = "w c";
        extraArgs = ["--sshoption=StrictHostKeyChecking=off"];
      };
      "home-thinknix50" = {
        sshKey = "/var/lib/syncoid/backup.key";
        source = "backup@thinknix50.local:NIXROOT/home";
        target = "d/home-thinknix50";
        sendOptions = "w c";
        extraArgs = ["--sshoption=StrictHostKeyChecking=off"];
      };
      "home-thinknix512" = {
        sshKey = "/var/lib/syncoid/backup.key";
        source = "backup@thinknix512.local:NIXROOT/home";
        target = "d/home-thinknix512";
        sendOptions = "w c";
        extraArgs = ["--sshoption=StrictHostKeyChecking=off"];
      };
      # sudo zfs allow backup compression,hold,send,snapshot,mount,destroy NIXROOT/home
    };
    localSourceAllow = options.services.syncoid.localSourceAllow.default
      ++ [ "mount" ];
    localTargetAllow = options.services.syncoid.localTargetAllow.default
      ++ [ "destroy" ];
  };

  services.sanoid = {
    enable = true;
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
    extraArgs = [ "--debug" ];
  };

  environment.systemPackages = with pkgs; [
    # used by zfs send/receive
    pv
    mbuffer
    lzop
    zstd

    cifs-utils
  ];

  #sound.enable = lib.mkForce true; # use pulseaudio
  #hardware.pulseaudio.enable = lib.mkForce true;
  #services.pipewire.enable = lib.mkForce false;
  #services.pipewire.jack.enable = lib.mkForce false;
  #services.pipewire.alsa.enable = lib.mkForce false;
  #services.pipewire.pulse.enable = lib.mkForce false;

}
