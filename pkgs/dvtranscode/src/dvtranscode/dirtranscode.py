import argparse
import logging
import os
import subprocess
import sys
import traceback

from . import MEDIA, Logger
from .transcode import detect_nvidia, Transcoder

TRANSCODED = "transcoded"

def touch(fname):
    with open(fname, 'a'):
        os.utime(fname)

def dirtranscode(
        input_dir,
        logger,
        software=False,
        recurse=False,
        verbose=False,
        nvidia_detected=False,
        overrides=(),
    ):

    ignore_dirs = [ TRANSCODED ]

    input_dir = os.path.abspath(input_dir)
    output_dir = os.path.join(input_dir, TRANSCODED)

    if os.path.exists(output_dir):
        if not os.path.isdir(output_dir):
            raise ValueError(f"cannot overwrite {output_dir}")

    made = False

    subdirs = []

    try:
        input_files = os.listdir(input_dir)
    except FileNotFoundError:
        logger.exception(f"trying to listdir {input_dir}")
        input_files = []

    for filename in input_files:
        input_file = os.path.join(input_dir, filename)
        if os.path.islink(input_file):
            continue
        elif os.path.isdir(input_file):
            subdirs.append(filename)
        else:
            lowered = input_file.lower()
            if lowered.endswith(MEDIA):
                relative_path = os.path.relpath(input_file, input_dir)
                no_ext = os.path.splitext(relative_path)[0]
                output_file = os.path.join(output_dir,  no_ext + ".mkv")
                if os.path.exists(output_file):
                    if input_file in overrides:
                        if verbose:
                            logger.info(f"forced reencoding of {input_file}")
                    else:
                        continue
                if not made:
                    os.makedirs(output_dir, exist_ok=True)
                    if verbose:
                        logger.info(f"making dir {output_dir}")
                    made = True
                try:
                    transcoder = Transcoder(
                        logger,
                        verbose=verbose,
                        nvidia_detected=nvidia_detected
                    )
                    transcoder.transcode(input_file, output_file)
                except subprocess.CalledProcessError:
                    logger.exception(f"transcoding failed for {input_file}")

    if recurse:
        for subdir in subdirs:
            if subdir not in ignore_dirs:
                input_subdir = os.path.join(input_dir, subdir)
                dirtranscode(
                    input_subdir,
                    logger,
                    software=software,
                    recurse=recurse,
                    verbose=verbose,
                    nvidia_detected=nvidia_detected,
                    overrides=overrides,
                )

def main(argv=sys.argv):
    logging.basicConfig(
        level=logging.INFO,
        format='%(message)s',
    )
    logger = Logger("dirtranscode")
    parser = argparse.ArgumentParser(
        description="Transcode video files in a directory to H264+PCM."
    )
    parser.add_argument(
        "input_dir",
        help="Input directory containing video files to transcode"
    )
    parser.add_argument(
        "--recurse",
        "-r",
        action="store_false",
        default=True,
        help="Recurse into subdirs"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print the commands being issued"
    )
    parser.add_argument(
        "--software",
        "-s",
        action="store_true",
        help="Use software rendering instead of hardware",
    )
    args = parser.parse_args()
    nvidia_detected = detect_nvidia()
    try:
        dirtranscode(
            args.input_dir,
            logger,
            software=args.software,
            recurse=args.recurse,
            verbose=args.verbose,
            nvidia_detected=nvidia_detected,
        )
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    main(sys.argv)
