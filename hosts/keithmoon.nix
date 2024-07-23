{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    ../users/chrism
    ./roles/intel.nix
    "${nixos-hardware}/common/pc/ssd"
    ./roles/encryptedzfs.nix
    ./roles/dnsovertls/resolvedonly.nix
    ./roles/davinci-resolve/studio.nix
    ./roles/steam.nix
    ../common.nix
  ];

  system.stateVersion = "24.05";

  networking.hostId = "90ca4330";
  networking.hostName = "keithmoon";

  boot.initrd.availableKernelModules = [
    "ahci" "xhci_pci" "ehci_pci" "megaraid_sas" "usb_storage" "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/nix" =
    { device = "NIXROOT/nix";
      fsType = "zfs";
    };

  boot.zfs.extraPools = [ "d" ];

  # 32 GB max ARC cache
  boot.kernelParams = [
    "zfs.zfs_arc_max=34359738368" 
    # required by wayland, see https://blog.davidedmundson.co.uk/blog/running-kwin-wayland-on-nvidia/
    "nvidia-drm.modeset=1"
  ];
  # not encrypted
  boot.zfs.requestEncryptionCredentials = lib.mkForce false;
  #services.desktopManager.plasma6.enable = lib.mkForce false;
  #services.xserver.enable = lib.mkForce false;
  #services.displayManager.sddm.enable = lib.mkForce false;

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

  environment.systemPackages = [ pkgs.cifs-utils ];

  services.samba = {
    enable = true;
    package = pkgs.samba4Full;
    openFirewall = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = keithmoon
      netbios name = keithmoon
      security = user
      browseable = yes
      smb encrypt = required
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.1. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
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

}
