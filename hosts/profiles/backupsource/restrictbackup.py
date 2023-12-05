#!/usr/bin/env python3
import os

bash = "/run/current-system/sw/bin/bash"

allowed = """exit
echo
command
zpool
zfs
""".split()

if __name__ == "__main__":
    original = os.environ['SSH_ORIGINAL_COMMAND']

    f = open('/tmp/commands', 'a')

    f.write(original + '\n')
    print(original)
    for name in allowed:
        if original.startswith(name):
            os.execvp(bash, [bash,  "-c", f'"{original}"']) # no need to break
