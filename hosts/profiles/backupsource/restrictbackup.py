#!/usr/bin/env python3
import os

sh = "/run/current-system/sw/bin/sh"

allowed = """exit
echo
command
zpool
zfs
""".split()

if __name__ == "__main__":
    original = os.environ['SSH_ORIGINAL_COMMAND'].strip()

    f = open('/tmp/commands', 'a')

    f.write(original + '\n')

    for name in allowed:
        if original.startswith(name):
            os.execvp(sh, [sh, "-c", original]) # no need to break
