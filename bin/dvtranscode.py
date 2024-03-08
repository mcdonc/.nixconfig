#!@py@
import argparse
import os
import select
import subprocess
import sys

import csv
from io import StringIO

LSPCI = "@lspci@"
FFMPEG = "@ffmpeg@"

if LSPCI.startswith("@"):
    LSPCI = "lspci"

if FFMPEG.startswith("@"):
    FFMPEG = "ffmpeg"

def get_encoder(av1, software):
    if av1:
        encoder = [
            '-c:v',
            'libsvtav1',
            '-preset',
            '10',
            '-crf',
            '35',
        ]
        software = True

    else:
        encoder = [
                '-c:v',
                'libx264',
            ]

    if not software:
        lspci_output = subprocess.run(
            [LSPCI],
            stdout=subprocess.PIPE,
            text=True
        )
        nvidia_detected = lspci_output.stdout.lower().find('nvidia') != -1
        if nvidia_detected:
            encoder = [
                '-c:v',
                'h264_nvenc',
            ]

    encoder.extend(['-c:a', 'pcm_s16le'])
    return encoder

def transcode(input_filename, output_filename, av1, software, yes, dry_run):
    command = [
        FFMPEG,
        '-hide_banner',
    ]

    if yes:
        command.append('-y')

    encoder = get_encoder(av1, software)

    cmd = command + [ '-i', input_filename ] + encoder + [ output_filename ]

    if dry_run:
        print(' '.join(cmd))
    else:
        subprocess.run(cmd)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Transcode a video files to H264/PCM/MKV."
    )
    parser.add_argument(
        "input_filename",
        help="Input video filename"
    )
    parser.add_argument(
        "output_filename",
        help="Output video filename",
        )
    parser.add_argument(
        "--av1",
        "-a",
        action="store_true",
        help="Encode resulting files to AVI1 instead of H264"
    )
    parser.add_argument(
        "--software",
        "-s",
        action="store_true",
        help="Use software rendering instead of hardware",
    )
    parser.add_argument(
        "--yes",
        "-y",
        action="store_true",
        help="Overwrite existing files"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the ffmpeg commands that would be issued, do no encoding"
    )
    args = parser.parse_args()
    transcode(
        args.input_filename,
        args.output_filename,
        args.av1,
        args.software,
        args.yes,
        args.dry_run,
    )
