args@{ config, pkgs, lib, nixos-hardware, options, ... }:

let
  monitor-sanoid-health = pkgs.writeShellScriptBin "monitor-sanoid-health" ''
    ${config.systemd.services.sanoid.serviceConfig.ExecStart} --monitor-health
  '';
  kscreen-doctor = "${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor";
  left-screen-1080p = pkgs.writeShellScriptBin "left-screen-1080p" ''
    ${kscreen-doctor} output.HDMI-1.mode.1920x1080@60
  '';
  left-screen-4k = pkgs.writeShellScriptBin "left-screen-4k" ''
    ${kscreen-doctor} output.HDMI-1.mode.3840x2160@30
  '';
in
{
  imports = [
    ../users/chrism
    ./roles/workstation
    ./roles/intel.nix
    "${nixos-hardware}/common/pc/ssd"
    ./roles/encryptedzfs.nix
    ./roles/dnsovertls/resolvedonly.nix
    ./roles/speedtest
    ./roles/steam.nix
    ./roles/davinci-resolve/studio.nix
    #./roles/vmount.nix
    ./roles/keithclient.nix
    ./roles/backupsource
    #    ./roles/proaudio.nix
    #    ./roles/rc505
    (
      import ./roles/macos-ventura.nix (
        args // { mem = "8G"; cores = 4; enable = false; }
      )
    )
  ];

  hardware.opengl.extraPackages = with pkgs; [ intel-compute-runtime ];

  system.stateVersion = "23.11";
  networking.hostId = "0a2c6441";
  networking.hostName = "optinix";

  # music, doesn't actually work for some reason
  powerManagement.enable = lib.mkForce true;
  powerManagement.cpuFreqGovernor = lib.mkForce "performance";

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.zfs.extraPools = [ "b" ];

  # dont ask for "b/storage" credentials
  boot.zfs.requestEncryptionCredentials = lib.mkForce [ "NIXROOT" ];

  # don't run updatedb on /b
  services.locate.prunePaths = [ "/b" ];

  boot.kernelParams = lib.mkForce [
    # music
    "threadirqs"
    # 2GB max ARC cache
    "zfs.zfs_arc_max=2147483648"
    # run in performance mode, dammit
    "cpufreq.default_governor=performance"
    "intel_pstate=disable"
  ];

  fileSystems."/nix" = {
    device = "NIXROOT/nix";
    fsType = "zfs";
  };

  #swapDevices = [{ device = "/dev/zvol/NIXROOT/swap"; }];

  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip duo_table {
        chain duo_nat {
          type nat hook postrouting priority filter; policy accept;
          oifname "enp1s0" masquerade
        }

        chain duo_forward {
          type filter hook forward priority filter; policy accept;
          iifname "enp0s20f0u7u2" oifname "enp1s0" accept
        }
      }
    '';
  };

  environment.systemPackages = with pkgs; [
    # health
    monitor-sanoid-health

    # kscreendoctor
    left-screen-1080p
    left-screen-4k

  ];

  # silence ACPI "errors" spewed to console at boot time (default is 4)
  boot.consoleLogLevel = 3;

}
