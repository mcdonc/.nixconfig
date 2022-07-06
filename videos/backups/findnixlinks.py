# Find all symlinks in the current user's home directory that point to
# somewhere under ``/nix``.

import os
home = os.path.expanduser('~')
for (root, dirs, files) in os.walk(home):
    for f in files:
        full = os.path.join(root, f)
        if os.path.islink(full):
            real = os.path.realpath(full)
            if real.startswith('/nix'):
                print('.' + full[len(home):])
print(os.path.join('.', '.cache'))

# tar cvzf /backup/location.tar.gz --exclude-from=<file containing this script output>
