import argparse
import csv
import io
import logging
import os
import select
import subprocess
import sys
import time

from . import (
    TRANSCODED,
    MEDIA
    )

from . import Logger
from .dirtranscode import dirtranscode
from .transcode import detect_nvidia

class Monitor:
    def __init__(
            self,
            media_dir,
            logger,
            onstart=True,
            quiet_period=10,
            software=False,
            nvidia_detected=False
    ):
        self.media_dir = media_dir
        self.logger = logger
        self.onstart = onstart
        self.quiet_period = quiet_period
        self.software = software
        self.nvidia_detected = nvidia_detected
        self.work = []
        self.last_append = 0
        self.forced = False
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
        self.logger.info(
            f"Running monitor with onstart {self.onstart} and quiet_period "
            f"{self.quiet_period}.  nvidia: {self.nvidia_detected} "
            f"software: {self.software} media_dir: {self.media_dir}"
            )
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

    def poll(self, process, poller):
        # Monitor the program's output for additions and changes to media
        # files
        # depth-first.. http://jeremy.zawodny.com/blog/archives/010037.html
        if self.onstart:
            self.logger.info("forcing dirtranscode due to onstart")
            self.append("")

        while True:
            events = poller.poll(1000) # every second
            for fd, event in events:
                if event & select.POLLIN:
                    new_data = process.stdout.readline()
                    event_dir, flags, event_file = self.parse_csv_line(new_data)
                    if TRANSCODED in event_dir.split(os.path.sep):
                        continue
                    if event_file.endswith(MEDIA):
                        self.logger.info(f"{flags} {event_dir}{event_file}")
                        event_file = os.path.join(event_dir, event_file)
                        self.append(event_file)

            self.flush()

            if process.poll() is not None:
                raise RuntimeError("inotifywait process exited")

    def append(self, path):
        self.work.append(path)
        self.last_append = time.time()

    def flush(self):
        now = time.time()
        if self.work and (now - self.last_append > self.quiet_period):
            work = self.work
            self.work = []
            self.dirtranscode(work)

    def dirtranscode(self, work):
        self.logger.info(f"dirtranscode started due for events: {work}")
        dirtranscode(
            self.media_dir,
            self.logger,
            software=self.software,
            recurse=True,
            verbose=True,
            nvidia_detected=self.nvidia_detected,
            overrides=work,
        )
        self.logger.info(f"dirtranscode completed for events: {work}")


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
    parser.add_argument(
        "--software",
        "-s",
        action="store_true",
        help="Use software rendering instead of hardware",
    )
    parser.add_argument(
        "--onstart",
        "-o",
        action="store_false",
        default=True,
        help="Run the transcoder at startup",
    )
    parser.add_argument(
        "--quiet-period",
        "-q",
        type=int,
        default=10,
        help="Do nothing until inotify has been quiet this number of seconds",
    )
    args = parser.parse_args()
    nvidia_detected = detect_nvidia()
    media_dir = os.path.expanduser(os.path.abspath(args.media_dir))
    monitor = Monitor(
        media_dir,
        logger,
        onstart=args.onstart,
        quiet_period=args.quiet_period,
        software=args.software,
        nvidia_detected=nvidia_detected,
        )
    monitor.runforever()

if __name__ == '__main__':
    main(sys.argv)
