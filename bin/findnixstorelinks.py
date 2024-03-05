#!@py@
import argparse
import os


def findnixstorelinks(path):
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
                    for p in prevent:
                        rel = os.path.relpath(full, home)
                        if rel.startswith(p):
                            break
                    else: # nobreak
                        print(rel)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Find and print all symlinks to /nix/store paths."
    )
    parser.add_argument(
        "--path",
        "-p",
        default="~",
        help="Source directory"
    )
    args = parser.parse_args()
    findnixstorelinks(args.path)

# tar cvzf /backup/location.tar.gz --exclude-from=<output of this script>
# rsync -avzP --exclude-from=<outfile> /b/optinix-home/.zfs/autosnap_2024-01-24_06:02:03_hourly/chrism/ /home/chrism/
