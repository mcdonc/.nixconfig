#!/usr/bin/env python3
import sys
f = open('/tmp/commands', 'a')
argv = ' '.join(sys.argv)
f.write(argv)
print(argv)
allowed = """exit
echo -n
command -v lzop
command -v mbuffer
zpool get -o value -H feature@extensible_dataset 'NIXROOT'
zfs get -H syncoid:sync 'NIXROOT/home'
zfs get -H syncoid:sync 'NIXROOT/root'
""".split()
