# klangk JIT runner pool: polls GitHub Actions for queued klangk e2e jobs
# (label "nix") and boots one disposable klangk-jit VM per job with a
# just-in-time runner token. Replaces the long-lived multi-runner
# klangk-ci VM (kept in keithmoon.nix for rollback). The pool script
# (../../scripts/klangk-jit-pool.sh) and the VM closure are resolved at
# evaluation time; the PAT comes from the github-runner-klangk agenix
# secret (must list this host's key in secrets/secrets.nix).
#
# Multiple hosts may run this role against the same job queue: each pool
# names its JIT runners with its own runnerNamePrefix (so stale-runner
# pruning never touches another host's registrations) and the script
# kills runners that booted but lost the assignment race after 10 idle
# minutes.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.services.klangk-jit-pool;
in
{
  options.services.klangk-jit-pool = {
    enable = lib.mkEnableOption "klangk JIT ephemeral runner pool (per-job VMs)";

    maxVms = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4;
      description = "Maximum concurrent per-job VMs (i.e. runner slots).";
    };

    vmHost = lib.mkOption {
      type = lib.types.str;
      default = "klangk-jit";
      description = ''
        nixosConfiguration name of the disposable runner VM this pool boots.
        Hosts with less RAM/cores can point this at a resized klangk-jit
        variant (see hosts/klangk-jit52.nix).
      '';
    };

    runnerNamePrefix = lib.mkOption {
      type = lib.types.str;
      default = "jit";
      description = ''
        GitHub runner names are "''${prefix}-vm-<timestamp>-<pid>-<rand>".
        Stale-runner pruning only ever deletes runners matching this
        host's prefix, so each pool host needs its own.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets."github-runner-klangk" = {
      file = ../../secrets/github-runner-klangk.age;
    };

    systemd.services.klangk-jit-pool =
      let
        vm = inputs.self.nixosConfigurations.${cfg.vmHost}.config;
        poolScript = pkgs.writeShellScript "klangk-jit-pool" (
          builtins.replaceStrings
            [
              "@vmRun@"
              "@tokenFile@"
              "@maxVms@"
              "@runnerPrefix@"
            ]
            [
              "${vm.system.build.vm}/bin/run-${vm.system.name}-vm"
              "${config.age.secrets."github-runner-klangk".path}"
              (toString cfg.maxVms)
              cfg.runnerNamePrefix
            ]
            (builtins.readFile ../../scripts/klangk-jit-pool.sh)
        );
      in
      {
        description = "klangk JIT ephemeral runner pool (per-job VMs)";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        # jq/curl/qemu-img/flock for the pool; the VM run script needs
        # qemu & co.
        path = with pkgs; [
          curl
          jq
          qemu_kvm
          util-linux
        ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${poolScript}";
          # Per-job qcow2 disks + console logs live under the state dir
          # (/var/lib — NOT tmpfs, which would bill VM disk writes to RAM);
          # active-VM bookkeeping under the runtime dir.
          StateDirectory = "klangk-jit-pool";
          RuntimeDirectory = "klangk-jit-pool";
          Restart = "always";
          RestartSec = 10;
        };
      };
  };
}
