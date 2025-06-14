{
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    ../users/chrism
    ../users/larry
    ./roles/workstation.nix
    (modulesPath + "/profiles/qemu-guest.nix")
    {
    }
  ];

  home-manager = {
    users.chrism.home.packages = with pkgs; [
      gpu-viewer
    ];
  };

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.enable = true;
  boot.loader.timeout = 60;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9f6f3554-a000-4f9e-b3b9-844a2a7a8cb0";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/6c848ad1-2f09-467c-8746-c415c6b1b696"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.hostId = "fd244a99";
  networking.hostName = "nixos-vm";
  system.stateVersion = "23.11";

  services.spice-vdagentd.enable = true;
  services.spice-autorandr.enable = true;

  # virtualisation.virtualbox.guest = {
  #   enable = true;
  #   x11 = true;
  # };
  #services.xserver.desktopManager.plasma6.enable = true;
  #services.xserver.desktopManager.plasma5.enable = lib.mkForce false;

}
