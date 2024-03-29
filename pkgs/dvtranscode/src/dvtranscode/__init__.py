import logging

__version__ = "0.0"

MEDIA = (".mp4", ".mkv", ".MP4", ".MKV", ".webm", ".WEBM")
TRANSCODED = "transcoded"

class Logger:
    def __init__(self, subsystem):
        self.subsystem = subsystem

    def format(self, message):
        return f"{self.subsystem}: {message}"

    def info(self, message):
        logging.info(self.format(message))

    def error(self, message):
        logging.error(self.format(message))

    def warning(self, message):
        logging.warning(self.format(message))

    def exception(self, message):
        logging.exception(self.format(message))
