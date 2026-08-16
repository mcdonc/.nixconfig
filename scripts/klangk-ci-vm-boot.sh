#!/usr/bin/env bash
# Persistent-disk boot of the klangk-ci VM (run by the klangk-ci-vm system
# unit on keithmoon). qemu-vm.nix's run script seeds NIX_DISK_IMAGE from its
# temp image on first boot — pointing it at a fixed path gives persistence.
#
# The VM closure path is baked in by keithmoon's NixOS config at evaluation
# time (via klangk-ci's system.build.vm), so `nixos-rebuild switch` on
# keithmoon automatically picks up klangk-ci config changes — no manual
# vmout step needed.
set -euo pipefail

vm_dir="$HOME/vm/klangk-ci"
export NIX_DISK_IMAGE="$vm_dir/klangk-ci.qcow2"
cd "$vm_dir"
exec "@vmClosure@/bin/run-klangk-ci-vm"
