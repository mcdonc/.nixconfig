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
  ];

  system.stateVersion = "24.05";

  age.secrets."mcdonc-unhappy-cachix-authtoken" = {
    file = ../secrets/mcdonc-unhappy-cachix-authtoken.age;
    mode = "640";
    owner = "chrism";
    group = "users";
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
  boot.initrd.kernelModules = [ ];
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

  services.samba = {
    enable = true;
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
        "log level" = "nmbd:0";
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

  # filter out stupid samba nmdb messages from log (doesnt seem to work)
  systemd.services.samba-nmbd.serviceConfig = {
    StandardOutput = "null";
    StandardError = "null";
  };

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

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

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

  environment.systemPackages = with pkgs; [
    cifs-utils
    # used by zfs send/receive
    pv
    mbuffer
    lzop
    zstd
    #inputs.winboat.packages.x86_64-linux.winboat
    #freerdp # for winboat
  ];

  # services.pulseaudio.enable = lib.mkForce true;
  # services.pipewire.enable = lib.mkForce false;
  # services.pipewire.jack.enable = lib.mkForce false;
  # services.pipewire.alsa.enable = lib.mkForce false;
  # services.pipewire.pulse.enable = lib.mkForce false;

 security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "65536"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; }
 ];

 environment.etc."security/limits.conf".text = ''
    # set soft and hard nofile for all users
    * soft nofile 65536
    * hard nofile 1048576
  '';

}
