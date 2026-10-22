#!/usr/bin/env python3
"""Which slice each view needs (Performance Guide, section 18, Stage 3), and what is still wrong.

For every Swift file under iPhone/ and Apple Watch/ this prints, per file:
  - the `@ObservedObject var settings = Settings.shared` structs it still has (the migration backlog),
  - the slices it observes,
  - every `settings.x` / `Settings.shared.x` read, resolved to the slice that owns `x`: a stored field
    by the key table (Scripts/qa/settings_slices.json), a computed property or method by the stored
    fields ITS body reads (one level, over Settings.swift / SettingsQuran.swift / SettingsAdhan.swift),
  - a STALE line for a field read through an observed slice's forwarder that the slice does not own
    (the compiler already stops `quran.showDuha`; this catches the `Settings.shared.showDuha` escape
    in a body that observes only `QuranDisplay`).

    python3 Scripts/qa/settings_observers.py            # the full report
    python3 Scripts/qa/settings_observers.py --backlog  # files still observing Settings, with counts
    python3 Scripts/qa/settings_observers.py --stale    # exit 1 when a migrated file reads outside its slices
"""
import json, os, re, sys, collections

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def model_files():
    """Settings.swift, its two extension files, and every other file that extends `Settings`."""
    found = []
    for top in ('iPhone', 'Apple Watch'):
        for dp, _, fs in os.walk(os.path.join(ROOT, top)):
            for f in fs:
                if not f.endswith('.swift'): continue
                path = os.path.join(dp, f)
                text = open(path, encoding='utf-8', errors='ignore').read()
                if 'final class Settings' in text or re.search(r'^(?:private |fileprivate )?extension Settings\b', text, re.M):
                    found.append(path)
    return sorted(found)


MODEL = model_files()
# Members whose bodies say nothing about their inputs: a per-screen defaults key (`advanced`) that
# `setAdvanced` routes under `advancedSettings`, and pure formatters.
MANUAL = {
    'advanced': {'SystemSettings'}, 'anyAdvancedSettings': {'SystemSettings'}, 'advancedBinding': {'SystemSettings'},
    # Write counters bumped by the content setters, read instead of hashing the blobs.
    'trackerGeneration': {'PrayerTracker'},
    'contentGeneration': {'PrayerTracker', 'QuranContent', 'IslamSettings', 'HadithSettings'},
    'trackerStats': {'PrayerTracker'},
    'profileStatsStamp': {'PrayerTracker', 'QuranContent', 'IslamSettings', 'HadithSettings'},
    # Keyed caches and per-prayer lookups by name, whose bodies name no field.
    'isIslamResourceFavorite': {'IslamSettings'}, 'toggleIslamResourceFavorite': {'IslamSettings'},
    'notificationMode': {'AdhanSettings'}, 'setNotificationMode': {'AdhanSettings'}, 'cycleNotificationMode': {'AdhanSettings'},
    'ownsTravelingModeAutoCheck': {'AdhanSettings'}, 'ownsAutomaticCalculationCheck': {'AdhanSettings'},
    'alertToneSoundFilename': {'AdhanSettings'}, 'adhanFullSoundResource': {'AdhanSettings'},
    'recommendedCalculationMethod': {'AdhanSettings', 'LiveState'}, 'canonicalPrayerCalculationMethod': set(),
    'lastRead': {'ReadingState'}, 'recordLastRead': {'ReadingState'},
    # Pure folds and formatters: no slice.
    'cleanSearch': set(), 'cleanSearchKeepingHamza': set(), 'cleanSearchIgnoringSilentArabicLetters': set(),
    'foldedTransliterationForSearch': set(), 'formatDate': set(), 'hijriCalendar': set(), 'canMarkPrayer': set(),
    'objectWillChange': set(),
    # The daily key turns on the rollover switch (the Fajr boundary itself is a DailyRollover event).
    'dailyDayKey': {'SystemSettings'}, 'dailyDayIndex': {'SystemSettings'}, 'nextDailyRollover': {'SystemSettings'},
    # Counts served from the khatm and revision caches (loaded from their Data fields).
    'khatmCompletedAyahCount': {'QuranContent'}, 'revisionRevisedCount': {'QuranContent'},
    # Actions a view calls from a closure; nothing it draws comes from them.
    'refreshQuranWidgets': set(), 'reloadWidgets': set(), 'scheduleNotifications': set(),
    'fetchPrayerTimes': set(), 'fetchPrayerTimesDebounced': set(), 'requestNotificationAuthorization': set(),
    'requestLocationAuthorization': set(), 'requestLocationIfUndetermined': set(), 'refreshLocationIfStale': set(),
    'resetAllSettings': set(), 'overrideAutomaticCalculationKeepingPrevious': set(), 'overrideTravelingMode': set(),
    'confirmAutomaticCalculationChange': set(), 'confirmTravelAutomaticChange': set(), 'resetTravelAutomaticFlags': set(),
    'setTravelingModeManually': set(), 'snoozePermissionAlert': set(), 'markRevisionAyahRevised': set(),
    'beginLocationRefinementForCompass': set(), 'endLocationRefinement': set(), 'updateCurrentAndNextPrayer': set(),
    'updateDates': set(), 'recordTrackerMark': set(), 'setTrackerExempt': set(),
}
SLICES = json.load(open(os.path.join(ROOT, 'Scripts/qa/settings_slices.json')))
FIELD_SLICE = {}
for slice_name, info in SLICES.items():
    for f in info['fields']: FIELD_SLICE[f] = slice_name
    for k in info['keys']: FIELD_SLICE.setdefault(k, slice_name)
