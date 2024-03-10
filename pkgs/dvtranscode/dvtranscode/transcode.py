import argparse
import csv
import os
import subprocess
import sys
import traceback

from io import StringIO

def parse_csv_line(self, line):
    file_like_object = StringIO(line)
    csv_reader = csv.reader(file_like_object)
    parsed_line = next(csv_reader)
    return parsed_line

def detect_nvidia():
    lspci_output = subprocess.run(
        ["lspci"],
        stdout=subprocess.PIPE,
        text=True
    )
    return lspci_output.stdout.lower().find('nvidia') != -1

def get_encoder(av1, software, nvidia_detected):
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
        if nvidia_detected:
            encoder = [
                '-c:v',
                'h264_nvenc',
            ]

    encoder.extend(['-c:a', 'pcm_s16le'])
    return encoder

def transcode(
        input_file,
        output_file,
        av1=False,
        software=False,
        dry_run=False,
        nvidia_detected=False,
    ):

    ff = [
        "ffmpeg",
        '-hide_banner',
        '-y',
    ]

    encoder = get_encoder(av1, software, nvidia_detected)

    temp_file = output_file + ".part"

    cmd = ff + ['-i', input_file] + encoder + ['-f', 'matroska', temp_file]

    if dry_run:
        print(' '.join(cmd))
    else:
        subprocess.run(cmd, check=True)
        try:
            os.rename(temp_file, os.path.splitext(temp_file)[0])
            return 0
        except FileNotFoundError:
            traceback.print_exc()
            return 2

def main(argv=sys.argv):
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
        "--dry-run",
        action="store_true",
        help="Print the ffmpeg commands that would be issued, do no encoding"
    )
    args = parser.parse_args()
    nvidia_detected = detect_nvidia()
    return transcode(
        args.input_filename,
        args.output_filename,
        args.av1,
        args.software,
        args.dry_run,
        nvidia_detected,
    )

if __name__ == "__main__":
    sys.exit(main(sys.argv))

