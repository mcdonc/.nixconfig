# NixOS VM "klangk-jit52" — laptop-sized klangk-jit variant.
#
# thinknix52's JIT pool (roles/klangk-jit-pool.nix) boots one fresh copy
# of this VM per queued e2e job, exactly like keithmoon's pool does with
# klangk-jit — but sized for a ThinkPad P52 host (6c/12t) that also runs
# a desktop: fewer cores and less RAM per VM. Everything else (one-shot
# JIT registration, rootless podman, host-store/tarball-cache 9p
# sharing) is inherited from klangk-jit.nix.
{
  lib,
  ...
}:

{
  imports = [ ./klangk-jit.nix ];

  networking.hostName = lib.mkForce "klangk-jit52";
  networking.hostId = lib.mkForce "44194a30";

  # P52 sizing: leave the host enough of its 6c/12t to stay usable while
  # CI runs. Bump memorySize (and maxVms) if this machine has >= 64G.
  virtualisation.cores = lib.mkForce 6;
  virtualisation.memorySize = lib.mkForce 16384;
  virtualisation.diskSize = lib.mkForce 51200;
}
