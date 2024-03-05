#!@py@
import os
import argparse
import shutil

def copy_transcodes(
        source_dir,
        target_dir,
        recurse=False,
    ):

    transcoded_dir = "transcoded"

    source_dir = os.path.abspath(source_dir)
    target_dir = os.path.abspath(target_dir)

    if os.path.exists(target_dir):
        if not os.path.isdir(target_dir):
            raise ValueError(f"cannot overwrite {target_dir}")

    subdirs = []
    for file in os.listdir(source_dir):
        if file == transcoded_dir:
            shutil.copytree(
                os.path.join(src_dir, transcoded_dir),
                target_dir,
                dirs_exist_ok=True,
            )
        elif os.path.isdir(source_file):
            subdirs.append(source_file)

    if recurse:
        for dir in subdirs:
            source_subdir = os.path.join(source_dir, dir)
            target_subdir = os.path.join(target_dir, dir)
            copy_transcodes(source_subdir, target_subdir, recurse)

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
        "--recurse",
        action="store_true",
        help="Recurse into subdirs"
    )
    args = parser.parse_args()
    copy_transcodes(args.source_dir, args.target_dir, args.recurse)
