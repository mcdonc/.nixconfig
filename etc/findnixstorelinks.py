import os
home = os.path.expanduser('~')
prevent = [
    os.path.join('.', '.cache'),
    os.path.join('.', '.local', 'share', 'Steam'),
    os.path.join('.', '.local', 'share', 'keybase'),
    os.path.join('.', '.local', 'share', 'baloo'),
    ]
for path in prevent:
    print(path)
for (root, dirs, files) in os.walk(home):
    for f in files:
        full = os.path.join(root, f)
        if os.path.islink(full):
            real = os.path.realpath(full)
            if real.startswith('/nix'):
                rel = '.' + full[len(home):]
                for p in prevent:
                    if rel.startswith(p):
                        break
                else: # nobreak
                    print(rel)
# tar cvzf /backup/location.tar.gz --exclude-from=<output of this script>
