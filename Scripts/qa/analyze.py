#!/usr/bin/env python3
"""analyze.py <tag>: error and fault lines per screen from $QA_OUT/logs/sweep/<tag>-*.log, noise filtered.
Lines seen on 3+ screens are ambient; app NSLog warnings are listed separately; the rest is per screen."""
import sys, re, glob, os, collections
tag = sys.argv[1]
SCR = os.environ["QA_OUT"]
files = sorted(glob.glob(f"{SCR}/logs/sweep/{tag}-*.log"))
# compact style: "2026-09-28 16:27:03.146 E  iPhone[pid:tid] [subsystem:category] message"
line_re = re.compile(r'^\S+ \S+ (\w+)\s+iPhone\[\d+:\w+\] (?:\[([^\]]*)\] )?(.*)$')
SIGNAL = re.compile(r'runtime issue|Modifying state during view update|tried to update multiple times per frame|'
                    r'Publishing changes from (background|within view updates)|NSRangeException|NSInternalInconsistency|'
                    r'Fatal error|Unexpectedly found nil|precondition|AttributeGraph: cycle|Bound preference|'
                    r'onChange\(of: .*\) action tried to update|invalid (frame|sample|value)|NaN|'
                    r'Unable to simultaneously satisfy|Invalid .* dimension|UICollectionView.*(invalid|inconsistent)|'
                    r'Accessing StateObject|Accessing State\'s value outside|FAILED|failed|error', re.I)
NOISE = re.compile(r'BackgroundTask|BGTaskScheduler|wcd|WCSession|coreaudio|CFBundle|TextKit 1|FigFilePlayer|'
                   r'NavigationRequestObserver|OnScrollGeometryChange|kCLErrorDomain|modelmanager|ModelManager|'
                   r'SensitiveContent|RTIInputSystemClient|UIKeyboard|LoadedFontManager|sandbox|nw_|tcp_|'
                   r'SensorKit|BackBoardServices|BoardServices|PointerUI|[Ss]iri|assistant|AudioSession|HALC|'
                   r'com\.apple\.Metal|ViewServiceBridge|LaunchServices|RBSAssert|dyld|MPRemoteCommand|SecTask|'
                   r'CTTelephony|carrier|xctest|DataDeliveryServices|MobileAsset|CoreAnalytics|AppleTypeCString|'
                   r'Received port for identifier|mediaremote|RemoteControl|CFNetwork|BackgroundSession|'
                   r'LinguisticData|com\.apple\.runningboard|TCC|AXRuntime|accessibility|com\.apple\.xpc|'
                   r'CoreData|cloudkit|CloudKit|ubiquity|FrontBoard|UIScene|SpringBoard|BiomeLibrary|'
                   r'com\.apple\.defaults|cfprefsd|IOSurface|CAMetalLayer|PlugInKit|pkd|chronod|WidgetKit|'
                   r'SwiftUI.*Toolbar|IconServices|NLEmbedding|GenerativeModels|FoundationModels|TextComposer|'
                   r'com\.apple\.photos|Photos|Location|locationd|CoreLocation|geocod', re.I)
per_screen = {}
global_counts = collections.Counter()
app_logs = collections.defaultdict(collections.Counter)   # app NSLog lines, "(Foundation) ..."
APP_WARN = re.compile(r'APPEARANCE ENV|WARN|ERROR|FAIL|MISSING|STALE|LOOP|INVALID|UNEXPECTED|mismatch|not found|could not|couldn\'t|refused|dropped', re.I)
for f in files:
    name = os.path.basename(f)[len(tag)+1:-4]
    hits = collections.Counter()
    for raw in open(f, errors='replace'):
        m = line_re.match(raw.rstrip('\n'))
        if not m: continue
        level, subsys, msg = m.group(1), m.group(2) or '', m.group(3)
        text = f"[{subsys}] {msg}"
        if msg.startswith('(Foundation)'):
            if APP_WARN.search(msg):
                k = re.sub(r'0x[0-9a-f]+', '0x…', msg[13:]); k = re.sub(r'\d{3,}', '#', k)[:200]
                app_logs[k][name] += 1
            continue
        if NOISE.search(text): continue
        if level in ('E', 'F') or SIGNAL.search(msg):
            key = re.sub(r'0x[0-9a-f]+', '0x…', text)
            key = re.sub(r'\d{3,}', '#', key)[:260]
            hits[(level, key)] += 1
    per_screen[name] = hits
    for k in hits: global_counts[k] += 1
print(f"{len(files)} screen logs")
print("\n=== lines seen on 3+ screens (likely ambient)")
for (lvl, k), n in global_counts.most_common():
    if n >= 3: print(f"  {n:3d} screens  {lvl}  {k}")
print("\n=== app NSLog warnings (message -> screens)")
for k, scr in sorted(app_logs.items(), key=lambda kv: -len(kv[1])):
    print(f"  {len(scr):3d} screens  {k}")
    print(f"             e.g. {', '.join(list(scr)[:6])}")
print("\n=== per-screen lines seen on fewer than 3 screens")
for name, hits in per_screen.items():
    rare = [(lvl, k, c) for (lvl, k), c in hits.items() if global_counts[(lvl, k)] < 3]
    if rare:
        print(f"-- {name}")
        for lvl, k, c in sorted(rare, key=lambda x: -x[2])[:12]:
            print(f"    {c:3d}x {lvl}  {k}")
