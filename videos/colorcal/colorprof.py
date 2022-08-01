#!/usr/bin/env python

import subprocess
import os.path
import shutil

EDID_NAME_TAGS = [
    bytearray.fromhex('000000fc00'),
    bytearray.fromhex('000000fe00')
]

def serial_from_edid(edid):
    import pdb; pdb.set_trace()
    serial = edid[12:16].decode('utf-8')
    return serial

def name_from_edid(edid):
  """
  Parse a byte array edid blob to extract some sort of human-readable name.

  For more info, see:
  http://read.pudn.com/downloads110/ebook/456020/E-EDID%20Standard.pdf
  """
  names = []
  for i in range(0, 6):
    offset = 36 + i * 18
    tag = edid[offset : offset + 5]
    val = edid[offset + 5 : offset + 18]
    if tag in EDID_NAME_TAGS:
      names += [val.decode('utf-8').strip()]
  return '-'.join(names)

def get_xrandr_monitors():
  """
  Gets the mapping from xrandr to actual monitor names.::

    eDP1 => 'LG Display'

  """
  xrandr_out = subprocess.check_output(['xrandr', '--verbose']).decode('utf-8')

  names = dict()
  serials = dict()
  monitor = None
  in_edid = False
  edid = b''
  for line in xrandr_out.splitlines():
    line = line.strip()
    words = line.split()
    if len(words) > 1 and words[1] == 'connected':
      monitor = words[0]
    elif line == 'EDID:':
      in_edid = True
    elif in_edid and len(line) == 32:
      edid += bytearray.fromhex(line)
    else:
      if in_edid:
        names[monitor] = name_from_edid(edid)
        serials[monitor] = serial_from_edid(edid)
      in_edid = False
      edid = b''

  return {'names':names, 'serials':serials}

def get_dispwin_mapping():
  """
  Gets the mapping that dispwin uses for the outputs.::

    eDP1 => 1

  """
  dispwin_proc = subprocess.run(['dispwin', '--help'],
      stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  dispwin_out = dispwin_proc.stdout.decode('utf-8')
  dispwin_mapping = dict()
  for line in dispwin_out.splitlines():
    # E.g.: 1 = 'Screen 1, Output eDP1 at 0, 0, width 2560, height 1440'
    words = line.split()
    if words[1] == '=' and words[4] == 'Output':
      num = words[0]
      name = words[5]
      dispwin_mapping[name] = num
  return dispwin_mapping

def icc_file_for_monitor_name(name, serial):
  name = name.replace(' ', '-')
  return os.path.expanduser('~/.color/icc/{}-{}.icc'.format(name, serial))

def assert_executable(executable):
  if not shutil.which(executable):
    raise Exception('Executable not available on system: ' + executable)

if __name__ == '__main__':
  assert_executable('xrandr')
  assert_executable('dispwin')

  monitors = get_xrandr_monitors()
  xrandr_monitor_names = monitors['names']
  xrandr_monitor_serials = monitors['serials']
  dispwin_mapping = get_dispwin_mapping()
  for monitor in xrandr_monitor_names:
    monitor_name = xrandr_monitor_names[monitor]
    if monitor in dispwin_mapping:
      dispwin_num = dispwin_mapping[monitor]
      serial = xrandr_monitor_serials[monitor]
      icc_file = icc_file_for_monitor_name(monitor_name, serial)
      print('[{}] checking: {}'.format(monitor, icc_file))
      if os.path.isfile(icc_file):
        cmd = ['dispwin', '-d', dispwin_num, icc_file]
        print('[{}] running: {}'.format(monitor, ' '.join(cmd)))
        subprocess.check_output(cmd)
      else:
        print('[{}] no icm file'.format(monitor))
