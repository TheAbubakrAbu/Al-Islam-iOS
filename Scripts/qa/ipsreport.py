#!/usr/bin/env python3
"""ipsreport.py [report.ips ...]: a crash report in a few readable lines: where it ran (the Mac app or a
simulator, by path; a simulator report carries the HOST's macOS version), version and build, the exception,
the runtime message (a Swift "Fatal error", an abort reason), the crashing thread's frames with symbols, the
last exception backtrace, and whether a StressWalker frame is on any stack (the walk drove that step: judge
the ACTION, see Docs/Engineering/Mac Crash Sweep Guide.md). With no argument: the newest iPhone-*.ips report."""
import glob, json, os, sys

paths = sys.argv[1:] or sorted(glob.glob(os.path.expanduser('~/Library/Logs/DiagnosticReports/iPhone-*.ips')),
                               key=os.path.getmtime)[-1:]
for p in paths:
    try:
        with open(p, encoding='utf-8', errors='replace') as f:
            f.readline(); body = json.loads(f.read())
    except Exception as e:
        print('PARSE FAILED', p, e); continue
    images = body.get('usedImages', [])

    def frame(fr):
        i = fr.get('imageIndex', -1)
        img = images[i] if 0 <= i < len(images) else {}
        s = f"{img.get('name', '?')}:{fr['symbol']}" if fr.get('symbol') else f"{img.get('name', '?')}+{fr.get('imageOffset', 0)}"
        if fr.get('sourceFile'):
            s += f" ({fr['sourceFile']}:{fr.get('sourceLine', '')})"
        return s

    info = body.get('bundleInfo', {}); exc = body.get('exception', {}); term = body.get('termination', {})
    path = body.get('procPath', '')
    where = 'SIMULATOR' if 'CoreSimulator' in path else 'MAC APP' if ('/Volumes/VOLUME' in path or 'Wrapper/iPhone.app' in path) else 'other'
    print('=' * 100)
    print(f"{os.path.basename(p)}  {where}  v{info.get('CFBundleShortVersionString')} build {info.get('CFBundleVersion')}  "
          f"{exc.get('type')}/{exc.get('signal')}  {str(exc.get('subtype', ''))[:120]}")
    print(f"  path: {path}")
    print(f"  launched {body.get('procLaunch', '')}  captured {body.get('captureTime', '')}")
    if term.get('indicator'):
        print(f"  termination: {term.get('indicator')}")
    if body.get('asi'):
        print(f"  message: {json.dumps(body['asi'])[:600]}")
    threads = body.get('threads', []); ft = body.get('faultingThread', 0)
    frames = threads[ft].get('frames', []) if ft < len(threads) else []
    print(f"  crashing thread {ft}{' (main)' if ft == 0 else ''}:")
    for fr in frames[:16]:
        print('    ' + frame(fr))
    leb = body.get('lastExceptionBacktrace')
    if leb:
        print('  last exception backtrace:')
        for fr in leb[:12]:
            print('    ' + frame(fr))
    walker = 'StressWalker' in json.dumps(body)
    print(f"  StressWalker on a stack: {'YES (the walk drove this step; judge the action)' if walker else 'no'}")
