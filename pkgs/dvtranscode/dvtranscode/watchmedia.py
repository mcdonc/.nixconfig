import argparse
import csv
import io
import os
import select
import subprocess
import sys
import multiprocessing

WORK_PENDING = multiprocessing.Event()

from . import (
    TRANSCODED,
    MEDIA
    )

from .dirtranscode import dirtranscode
from .transcode import detect_nvidia

class Monitor:
    def __init__(self, media_dir, nvidia_detected=False):
        self.nvidia_detected = nvidia_detected
        self.media_dir = media_dir
        self.command = [
            "inotifywait",
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
            media_dir,
        ]

    def parse_csv_line(self, line):
        file_like_object = io.StringIO(line)
        csv_reader = csv.reader(file_like_object)
        parsed_line = next(csv_reader)
        return parsed_line

    def runforever(self):
        try:
            # Start the external program and capture its output
            print(' '.join(self.command))
            process = subprocess.Popen(
                self.command,
                stdout=subprocess.PIPE,
                text=True,
            )
            # Create a poller to monitor the program's output
            poller = select.poll()
            poller.register(process.stdout.fileno(), select.POLLIN)
            self.poll(process, poller)
        except KeyboardInterrupt:
            pass

    def poll(self, process, poller):
        # Monitor the program's output for additions and changes to media
        # files
        while True:
            events = poller.poll()
            work_pending = False
            for fd, event in events:
                if event & select.POLLIN:
                    new_data = process.stdout.readline()
                    event_dir, flags, event_file = self.parse_csv_line(new_data)
                    print(f"{event_dir} {flags} {event_file}")
                    if TRANSCODED in event_dir.split(os.path.sep):
                        continue
                    if event_file.endswith(MEDIA):
                        work_pending = True
            if work_pending:
                dirtranscode(
                    self.media_dir,
                    recurse=True,
                    nvidia_detected=self.nvidia_detected
                )
            if process.poll() is not None:
                raise RuntimeError("inotifywait process exited")


def main(argv=sys.argv):
    parser = argparse.ArgumentParser(
        description="Watch a directory and subdirectory for media file changes."
    )
    parser.add_argument(
        "media_dir",
        help="Media directory"
    )
    args = parser.parse_args()
    nvidia_detected = detect_nvidia()
    media_dir = os.path.expanduser(os.path.abspath(args.media_dir))
    monitor = Monitor(media_dir, nvidia_detected)
    monitor.runforever()

if __name__ == '__main__':
    main(sys.argv)
