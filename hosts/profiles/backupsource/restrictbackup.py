#!/usr/bin/env python3
import os

sh = "/run/current-system/sw/bin/sh"

allowed = ("exit", "echo", "command", "zpool", "zfs")

# This would require a lot more work to be truly secure (anticipate ";", "&",
# "&&", $(cmd), `cmd` injection).  It'd be a project.

if __name__ == "__main__":

    original = os.environ.get('SSH_ORIGINAL_COMMAND', '').strip()

    if original:

        f = open('/tmp/commands', 'a')

        f.write(original + '\n')

        for name in allowed:
            if original.startswith(name):
                os.execvp(sh, [sh, "-c", original]) # no need to break
