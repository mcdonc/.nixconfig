import pprint
import pyedid
import subprocess

# getting `xrandr --verbose` output
randr = subprocess.check_output(['xrandr', '--verbose'])

# parsing xrandr outputs to a bytes edid's list
edids = pyedid.get_edid_from_xrandr_verbose(randr)

# parsing edid
edid = pyedid.parse_edid(edids[0])

pprint.pprint(edid)
