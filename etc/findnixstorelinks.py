import sys
import os

if len(sys.argv) > 1:
    path = sys.argv[1]
else:
    path = "~"

home = os.path.expanduser(path)
prevent = [
    os.path.join('.cache'),
    os.path.join('.local', 'share', 'Steam'),
    os.path.join('.local', 'share', 'keybase'),
    os.path.join('.local', 'share', 'baloo'),
    ]
for path in prevent:
    print(path)
for (root, dirs, files) in os.walk(home):
    for f in files:
        full = os.path.join(root, f)
        if os.path.islink(full):
            real = os.path.realpath(full)
            if real.startswith('/nix'):
                rel = '.' + full[len(home)+2:]
                for p in prevent:
                    if rel.startswith(p):
                        break
                else: # nobreak
                    print(rel)
# tar cvzf /backup/location.tar.gz --exclude-from=<output of this script>
# rsync -avzP --exclude-from=<outfile> /b/optinix-home/.zfs/autosnap_2024-01-24_06:02:03_hourly/chrism/ /home/chrism/
