{ config, lib, pkgs, ... }:

{
  imports = [
    <nixos-hardware-fork/lenovo/thinkpad/p52>
    ../common/pseries.nix
    ../common/p52sleep.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
  ];

  # override optimus default offload mode to deal with external monitor
  hardware.nvidia.prime.offload.enable = lib.mkForce false;
  hardware.nvidia.prime.sync.enable = true;

  networking.hostId = "e1e4a33b";
  networking.hostName = "thinknix52";
  networking.useDHCP = lib.mkForce true;

  # why?  I have no idea.
  systemd.services.NetworkManager-wait-online.enable = false;
  
  powerManagement.enable = true;
  powerManagement.resumeCommands =
    ''
      /bin/sh -c 'echo -n "0000:02:00.0"> /sys/bus/pci/drivers/nvme/bind'
      /bin/sh -c 'echo -n "0000:01:00.0"> /sys/bus/pci/drivers/nvidia/bind'
      /bin/sh -c 'echo -n "0000:01:00.0"> /sys/bus/pci/drivers/nvidia_drm/bind'
    '';
  powerManagement.powerDownCommands =
    ''
      /bin/sh -c 'echo -n "0000:02:00.0"> /sys/bus/pci/drivers/nvme/unbind'
      /bin/sh -c 'echo -n "0000:01:00.0"> /sys/bus/pci/drivers/nvidia/unbind'
      /bin/sh -c 'echo -n "0000:01:00.0"> /sys/bus/pci/drivers/nvidia_drm/unbind'
    '';
  
}


