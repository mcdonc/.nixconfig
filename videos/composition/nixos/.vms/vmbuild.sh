#!/usr/bin/env bash
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
cd "$DIR" || exit
rm -rf ./results
mkdir ./results
vms=("barris") # "luckman" "arctor"
for vm in "${vms[@]}"; do
  nix build -I .. \
    ".#nixosConfigurations.$vm.config.system.build.vm" --out-link "results/$vm"
done
