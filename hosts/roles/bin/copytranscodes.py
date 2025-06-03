#!@py@
import os
import argparse
import shutil

ignore_done = shutil.ignore_patterns("*.done")


def copy_transcodes(
        source_dir,
        target_dir,
        dont_recurse=False,
    ):

    transcoded_dir = ".transcoded"

    source_dir = os.path.abspath(source_dir)
    target_dir = os.path.abspath(target_dir)

    if os.path.exists(target_dir):
        if not os.path.isdir(target_dir):
            raise ValueError(f"cannot overwrite {target_dir}")

    subdirs = []
    for file in os.listdir(source_dir):
        source_file = os.path.join(source_dir, file)
        if file == transcoded_dir:
            shutil.copytree(
                source_file,
                target_dir,
                dirs_exist_ok=True,
                ignore=ignore_done,
            )
        elif os.path.isdir(source_file):
            subdirs.append(file)

    if not dont_recurse:
        for dir in subdirs:
            source_subdir = os.path.join(source_dir, dir)
            target_subdir = os.path.join(target_dir, dir)
            copy_transcodes(source_subdir, target_subdir, dont_recurse)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Copy directory with transcoded files."
    )
    parser.add_argument(
        "source_dir",
        help="Input directory containing video files to copy"
    )
    parser.add_argument(
        "target_dir",
        help="Target directory."
        )
    parser.add_argument(
        "--dont-recurse",
        "-d",
        action="store_true",
        help="Don't recurse into subdirs"
    )
    args = parser.parse_args()
    copy_transcodes(args.source_dir, args.target_dir, args.dont_recurse)
