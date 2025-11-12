#!/usr/bin/env python3
import csv
import os

if __name__ == '__main__':
    outdir = '/var/www/speedtest'
    os.makedirs(outdir, exist_ok=True)
    infile = open('/var/log/fast.csv', newline='')
    outfile = open(os.path.join(outdir, 'index.html'), 'w')
    inlist = []
    outlist = []
    max = 180
    order = [
        'Timestamp',
        'Speed (Mbps)',
        'Latency (ms)',
        'Downloaded',
        'Bloat',
        'Channels',
    ]
    reader = csv.reader(infile, delimiter='\t')
    reader.__next__() # header
    for row in reader:
        if len(inlist) >= max:
            inlist.pop(0)
        inlist.append(row)
    inlist.reverse()

    outlist.append('<html>')
    outlist.append('<head>')
    outlist.append('<style>')
    outlist.append("""table {
    table-layout: fixed;
    width: 100%;
    border-collapse: collapse;
    }
    tbody td {
    text-align: center;
    }
    h1 {
    text-align: center;
    }
    tr:nth-child(even) {
    background-color: #f2f2f2;
    }
    """)
    outlist.append('</style>')
    outlist.append('<body>')
    outlist.append('<h1>Internet Speed Over Time</h1>')
    outlist.append('<table>')
    outlist.append('<tr>')
    for thing in order:
        outlist.append(f'<th>{thing}</th>')
    outlist.append('</tr>')
    for line in inlist:
        outlist.append('<tr>')
        for thing in line:
            outlist.append(f'<td>{thing}</td>')
        outlist.append('</tr>')
    outlist.append('</table>')
    outlist.append('</body>')
    outlist.append('</html>')
    outfile.writelines(outlist)
