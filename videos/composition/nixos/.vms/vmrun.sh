#!/usr/bin/env bash
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
cd "$DIR" || exit
QEMU_KERNEL_PARAMS=console=ttyS0 ./results/$1/bin/run-$1-vm -nographic

