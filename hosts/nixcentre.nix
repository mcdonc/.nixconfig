{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/pc/ssd"
    ./profiles/encryptedzfs.nix
    ./profiles/dnsovertls/resolvedonly.nix
    ./profiles/sessile.nix
    ./profiles/davinci-resolve.nix
    ../common.nix
  ];

  system.stateVersion = "23.11";

  networking.hostId = "849b55f4";
  networking.hostName = "nixcentre";

  powerManagement.cpuFreqGovernor = "performance";

  # use pipewire for Resolve
  sound.enable = lib.mkForce true;
  hardware.pulseaudio.enable = lib.mkForce true;
  services.pipewire.enable = lib.mkForce false;
  
  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # 2GB max ARC cache
  boot.kernelParams = lib.mkForce [ "zfs.zfs_arc_max=2147483648" ];

  fileSystems."/nix" = {
    device = "NIXROOT/nix";
    fsType = "zfs";
  };

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"]; # or "nvidiaLegacy470 etc.

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

}
