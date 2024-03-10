import argparse
import csv
import io
import multiprocessing
import logging
import os
import select
import subprocess
import sys
import time

WORK_PENDING = multiprocessing.Event()

from . import (
    TRANSCODED,
    MEDIA
    )

from . import Logger
from .dirtranscode import dirtranscode
from .transcode import detect_nvidia

class Pending:
    def __init__(self, quiet_period):
        self.quiet_period = quiet_period
        self.paths = []
        self.last = None

    def append(self, path):
        self.paths.append(path)
        self.last = time.time()

    def force(self):
        if not self.paths:
            self.paths.append("")
        self.last = None

    def get(self):
        now = time.time()
        if self.last is None or (now - self.last > self.quiet_period):
            self.last = None
            paths = self.paths
            self.paths = []
            return paths
        return []

class Monitor:
    def __init__(self, media_dir, logger, nvidia_detected=False):
        self.media_dir = media_dir
        self.logger = logger
        self.nvidia_detected = nvidia_detected
        self.command = [
            "inotifywait",
            "-c", # CSV
            "-mr",
            "-e"
            "close_write",
            "-e"
            "moved_to",
#            "-e"
#            "moved_from",
#            "-e",
#            "delete",
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
            self.logger.info(f"starting {' '.join(self.command)}")
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

    def poll(self, process, poller, timeout=30, quiet_period=10):
        # Monitor the program's output for additions and changes to media
        # files
        # depth-first.. http://jeremy.zawodny.com/blog/archives/010037.html
        pending = Pending(quiet_period)
        while True:
            events = poller.poll(timeout * 1000)
            for fd, event in events:
                if event & select.POLLIN:
                    new_data = process.stdout.readline()
                    event_dir, flags, event_file = self.parse_csv_line(new_data)
                    if TRANSCODED in event_dir.split(os.path.sep):
                        continue
                    if event_file.endswith(MEDIA):
                        self.logger.info(f"{event_dir} {flags} {event_file}")
                        event_file = os.path.join(event_dir, event_file)
                        pending.append(event_file)

            if not events: # at least every timeout seconds
                pending.force()

            work = pending.get()

            if work:
                if work == [""]:
                    self.logger.info("forced transcoding due to timeout")
                    work = []
                else:
                    self.logger.info(f"transcoding due to events: {work}")
                dirtranscode(
                    self.media_dir,
                    self.logger,
                    recurse=True,
                    verbose=True,
                    nvidia_detected=self.nvidia_detected,
                    overrides=work,
                )
            if process.poll() is not None:
                raise RuntimeError("inotifywait process exited")


def main(argv=sys.argv):
    logging.basicConfig(
        level=logging.INFO,
        format='%(message)s',
    )
    logger = Logger("watchmedia")
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
    monitor = Monitor(media_dir, logger, nvidia_detected)
    monitor.runforever()

if __name__ == '__main__':
    main(sys.argv)
