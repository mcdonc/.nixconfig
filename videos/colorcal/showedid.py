import pyedid
import subprocess

def hyphen_separate(s, default=''):
    if s is None:
        return default
    return '-'.join(s.split())

def get_monids(edids):
    for edid in edids:
        e = pyedid.parse_edid(edid)
        manufacturer = hyphen_separate(e.manufacturer, 'nomanufacturer')
        name = hyphen_separate(e.name, 'noname')
        serial = e.serial or 'noserial'
        year = e.year or 'noyear'
        week = e.week or 'noweek'
        monid = f"{manufacturer}-{name}-{year}-{week}-{serial}"
        yield monid

def show_monids(edids):
    for n, monid in enumerate(get_monids(edids)):
        print(f"{n} {monid}")

if __name__ == '__main__':
    randr = subprocess.check_output(['xrandr', '--verbose'])
    edids = pyedid.get_edid_from_xrandr_verbose(randr)
    print(pyedid.parse_edid(edids[0]))
    show_monids(edids)
