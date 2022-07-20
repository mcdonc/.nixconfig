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
print(os.path.join('.', '.local', 'share', 'Steam'))
print(os.path.join('.', '.local', 'share', 'keybase'))
print(os.path.join('.', '.local', 'share', 'baloo'))
# tar cvzf /backup/location.tar.gz --exclude-from=<output of this script>
