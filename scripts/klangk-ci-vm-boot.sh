#!/usr/bin/env bash
# Persistent-disk boot of the klangk-ci VM (run by the klangk-ci-vm system
# unit on keithmoon). qemu-vm.nix's run script seeds NIX_DISK_IMAGE from its
# temp image on first boot — pointing it at a fixed path gives persistence.
#
# vmout (the current VM closure path) and klangk-ci.qcow2 (the persistent
# disk) live in ~/vm/klangk-ci, managed outside this script: writing a new
# closure path to vmout and restarting the unit switches the VM generation.
set -euo pipefail

vm_dir="$HOME/vm/klangk-ci"
out=$(cat "$vm_dir/vmout")
export NIX_DISK_IMAGE="$vm_dir/klangk-ci.qcow2"
cd "$vm_dir"
exec "$out/bin/run-klangk-ci-vm"
