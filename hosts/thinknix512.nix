{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p51"
    ../pseries.nix
    ../encryptedzfs.nix
    ../sessile.nix
    ../rc505
    ../common.nix
#    ../oldnvidia.nix
  ];
  system.stateVersion = "22.05";

  # boot.zfs.extraPools = [ "b" ];
  
  # services.syncoid = {
  #   enable = true;
  #   interval = "*:0/1";
  #   commands = {
  #     "NIXROOT/test" = {
  #       target = "b/thinknix512-test";
  #       sendOptions = "raw";
  #       extraArgs = [ "--debug" ];
  #     };
  #   };
  #   localSourceAllow = options.services.syncoid.localSourceAllow.default ++ [ "mount" ];
  #   localTargetAllow = options.services.syncoid.localTargetAllow.default ++ [ "destroy" ];
  # };

  # services.sanoid = {
  #   enable = true;
  #   interval = "*:0/1";
  #   templates.backup = {
  #     autoprune = true;
  #     autosnap = true;
  #     hourly = 24;
  #     daily = 30;
  #     monthly = 6;
  #   };
  #   datasets."b/thinknix512-test" = {
  #     useTemplate = ["backup"];
  #   };
  #   extraArgs = [ "--debug" ];
  # };

  networking.hostId = "deadbeef";
  networking.hostName = "thinknix512";

  hardware.nvidia.prime.offload.enable = false;
  hardware.nvidia.prime.sync.enable = lib.mkForce true;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default
  # is 4)
  boot.consoleLogLevel = 3;

  # why must I do this?  I have no idea.  But if I don't, swnix pauses then
  # "fails" (really just prints an error) when it switches configurations.
  systemd.services.NetworkManager-wait-online.enable = false;
  
  #services.cachix-agent.enable = true;
}
