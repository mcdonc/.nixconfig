args@{ config, pkgs, lib, nixos-hardware, options, ... }:

let
  monitor-sanoid-health = pkgs.writeShellScriptBin "monitor-sanoid-health" ''
    ${config.systemd.services.sanoid.serviceConfig.ExecStart} --monitor-health
  '';
  kscreen-doctor = "${pkgs.libsForQt5.libkscreen}/bin/kscreen-doctor";
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
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/pc/ssd"
    ./roles/encryptedzfs.nix
    ./roles/dnsovertls/resolvedonly.nix
    ./roles/speedtest
    ./roles/steam.nix
    ./roles/davinci-resolve.nix
    ./roles/vmount.nix
    ./roles/music.nix
    ./roles/rc505
    ../common.nix
    (
      import ./roles/macos-ventura.nix (
        args // { mem = "8G"; cores = 4; enable = false; }
      )
    )
  ];

  system.stateVersion = "23.11";
  networking.hostId = "0a2c6441";
  networking.hostName = "optinix";

  hardware.opengl.extraPackages = with pkgs; [ intel-compute-runtime ];

  # music
  powerManagement.cpuFreqGovernor = lib.mkForce "performance";

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
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
  ];

  fileSystems."/nix" = {
    device = "NIXROOT/nix";
    fsType = "zfs";
  };

  #swapDevices = [{ device = "/dev/zvol/NIXROOT/swap"; }];

  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/backup/sanoid.nix

  services.syncoid = {
    enable = true;
    interval = "*:35"; # run this less often than sanoid (every hour at 35 mins)
    commonArgs = [ "--debug" ];
    commands = {
      "optinix-home" = {
        source = "NIXROOT/home";
        target = "b/optinix-home";
        sendOptions = "w c";
      };
      # sudo zfs allow backup compression,hold,send,snapshot,mount,destroy NIXROOT/home
    };
    localSourceAllow = options.services.syncoid.localSourceAllow.default
      ++ [ "mount" ];
    localTargetAllow = options.services.syncoid.localTargetAllow.default
      ++ [ "destroy" ];
  };

  services.sanoid = {
    enable = true;
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
      "b/storage" = {
        autoprune = true;
        autosnap = true;
        hourly = 0;
        daily = 0;
        weekly = 2;
        monthly = 0;
        yearly = 0;
      };
      # https://github.com/jimsalterjrs/sanoid/wiki/Syncoid#snapshot-management-with-sanoid
      "b/optinix-home" = {
        autoprune = true;
        autosnap = false;
        hourly = 4;
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 0;
      };
    };
    extraArgs = [ "--debug" ];
  };

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
    # used by zfs send/receive
    pv
    mbuffer
    lzop
    zstd

    # health
    monitor-sanoid-health

    # kscreendoctor
    left-screen-1080p
    left-screen-4k
  ];

}
