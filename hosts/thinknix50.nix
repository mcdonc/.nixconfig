args@{
  config,
  pkgs,
  lib,
  nixos-hardware,
  ...
}:
{
  imports = [
    ../users/chrism
    ./roles/workstation.nix
    "${nixos-hardware}/lenovo/thinkpad/p50"
    "${nixos-hardware}/common/pc/ssd"
    ./roles/pseries.nix
    ./roles/encryptedzfs.nix
    ./roles/tlp.nix
    ./roles/vmount.nix
    ./roles/dns/resolved-tls.nix
    ./roles/backupsource.nix
    ./roles/davinci-resolve/studio.nix
    ./roles/nix-serve-client.nix
    ./roles/speedtest
    ./roles/tailscale
    #./roles/rc505
    # (
    #   import ./roles/macos-ventura.nix (
    #     args // { mem = "16G"; cores = 4; enable = false; }
    #   )
    # )
  ];

  systemd.tpm2.enable = false;

  # roadwork setup
  #
  #services.tlp = {
  #  enable = true;
  #  settings = {
  #    CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #    START_CHARGE_THRESH_BAT0 = lib.mkForce "85";
  #    STOP_CHARGE_THRESH_BAT0 = lib.mkForce "99";
  #    # rtl8153 / tp-link ue330 quirk for USB ethernet
  #    USB_DENYLIST = "2357:0601 0bda:5411";
  #  };
  #};

  system.stateVersion = "22.05";

  networking.hostId = "f416c9cd";
  networking.hostName = "thinknix50";

  # doesn't work, but for in the future...
  #services.fprintd.enable = true;
  #services.fprintd.tod.enable = true;
  #services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;

  hardware.nvidia.prime.offload.enable = lib.mkForce (
    !config.hardware.nvidia.prime.sync.enable
  );

  # to allow sleep, set to true
  hardware.nvidia.prime.sync.enable = lib.mkForce true;

}
