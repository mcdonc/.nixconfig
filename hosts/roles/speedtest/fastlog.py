#!/usr/bin/env python3
import sys
import json
from datetime import datetime
import subprocess
from json.decoder import JSONDecodeError

keymap = {
    "bloat":"bufferBloat",
    "speed":"downloadSpeed",
    "dled":"downloaded",
    "ltcy":"latency",
    "timestamp":"timestamp",
    "channels":"channels",
    }

order = [ "timestamp", "speed", "ltcy", "dled", "bloat", "channels" ]
default_fname = "/var/log/fast.csv"

if __name__== "__main__":
    proc = subprocess.run(["fast", "--json"], capture_output=True)
    numchannels = subprocess.run(
        ["numchannels"], capture_output=True, text=True
    ).stdout
    print(f"numchannels: {numchannels}") 
    if proc.returncode != 0:
        sys.exit(proc.returncode)
    j = proc.stdout
    try:
        fname = sys.argv[1]
    except IndexError:
        fname = default_fname
    f = open(fname, "a+")
    if f.tell() == 0:
        header = "\t".join(order)
        print(header)
        f.write(header + "\n")
    timestamp  = datetime.now().strftime("%d/%m/%y %H:%M")
    try:
        data = json.loads(j)
    except JSONDecodeError:
        oneline = j.strip('\n').strip('\r')
        for k in keymap.values():
            data[k] = ""
        data["downloadSpeed"] = f"ERROR: {oneline}"
    data["timestamp"] = timestamp
    data["channels"] = numchannels
    dataline = "\t".join([str(data[keymap[k]]) for k in order ])
    print(dataline)
    f.write(dataline + "\n")
