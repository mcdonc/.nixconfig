{
  config,
  lib,
  pkgs,
  nixos-hardware,
  ...
}:

{
  imports = [
    ../users/chrism
    ./roles/workstation.nix
    "${nixos-hardware}/lenovo/thinkpad/p52"
    "${nixos-hardware}/common/pc/ssd"
    ./roles/pseries.nix
    ./roles/encryptedzfs.nix
    ./roles/tlp.nix
    ./roles/steam.nix
    ./roles/davinci-resolve/studio.nix
    ./roles/dns/resolved-tls.nix # cannot be enabled for tpm
    ./roles/backupsource.nix
    ./roles/tailscale
    ./roles/pocket-id.nix
    ./roles/pocket-id-sso.nix
    ./roles/nvidiapassthru.nix
    ./roles/klangk-jit-pool.nix
    ./roles/sudorelax.nix
    #./roles/nix-serve-client.nix
    #./roles/rc505
    #./roles/sessile.nix
    # ./roles/vmount.nix  # no steam when this is enabled, but nec for dvresolve
    # (
    #   import ./roles/macos-ventura.nix (
    #     args // {mem="12G"; cores=4; enable=true;}
    #   )
    # )
  ];

  system.stateVersion = "22.05";

  # per-host settings
  networking.hostId = "e1e4a33b";
  networking.hostName = "thinknix52";

  hardware.nvidia.prime.offload.enable = lib.mkForce (
    !config.hardware.nvidia.prime.sync.enable
  );

  # sleep doesnt work in offload mode 01/07/2025 kernel 6.6 nvidia 565
  # confirmed 07/12/2025 in 25.05
  hardware.nvidia.prime.sync.enable = lib.mkForce true;

  # XXX26.05 Quadro P1000 dropped from mainline 595.xx, needs legacy 580.xx
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

  # klangk CI: JIT ephemeral runner pool sharing the "nix"-labeled job
  # queue with keithmoon's pool. Two concurrent laptop-sized VMs
  # (klangk-jit52); the pool's own runner prefix keeps the two hosts from
  # pruning each other's registrations, and idle losers of the boot race
  # are killed after 10 minutes (see scripts/klangk-jit-pool.sh).
  # Disabled: prevent this host's GitHub runners from starting. Set back
  # to true (and `systemctl start klangk-jit-pool`) to rejoin the queue.
  services.klangk-jit-pool = {
    enable = false;
    maxVms = 2;
    vmHost = "klangk-jit52";
    runnerNamePrefix = "jit-thinknix52";
  };

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default
  # is 4)
  boot.consoleLogLevel = 3;

  # --- msks dev mode (#231): the capability wrapper the devenv msksd
  # process execs — setpriv carrying the two ambient caps the
  # daemon's egress stack needs (per-VM taps, nftables/NFQUEUE,
  # DHCP 67, DNS 53). Same grant as keithmoon: root-owned in
  # /run/wrappers, usable only as
  #   msks-caps --inh-caps=+net_admin,+net_bind_service \
  #     --ambient-caps=+net_admin,+net_bind_service -- <cmd>
  security.wrappers.msks-caps = {
    source = "${pkgs.util-linux}/bin/setpriv";
    capabilities = "cap_net_admin,cap_net_bind_service+ep";
    owner = "root";
    group = "users";
    permissions = "u+rx,g+rx";
  };

}
