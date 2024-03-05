#!@py@
import os
import subprocess
import argparse

def touch(fname):
    with open(fname, 'a'):
        os.utime(fname)

def transcode_directory(
        input_dir,
        h264_encoding=False,
        recurse=False,
        yes=False,
        dry_run=False,
        ignore_done=False,
    ):

    command = [
        'ffmpeg',
    ]

    if yes:
        command.append('-y')

    encoder = [
        '-c:v',
        'libsvtav1',
        '-preset',
        '10',
        '-crf',
        '35',
    ]

    if h264_encoding:
        lspci_output = subprocess.run(
            ['lspci'],
            stdout=subprocess.PIPE,
            text=True
        )
        nvidia_detected = lspci_output.stdout.lower().find('nvidia') != -1
        if nvidia_detected:
            encoder = [
                '-c:v',
                'h264_nvenc',
            ]
        else:
            encoder = [
                '-c:v',
                'libx264',
            ]

    encoder.extend(['-c:a', 'pcm_s16le'])

    transcoded_dir = ".transcoded"

    input_dir = os.path.abspath(input_dir)
    output_dir = os.path.join(input_dir, transcoded_dir)

    if os.path.exists(output_dir):
        if not os.path.isdir(output_dir):
            raise ValueError(f"cannot overwrite {output_dir}")

    made = False

    subdirs = []
    
    for filename in os.listdir(input_dir):
        input_file = os.path.join(input_dir, filename)
        if os.path.islink(input_file):
            continue
        elif os.path.isdir(input_file):
            subdirs.append(filename)
        else:
            lowered = input_file.lower()
            if lowered.endswith(".mp4") or lowered.endswith(".mkv"):
                relative_path = os.path.relpath(input_file, input_dir)
                no_ext = os.path.splitext(relative_path)[0]
                output_file = os.path.join(output_dir,  no_ext + ".mkv")
                if not ignore_done:
                    if os.path.exists(output_file + '.done'):
                        continue
                cmd = command + [ '-i', input_file ] + encoder + [ output_file ]
                print(' '.join(cmd))
                if not made:
                    if not dry_run:
                        os.makedirs(output_dir, exist_ok=True)
                    made = True
                if not dry_run:
                    subprocess.run(cmd, check=True)
                    touch(output_file + '.done')

    if recurse:
        for subdir in subdirs:
            if subdir != transcoded_dir:
                input_subdir = os.path.join(input_dir, subdir)
                transcode_directory(
                    input_subdir,
                    h264_encoding,
                    recurse,
                    yes,
                    dry_run,
                    ignore_done,
                )

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Transcode video files in a directory to AV1."
    )
    parser.add_argument(
        "input_dir",
        help="Input directory containing video files to transcode"
    )
    parser.add_argument(
        "--h264",
        action="store_true",
        help="Encode resulting files to H.264 instead of AV1"
    )
    parser.add_argument(
        "--recurse",
        "-r",
        action="store_true",
        help="Recurse into subdirs"
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
    parser.add_argument(
        "--ignore-done",
        action="store_true",
        help="Ignore done markers"
    )
    args = parser.parse_args()
    transcode_directory(
        args.input_dir,
        args.h264,
        args.recurse,
        args.yes,
        args.dry_run,
        args.ignore_done,
    )