# Live state that is not Settings' to publish: a body reading these must observe LiveState / ReadingState.
LIVE = {'currentPrayer': 'LiveState', 'nextPrayer': 'LiveState', 'prayers': 'LiveState', 'prayersData': 'LiveState',
        'currentLocation': 'LiveState', 'lastReadSurah': 'ReadingState', 'lastReadAyah': 'ReadingState',
        'lastReadTimestamp': 'ReadingState'}

OBS_SETTINGS = re.compile(r'@ObservedObject (?:private )?var settings = Settings\.shared')
OBS_SLICE = re.compile(r'@ObservedObject (?:private )?var (\w+) = (%s)\.shared' % '|'.join(SLICES))
READ = re.compile(r'\b(?:settings|Settings\.shared)\.([A-Za-z_][A-Za-z0-9_]*)')
SLICE_READ = re.compile(r'\b(%s)\.shared\.([A-Za-z_][A-Za-z0-9_]*)' % '|'.join(SLICES))


def member_bodies():
    """name -> set of stored fields its body reads, for every func / computed var in the model files."""
    bodies = {}
    # Members sit at four spaces inside `final class Settings {` / `extension Settings {`; anchoring
    # there keeps a `let` inside a function body from being read as a member of its own.
    head = re.compile(r'^ {4}(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|internal|private|fileprivate|static|final|override|nonisolated|@MainActor)\s+)*'
                      r'(?:func|var|let)\s+([A-Za-z_][A-Za-z0-9_]*)')
    top = re.compile(r'^(?:private |fileprivate |public |final )*(class|struct|enum|extension|protocol|actor)\s+(\w+)')
    for path in MODEL:
        lines = open(path, encoding='utf-8', errors='ignore').read().split('\n')
        i = 0; inside_settings = False
        while i < len(lines):
            t = top.match(lines[i])
            if t:
                # Only members of `Settings` itself (the class and its extensions), never of another
                # type that shares the file (`current`, `compute` and other everyday names elsewhere).
                inside_settings = t.group(2) == 'Settings'
            m = head.match(lines[i]) if inside_settings else None
            if not m:
                i += 1; continue
            name = m.group(1)
            # A body starts at the first `{` before the NEXT member declaration; a stored property
            # followed by a member with a body has none (it used to swallow that next member).
            k = i; has_body = False
            while k < len(lines):
                if k > i and head.match(lines[k]): break
                if '{' in lines[k]: has_body = True; break
                k += 1
            if not has_body:
                i += 1; continue
            depth = 0; started = False; body = []
            j = i
            while j < len(lines):
                body.append(lines[j])
                depth += lines[j].count('{') - lines[j].count('}')
                if '{' in lines[j]: started = True
                if started and depth <= 0: break
                j += 1
            text = '\n'.join(body)
            # Every identifier: stored fields resolve directly, other members resolve through their own
            # bodies (`isHafsDisplay` reads `displayQiraahForArabic`, which reads `displayQiraah`).
            bodies.setdefault(name, set()).update(re.findall(r'\b([A-Za-z_][A-Za-z0-9_]*)\b', text))
            is_func = re.search(r'\bfunc\s+' + re.escape(name), lines[i]) is not None
            # A function that answers something (`-> T`) is part of what its caller reads; one that
            # returns nothing is a side effect (a widget refresh, a nag answer) whose reads are not.
            signature = '\n'.join(lines[i:k + 1])
            KIND[name] = 'func' if is_func and '->' not in signature else 'var'
            i = j + 1
    return bodies


KIND = {}
BODIES = member_bodies()


def resolve(member, depth=0, seen=None):
    """The slices a member read needs: a stored field's owner, or the owners of what a member reads."""
    if member in LIVE: return {LIVE[member]}
    if member in FIELD_SLICE: return {FIELD_SLICE[member]}
    if member in MANUAL: return set(MANUAL[member])
    if depth >= 4 or member not in BODIES: return set()
    seen = seen or set()
    needs = set()
    for ident in BODIES[member]:
        if ident == member or ident in seen: continue
        if ident in FIELD_SLICE or ident in LIVE or ident in MANUAL:
            needs |= resolve(ident, depth + 1, seen | {member})
        elif ident in BODIES and KIND.get(ident) == 'var':
            # A computed property is part of what the member answers; a function it CALLS is a side
            # effect (a widget refresh, a nag answer) whose reads are not the caller's inputs.
            needs |= resolve(ident, depth + 1, seen | {member})
    return needs


