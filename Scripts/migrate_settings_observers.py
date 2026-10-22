#!/usr/bin/env python3
"""Move a View struct off `@ObservedObject var settings = Settings.shared` and onto the slices it reads.

Performance Guide, section 18, Stage 3. For every `struct X: View` (or ViewModifier) that holds the
whole-object observer, the struct's own reads of `settings.<member>` are resolved to slices (a stored
field by the key table, a computed property or method by the stored fields its body reads, the same
resolution as Scripts/qa/settings_observers.py), and the observer line becomes

    private let settings = Settings.shared                      // reads, unobserved
    @ObservedObject private var quranDisplay = QuranDisplay.shared  // one per slice the body can read

`$settings.<field>` bindings move to the owning slice's forwarder (`$quranDisplay.<field>`), which the
compiler checks. A read of a member no slice resolves to is reported, never guessed.

    python3 Scripts/migrate_settings_observers.py --dry-run [paths...]
    python3 Scripts/migrate_settings_observers.py [paths...]      # rewrites in place
"""
import os, re, sys, importlib.util

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location('audit', os.path.join(ROOT, 'Scripts/qa/settings_observers.py'))
audit = importlib.util.module_from_spec(spec); spec.loader.exec_module(audit)

VAR = {'AppearanceSettings': 'appearanceSettings', 'SystemSettings': 'systemSettings', 'AdhanSettings': 'adhanSettings',
       'PrayerTracker': 'prayerTracker', 'QuranDisplay': 'quranDisplay', 'QuranContent': 'quranContent',
       'HadithSettings': 'hadithSettings', 'IslamSettings': 'islamSettings', 'LiveState': 'live', 'ReadingState': 'reading'}
OBSERVER = re.compile(r'^(\s*)(?:@ObservedObject (?:private )?var|private let) settings = Settings\.shared\s*$', re.M)
STRUCT = re.compile(r'^(\s*)(?:(?:private|fileprivate|public|internal)\s+)?struct\s+(\w+)\s*(?:<[^>]*>)?\s*:\s*([^{]*)\{', re.M)
READ = re.compile(r'\b(?:settings|Settings\.shared)\.([A-Za-z_][A-Za-z0-9_]*)')
BIND = re.compile(r'\$settings\.([A-Za-z_][A-Za-z0-9_]*)')


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


def innermost(structs, pos):
    best = None
    for s in structs:
        if s[2] <= pos < s[3] and (best is None or (s[3] - s[2]) < (best[3] - best[2])): best = s
    return best


def migrate(path, dry):
    text = open(path, encoding='utf-8').read()
    structs = struct_extents(text)
    edits = []; notes = []
    for m in OBSERVER.finditer(text):
        owner = innermost(structs, m.start())
        if owner is None or not re.search(r'\b(View|ViewModifier|DynamicProperty)\b', owner[1]):
            notes.append(f'  skip: observer at offset {m.start()} is not inside a View struct'); continue
        name, _, start, end = owner
        body = text[start:end]
        # Reads inside this struct only (nested structs included: they share the slices anyway).
        members = set(READ.findall(body))
        needs = set(); unresolved = set()
        for member in sorted(members):
            owners = audit.resolve(member)
            if owners: needs |= owners
            else: unresolved.add(member)
        bound = set(BIND.findall(body))
        bad_binds = {b for b in bound if b not in audit.FIELD_SLICE}
        if unresolved: notes.append(f'  {name}: unresolved reads {sorted(unresolved)} (left on settings)')
        if bad_binds: notes.append(f'  {name}: bindings to non-stored members {sorted(bad_binds)} (NOT rewritten; fix by hand)')
        indent = m.group(1)
        lines = [f'{indent}private let settings = Settings.shared']
        for slice_name in sorted(needs):
            if slice_name in ('LiveState', 'ReadingState'):
                if not re.search(r'@ObservedObject (?:private )?var \w+ = %s\.shared' % slice_name, body):
                    notes.append(f'  {name}: reads {slice_name} members without observing {slice_name} (pre-existing; add by hand)')
                continue
            if re.search(r'@ObservedObject (?:private )?var \w+ = %s\.shared' % slice_name, body): continue
            lines.append(f'{indent}@ObservedObject private var {VAR[slice_name]} = {slice_name}.shared')
        edits.append((m.start(), m.end(), '\n'.join(lines), name, sorted(needs), bound - bad_binds))
    if not edits:
        return 0, notes
    # Apply from the end so offsets stay valid; rewrite bindings inside each struct's extent.
    for start, end, replacement, name, needs, binds in sorted(edits, reverse=True):
        owner = innermost(structs, start)
        s_start, s_end = owner[2], owner[3]
        body = text[s_start:s_end]
        def rebind(mm):
            field = mm.group(1)
            if field not in audit.FIELD_SLICE: return mm.group(0)   # a computed binding: by hand
            return f'${VAR[audit.FIELD_SLICE[field]]}.{field}'
        body = BIND.sub(rebind, body)
        # the observer line itself, relative to the struct
        rel = start - s_start
        body = body[:rel] + replacement + body[rel + (end - start):]
        text = text[:s_start] + body + text[s_end:]
        notes.append(f'  {name}: -> {needs}' + (f', {len(binds)} bindings moved' if binds else ''))
    if not dry:
        open(path, 'w', encoding='utf-8').write(text)
    return len(edits), notes


def main():
    dry = '--dry-run' in sys.argv
    paths = [a for a in sys.argv[1:] if not a.startswith('--')]
    if not paths:
        for top in ('iPhone', 'Apple Watch'):
            for dp, _, fs in os.walk(os.path.join(ROOT, top)):
                for f in fs:
                    if f.endswith('.swift') and 'Settings/Model/' not in dp: paths.append(os.path.join(dp, f))
    total = 0
    for p in sorted(paths):
        n, notes = migrate(p, dry)
        if n or notes:
            print(f'{os.path.relpath(p, ROOT)}: {n} observer(s)')
            for line in notes: print(line)
        total += n
    print(f'{"would migrate" if dry else "migrated"} {total} observers')


if __name__ == '__main__':
    main()
