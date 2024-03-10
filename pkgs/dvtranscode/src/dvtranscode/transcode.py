import argparse
import json
import logging
import os
import subprocess
import sys
import traceback

from . import Logger

def detect_nvidia():
    lspci_output = subprocess.run(
        ["lspci"],
        stdout=subprocess.PIPE,
        text=True
    )
    return lspci_output.stdout.lower().find('nvidia') != -1


class Transcoder:
    def __init__(
            self,
            logger,
            software=False,
            verbose=False,
            nvidia_detected=False
    ):
        self.logger = logger
        self.software = software
        self.verbose = verbose
        self.nvidia_detected = nvidia_detected

    def needs_reencoding(self, file_path):
        try:
            cmd = [
                'ffprobe',
                '-v',
                'error',
                '-show_entries',
                'stream=codec_name',
                '-of',
                'json',
                file_path
            ]
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True
            )

            # Parse JSON output
            output = json.loads(result.stdout.decode('utf-8'))

            # Check if video and audio codecs match criteria
            need = { 'h264', 'pcm_s16le'}
            for stream in output['streams']:
                need.discard(stream['codec_name'])

            return bool(need)

        except subprocess.CalledProcessError as e:
            self.logger.warning(
                "Error running ffprobe:",
                e.stderr.decode('utf-8').strip()
            )
            return True

    def get_encoder(self, input_file):
        if self.needs_reencoding(input_file):
            encoder = [
                '-c:v',
                'libx264',
            ]

            if not self.software:
                if self.nvidia_detected:
                    encoder = [
                        '-c:v',
                        'h264_nvenc',
                    ]

            encoder.extend(['-c:a', 'pcm_s16le'])
        else:
            encoder = [
                '-c:v',
                'copy',
                '-c:a',
                'copy',
                ]

        return encoder

    def transcode(self, input_file, output_file):
        ff = [
            "ffmpeg",
            '-hide_banner',
            '-y',
        ]

        if self.verbose:
            ff.extend(['-loglevel', 'info'])
        else:
            ff.extend(['-loglevel', 'warning'])

        encoder = self.get_encoder(input_file)

        temp_file = output_file + ".part"

        cmd = ff + ['-i', input_file] + encoder + ['-f', 'matroska', temp_file]

        if self.verbose:
            self.logger.info(f"running {' '.join(cmd)}")

        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError as e:
            self.logger.warning(
                "Error running ffpeg:",
                e.stderr.decode('utf-8').strip()
            )
            raise

        try:
            final = os.path.splitext(temp_file)[0]
            os.rename(temp_file, final)
            if self.verbose:
                self.logger.info(f"renamed {temp_file} to {final}")
            return 0
        except FileNotFoundError:
            traceback.print_exc()
            return 2

def main(argv=sys.argv):
    logging.basicConfig(
        level=logging.INFO,
        format='%(message)s',
    )
    logger = Logger("transcode")
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
        "--software",
        "-s",
        action="store_true",
        help="Use software rendering instead of hardware",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print the commands being issued"
    )
    args = parser.parse_args()
    nvidia_detected = detect_nvidia()
    transcoder = Transcoder(
        logger,
        software=args.software,
        verbose=args.verbose,
        nvidia_detected=nvidia_detected
        )
    return transcoder.transcode(args.input_filename, args.output_filename)

if __name__ == "__main__":
    sys.exit(main(sys.argv))