STRUCT = re.compile(r'^(\s*)(?:(?:private|fileprivate|public|internal)\s+)?struct\s+(\w+)\s*(?:<[^>]*>)?\s*:\s*([^{]*)\{', re.M)


def struct_extents(text):
    """[(name, conformances, start, end)] for every struct, end = index after its closing brace."""
    out = []
    for m in STRUCT.finditer(text):
        depth = 0; i = m.end() - 1
        while i < len(text):
            c = text[i]
            if c == '{': depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0: break
            i += 1
        out.append((m.group(2), m.group(3), m.start(), i + 1))
    return out


def scan(path):
    s = open(path, encoding='utf-8', errors='ignore').read()
    settings_observers = len(OBS_SETTINGS.findall(s))
    slices = {m.group(2) for m in OBS_SLICE.finditer(s)}
    reads = set(READ.findall(s)) | {m.group(2) for m in SLICE_READ.finditer(s)}
    needs = collections.defaultdict(set)
    unknown = set()
    for r in sorted(reads):
        owners = resolve(r)
        if owners:
            for o in owners: needs[o].add(r)
        else:
            unknown.add(r)
    return settings_observers, slices, needs, unknown


def main():
    files = []
    for top in ('iPhone', 'Apple Watch'):
        for dp, _, fs in os.walk(os.path.join(ROOT, top)):
            for f in fs:
                if f.endswith('.swift'): files.append(os.path.join(dp, f))
    backlog = '--backlog' in sys.argv; stale_only = '--stale' in sys.argv
    stale = 0; total_observers = 0; files_with = 0
    for path in sorted(files):
        if 'Settings/Model/' in path: continue
        n, slices, needs, unknown = scan(path)
        if n == 0 and not slices: continue
        rel = os.path.relpath(path, ROOT)
        total_observers += n; files_with += 1 if n else 0
        if backlog:
            if n: print(f'{n:3d}  {rel}  needs {sorted(needs)}')
            continue
        if stale_only:
            # Per View struct: what it observes against what its own body reads through `settings` or
            # `Settings.shared`. Code outside any View struct (a store, a helper) reads at action time.
            s = open(path, encoding='utf-8', errors='ignore').read()
            for name, conf, start, end in struct_extents(s):
                if not re.search(r'\b(View|ViewModifier|DynamicProperty)\b', conf): continue
                body = s[start:end]
                if 'settings = Settings.shared' not in body and not OBS_SLICE.search(body): continue
                observed = {m.group(2) for m in OBS_SLICE.finditer(body)}
                live = set(re.findall(r'@ObservedObject (?:private )?var \w+ = (LiveState|ReadingState)\.shared', body))
                gaps = {}
                for r in sorted(set(READ.findall(body))):
                    for o in resolve(r):
                        if o in ('LiveState', 'ReadingState'):
                            if o not in live: gaps.setdefault(o, []).append(r)
                        elif o not in observed: gaps.setdefault(o, []).append(r)
                slice_gaps = {o: v for o, v in gaps.items() if o not in ('LiveState', 'ReadingState')}
                live_gaps = {o: v for o, v in gaps.items() if o in ('LiveState', 'ReadingState')}
                migrated = re.search(r'^\s*private let settings = Settings\.shared\s*$', body, re.M) is not None
                if slice_gaps and migrated:
                    stale += 1
                    print(f'STALE {rel} {name}: observes {sorted(observed | live)}, reads ' + '; '.join(f'{o}: {v}' for o, v in slice_gaps.items()))
                elif slice_gaps:
                    print(f'NOTE  {rel} {name}: never observed Settings; reads ' + '; '.join(f'{o}: {v}' for o, v in slice_gaps.items()))
                if live_gaps:
                    print(f'NOTE  {rel} {name}: pre-existing (Phase 1 step 6 rule): reads ' + '; '.join(f'{o}: {v}' for o, v in live_gaps.items()))
            continue
        print(f'{rel}: settings observers {n}, slices {sorted(slices) or "-"}')
        for o in sorted(needs): print(f'    {o:20s} {sorted(needs[o])}')
        if unknown: print(f'    {"(unresolved)":20s} {sorted(unknown)}')
    if backlog: print(f'\n{total_observers} Settings observers in {files_with} files')
    if stale_only:
        print(f'{stale} stale files'); sys.exit(1 if stale else 0)


if __name__ == '__main__':
    main()
