{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    ../users/chrism
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/pc/ssd"
    ./roles/encryptedzfs.nix
    ./roles/dnsovertls/resolvedonly.nix
    ./roles/sessile.nix
    ./roles/davinci-resolve.nix
    ./roles/steam.nix
    ../common.nix
  ];

  system.stateVersion = "23.11";

  networking.hostId = "849b55f4";
  networking.hostName = "nixcentre";

  powerManagement.cpuFreqGovernor = "performance";

  # # use pulseaudio instead of pipewire for Resolve farlight recording
  # sound.enable = lib.mkForce true;
  # hardware.pulseaudio.enable = lib.mkForce true;
  # services.pipewire.enable = lib.mkForce false;

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.kernelParams = lib.mkForce [
    # 2GB max ARC cache
    "zfs.zfs_arc_max=2147483648"
  ];

  fileSystems."/nix" = {
    device = "NIXROOT/nix";
    fsType = "zfs";
  };

  boot.zfs.extraPools = [ "vid" ];

  # don't run updatedb on /v
  services.locate.prunePaths = [ "/v" ];

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;
    nvidiaSettings = true;

    # # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    port = 5432;
    dataDir="/v/postgresql/${config.services.postgresql.package.psqlSchema}";
    authentication = pkgs.lib.mkForce ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            trust
      host    all             all             192.168.1.0/24          trust
    '';
  initialScript = pkgs.writeText "postgres-init-script" ''
    CREATE ROLE resolve WITH LOGIN PASSWORD 'resolve' CREATEDB;
  '';
  };

  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = nixcentre
      netbios name = nixcentre
      security = user
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.1. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      v = {
        path = "/v";
        browseable = "yes";
        writeable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "chrism";
        "force group" = "users";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
  };

}
