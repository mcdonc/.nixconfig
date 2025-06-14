{ lib, nixos-hardware, ... }:

{
  imports = [
    ../users/chrism
    ./roles/workstation.nix
    ./roles/intel.nix
    "${nixos-hardware}/common/pc/ssd"
    ./roles/encryptedzfs.nix
    ./roles/sessile.nix
    ./roles/dnsovertls/resolvedonly.nix
  ];

  system.stateVersion = "23.05";

  networking.hostId = "eeabbced";
  networking.hostName = "thinkcentre1";

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = false;
    };

    # is this too much?  It's convenient for Steam.
    opengl = {
      enable = true;
      driSupport = lib.mkDefault true;
      driSupport32Bit = lib.mkDefault true;
    };
  };

}
