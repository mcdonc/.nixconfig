#!@py@
import os
import subprocess
import argparse

def transcode_directory(
        input_dir,
        h264_encoding=False,
        recurse=False,
        yes=False
    ):
    # Output directory for transcoded files
    output_dir = os.path.join(input_dir, ".transcoded")

    # Create output directory if it doesn't exist
    if os.path.exists(output_dir):
        if not os.path.isdir(output_dir):
            raise ValueError(f"cannot overwrite {output_dir}")
    else:
        os.makedirs(output_dir)

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

    for root, dirs, files in os.walk(input_dir):

        for file in files:
            input_file = os.path.join(root, file)
            lowered = file.lower()
            if lowered.endswith(".mp4") or lowered.endswith(".mkv"):
                relative_path = os.path.relpath(input_file, input_dir)
                no_ext = os.path.splitext(relative_path)[0]
                output_file = os.path.join(output_dir,  no_ext + ".mkv")
                cmd = command + [ '-i', input_file ] + encoder + [ output_file ]
                print(cmd)
                subprocess.run(cmd)

        if recurse:
            for dir in dirs:
                if dir != ".transcoded":
                    input_dir = os.path.join(root, dir)
                    transcode_directory(input_dir, h264_encoding, recurse, yes)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Transcode video files in a directory."
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
        action="store_true",
        help="Recurse into subdirs"
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Overwrite existing files"
    )
    args = parser.parse_args()
    transcode_directory(args.input_dir, args.h264, args.recurse, args.yes)
