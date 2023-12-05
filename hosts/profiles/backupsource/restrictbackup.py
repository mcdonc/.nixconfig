#!/usr/bin/env python3
import os

f = open('/tmp/commands', 'a')
original = os.environ['SSH_ORIGINAL_COMMAND']

f.write(original + '\n')
print(original)

allowed = """exit
echo -n
command -v lzop
command -v mbuffer
zpool get -o value -H feature@extensible_dataset 'NIXROOT'
zfs get -H syncoid:sync 'NIXROOT/home'
zfs get -H syncoid:sync 'NIXROOT/root'
""".split()
