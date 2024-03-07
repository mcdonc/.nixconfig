#!@py@
import argparse
import os
import select
import subprocess
import sys

import csv
from io import StringIO

MEDIA = (".mp4", ".mkv", ".MP4", ".MKV")
TRANSCODED = "transcoded"
INOTIFYWAIT = "@inotifywait@"
LSPCI = "@lspci@"
FFMPEG = "@ffmpeg@"

if INOTIFYWAIT.startswith("@"):
    INOTIFYWAIT = "inotifywait" # not text-replaced

if LSPCI.startswith("@"):
    LSPCI = "lspci"

if FFMPEG.startswith("@"):
    FFMPEG = "ffmpeg"

class Monitor:
    def __init__(self, intake_dir):
        self.program_command = [
            INOTIFYWAIT,
            "-c", # CSV
            "-mr",
            "-e"
            "close_write",
            "-e"
            "moved_to",
            "-e"
            "moved_from",
            "-e"
            "delete",
            intake_dir,
            ]
        self.av1_encoding = False

    def get_encoder(self):
        command = [
            'ffmpeg',
            '-hide_banner',
        ]

        command.append('-y')

        if self.av1_encoding:
            encoder = [
                '-c:v',
                'libsvtav1',
                '-preset',
                '10',
                '-crf',
                '35',
            ]

        else:
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
            else:
                encoder = [
                    '-c:v',
                    'libx264',
                ]

        encoder.extend(['-c:a', 'pcm_s16le'])
        return command, encoder

    def parse_csv_line(self, line):
        file_like_object = StringIO(line)
        csv_reader = csv.reader(file_like_object)
        parsed_line = next(csv_reader)
        return parsed_line

    def DELETE(self, event_dir, event_file):
        no_ext = os.path.splitext(event_file)[0]
        transcode_file = os.path.join(
            event_dir,
            TRANSCODED,
            no_ext + '.mkv'
        )
        temp_file = transcode_file + ".part"
        for filename in temp_file, transcode_file:
            print(f"deleting {filename}")
            try:
                os.unlink(filename)
            except FileNotFoundError:
                pass
        transcode_dir = os.path.join(event_dir, TRANSCODED)
        if os.path.isdir(transcode_dir):
            if not os.listdir(transcode_dir):
                try:
                    os.rmdir(transcode_dir)
                except FileNotFoundError:
                    pass

    MOVED_FROM = DELETE

    def CLOSE_WRITE__CLOSE(self, event_dir, event_file):
        input_file = os.path.join(event_dir, event_file)
        output_dir = os.path.join(event_dir, TRANSCODED)
        no_ext = os.path.splitext(event_file)[0]
        temp_file = os.path.join(output_dir, no_ext + ".mkv.part")
        print(f"transcode {input_file} to {temp_file}")

        if os.path.exists(output_dir):
            if not os.path.isdir(output_dir):
                raise RuntimeError(f"cannot overwrite {output_dir}")

        os.makedirs(output_dir, exist_ok=True)
        command, encoder = self.get_encoder()
        cmd = (
            command +
            [ '-i', input_file ] +
            encoder +
            [ '-f', 'matroska', temp_file ]
        )
        print(' '.join(cmd))
        p = subprocess.run(cmd)
        if p.returncode:
            try:
                os.unlink(temp_file)
            except FileNotFoundError:
                pass
        else:
            os.rename(temp_file, os.path.splitext(temp_file)[0])

    MOVED_TO = CLOSE_WRITE__CLOSE

    def runforever(self):
        try:
            # Start the external program and capture its output
            print(' '.join(self.program_command))
            process = subprocess.Popen(
                self.program_command,
                stdout=subprocess.PIPE
            )
            # Create a poller to monitor the program's output
            poller = select.poll()
            poller.register(process.stdout.fileno(), select.POLLIN)
            self.poll(process, poller)

        except KeyboardInterrupt:
            pass

    def poll(self, process, poller):
        # Monitor the program's output for changes
        while True:
            events = poller.poll()
            for fd, event in events:
                if event & select.POLLIN:
                    new_data = process.stdout.readline()
                    if isinstance(new_data, bytes):
                        new_data = new_data.decode("utf-8")
                    event_dir, flags, event_file = self.parse_csv_line(new_data)
                    flags = '__'.join(flags.split(','))
                    print(f"{event_dir} {flags} {event_file}")
                    if TRANSCODED in event_dir.split(os.path.sep):
                        continue
                    if event_file.endswith(MEDIA):
                        op = getattr(self, flags, None)
                        if op is not None:
                            op(event_dir, event_file)
            if process.poll() is not None:
                raise RuntimeError("process exited")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Transcode video files in an intake directory."
    )
    parser.add_argument(
        "intake_dir",
        help="Intake directory"
    )
    args = parser.parse_args()
    monitor = Monitor(os.path.abspath(args.intake_dir))
    monitor.runforever()
