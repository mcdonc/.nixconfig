#!/usr/bin/env python3
import requests
from requests.auth import HTTPBasicAuth
import os
import sys

# curl -i -u "$MODEMSECRET" http://192.168.100.1/DocsisStatus.htm
# grep for Set-Cookie: XSRF_TOKEN=30060125; Path=/
# curl -u $MODEMSCECRET -b XSRF_TOKEN=$XSRF_TOKEN http://192.168.100.1/DocsisStatus.htm

username, password = os.environ["MODEMSECRET"].split(':', 1)

resp = requests.get(
    "http://192.168.100.1/DocsisStatus.htm",
    auth=HTTPBasicAuth(username, password=password)
)
xsrf= resp.headers['Set-Cookie'].split(";", 1)[0]

name, val = xsrf.split("=", 1)
cookies = {name: val}
body = requests.get(
    "http://192.168.100.1/DocsisStatus.htm",
    auth=HTTPBasicAuth(username, password=password),
    cookies=cookies,
)

result = [ -1, -1 ]

# grep for "var tagValueList =" (downstream)
# grep inside of that for 255000000
# split that line on "|"
for line in body.text.split('\n'):
    if "var tagValueList =" in line:
        if "255000000" in line:
            result = line.split('|')
            break


# drop the first element (it will be 32)
# drop the last element (it will be ";")
# groups of 9 represent rows
# 2nd element of each row represents locked
result = result[1:-1]
rows = [result[i:i+9] for i in range(0, len(result), 9)]
if rows:
    locked = sum(1 for row in rows if row[1] == "Locked")
else:
    locked = "U"
sys.stdout.write(str(locked))
sys.stdout.flush()

#result = ["var tagValueList = '32", '1', 'Not Locked', 'Unknown', '5', '117000000 Hz', '0.0', '0.0', '0', '0', '2', 'Locked', 'QAM256', '1', '723000000 Hz', '3', '45.3', '0', '0', '3', 'Locked', 'QAM256', '2', '729000000 Hz', '3.1', '45.2', '0', '0', '4', 'Locked', 'QAM256', '3', '735000000 Hz', '3.4', '45.1', '0', '0', '5', 'Locked', 'QAM256', '4', '741000000 Hz', '3.2', '44.5', '0', '0', '6', 'Locked', 'QAM256', '6', '753000000 Hz', '3.3', '44.9', '0', '0', '7', 'Locked', 'QAM256', '7', '759000000 Hz', '3.4', '44.3', '0', '0', '8', 'Locked', 'QAM256', '8', '765000000 Hz', '3.3', '44.5', '0', '0', '9', 'Not Locked', 'Unknown', '0', '0 Hz', '0.0', '0.0', '0', '0', '10', 'Not Locked', 'Unknown', '26', '123000000 Hz', '0.0', '0.0', '0', '0', '11', 'Not Locked', 'Unknown', '27', '129000000 Hz', '0.0', '0.0', '0', '0', '12', 'Not Locked', 'Unknown', '28', '135000000 Hz', '0.0', '0.0', '0', '0', '13', 'Not Locked', 'Unknown', '29', '141000000 Hz', '0.0', '0.0', '0', '0', '14', 'Not Locked', 'Unknown', '30', '147000000 Hz', '0.0', '0.0', '0', '0', '15', 'Not Locked', 'Unknown', '31', '153000000 Hz', '0.0', '0.0', '0', '0', '16', 'Not Locked', 'Unknown', '32', '159000000 Hz', '0.0', '0.0', '0', '0', '17', 'Not Locked', 'Unknown', '33', '165000000 Hz', '0.0', '0.0', '0', '0', '18', 'Not Locked', 'Unknown', '34', '171000000 Hz', '0.0', '0.0', '0', '0', '19', 'Not Locked', 'Unknown', '35', '177000000 Hz', '0.0', '0.0', '0', '0', '20', 'Not Locked', 'Unknown', '36', '183000000 Hz', '0.0', '0.0', '0', '0', '21', 'Not Locked', 'Unknown', '37', '189000000 Hz', '0.0', '0.0', '0', '0', '22', 'Not Locked', 'Unknown', '38', '195000000 Hz', '0.0', '0.0', '0', '0', '23', 'Not Locked', 'Unknown', '39', '201000000 Hz', '0.0', '0.0', '0', '0', '24', 'Not Locked', 'Unknown', '40', '207000000 Hz', '0.0', '0.0', '0', '0', '25', 'Not Locked', 'Unknown', '41', '213000000 Hz', '0.0', '0.0', '0', '0', '26', 'Not Locked', 'Unknown', '42', '219000000 Hz', '0.0', '0.0', '0', '0', '27', 'Not Locked', 'Unknown', '43', '225000000 Hz', '0.0', '0.0', '0', '0', '28', 'Not Locked', 'Unknown', '44', '231000000 Hz', '0.0', '0.0', '0', '0', '29', 'Not Locked', 'Unknown', '45', '237000000 Hz', '0.0', '0.0', '0', '0', '30', 'Not Locked', 'Unknown', '46', '243000000 Hz', '0.0', '0.0', '0', '0', '31', 'Not Locked', 'Unknown', '47', '249000000 Hz', '0.0', '0.0', '0', '0', '32', 'Not Locked', 'Unknown', '48', '255000000 Hz', '0.0', '0.0', '0', '0', "';"]
