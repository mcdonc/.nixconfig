#!/usr/bin/env python3
import os

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
            result = os.popen(original).read()
            f.write(result+"\n")
            print(result)
