#!/usr/bin/env python3
"""ipsmatch.py <mac|UDID> <since-epoch> : prints the iPhone-*.ips reports newer than the epoch that belong to
the Mac app (platform macOS, translocated /Volumes/VOLUME path) or to the simulator with that UDID."""
import sys, os, glob, json
who, since = sys.argv[1], float(sys.argv[2])
for p in sorted(glob.glob(os.path.expanduser('~/Library/Logs/DiagnosticReports/iPhone-*.ips'))):
    if os.path.getmtime(p) < since: continue
    try:
        with open(p, encoding='utf-8', errors='replace') as f:
            f.readline(); body = json.loads(f.read())
    except Exception:
        continue
    path = body.get('procPath', '')
    # A simulator report carries the HOST's macOS version, so only the path tells them apart.
    is_mac = 'CoreSimulator' not in path and ('/Volumes/VOLUME' in path or 'Wrapper/iPhone.app' in path or '/Applications/' in path)
    if (who == 'mac' and is_mac) or (who != 'mac' and who in path):
        print(os.path.basename(p))
