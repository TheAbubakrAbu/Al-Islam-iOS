#!/usr/bin/env python3
"""Generate iPhone/Settings/Model/SettingsSlices.swift from the stored settings in Settings.swift.

Performance Guide, section 18 (Stage 2). Every `@Setting` and `@Published` field of `Settings` is
assigned to exactly ONE slice below (or listed as unrouted). A slice is an ObservableObject that
publishes only when one of its keys changes; views observe the slice they read, through the typed
forwarders this script writes, instead of the whole `Settings` object.

Run it after adding a field to Settings.swift (the script fails on an unassigned name, and
`UnitTests/SettingsSliceTests` fails on an unassigned key):

    python3 Scripts/gen_settings_slices.py            # writes the Swift file and Scripts/qa/settings_slices.json
    python3 Scripts/gen_settings_slices.py --check    # exits 1 if the committed file is stale
"""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, 'iPhone/Settings/Model/Settings.swift')
TARGET = os.path.join(ROOT, 'iPhone/Settings/Model/SettingsSlices.swift')
JSON = os.path.join(ROOT, 'Scripts/qa/settings_slices.json')

# --- The assignment -------------------------------------------------------------------------------
# Slice name -> (doc line, explicit field names). Prefix rules below catch the per-prayer families.
SLICES = {
    'AppearanceSettings': (
        'Accent, theme, color scheme, glass and glow: what the chrome everywhere draws with (the '
        'appearance environment snapshots these).',
        {'accentColor', 'customAccentColorHex', 'customBackgroundColorHex', 'defaultView', 'classicLook',
         'classicLookInLowPower', 'showAccentGlow', 'alIslamGlow', 'colorSchemeString', 'userBackgroundRaw'}),
    'SystemSettings': (
        'App-wide switches no tab owns: onboarding flags, Simple Mode, Advanced, haptics, keep screen on, '
        'the launch tab, grid modes, help doors, tab sections, the daily rollover hour.',
        {'firstLaunch', 'aboutYouVersionSeen', 'cloudOfferVersionSeen', 'startHereHidden', 'startHereVisitedRaw',
         'helpDoorsHiddenRaw', 'helpDoorsCollapsedRaw', 'tabSectionChoicesRaw', 'tabSectionsCollapsedRaw', 'launchTabRaw', 'launchTabChosen', 'hapticOn', 'keepScreenOnRaw',
         'advancedSettings', 'simpleMode', 'gridMode', 'gridModeArabicRaw', 'gridModeNamesRaw', 'gridModeIslamRaw',
         'gridModeSettingsRaw', 'dailyRolloverAtFajr'}),
    'AdhanSettings': (
        'Prayer times, notifications, nagging, adhan sounds, travel, calculation, the sky and the '
        'permission alerts: the Adhan tab and its settings pages.',
        {'travelingMode', 'homeLocation', 'favoriteLocations', 'hanafiMadhab', 'prayerCalculation', 'hijriOffset',
         'highLatitudeRule', 'customPrayerNames', 'hijriDateData', 'datePrayers', 'dateFullPrayers', 'changedDate',
         'lastScheduledHijriYear', 'dateNotifications', 'dateNotificationsDayBefore', 'prayerNotificationEnglishNames',
         'switchHijriDateAtMaghrib', 'alertToneSound', 'customFajrAngle', 'customIshaAngle', 'currentCountryCode',
         'showLocationAlert', 'showNotificationAlert', 'locationNeverAskAgain', 'notificationNeverAskAgain',
         'locationAlertSnoozedUntil', 'notificationAlertSnoozedUntil', 'showPrayerInfo', 'showDuha',
         'showIslamicMidnight', 'showLastThird', 'lastTravelingNotificationStamp', 'lastCalculationNotificationStamp'}),
    'PrayerTracker': (
        'The prayer tracker marks and the menses pause: written from the tracker and the notification '
        'actions while the user is anywhere.',
        {'prayerTrackerData', 'trackerExemptDaysData', 'mensesPauseActive', 'mensesPauseStartStamp'}),
    'QuranDisplay': (
        'How the Quran reads: fonts and sizes, tajweed, translations, word by word, page mode, riwayah, '
        'the reciter, sort and list options, test mode.',
        {'reciter', 'reciterId', 'reciteType', 'showBookmarks', 'showFavorites', 'quranPageMode', 'mushafFitPage',
         'mushafTwoPageSpread', 'mushafPageLanguage', 'mushafPDFAppearance', 'mushafHafsPDFEdition',
         'showMuqattaatHelper', 'showAyahInformation', 'showSurahInformation', 'beginnerMode', 'quranSortModeRaw',
         'quranSortDirectionRaw', 'khatmGroupByJuz', 'searchForSurahs', 'saveLastReadAyah', 'saveLastListenedSurah',
         'saveLastListenedAyah', 'showAyahOfTheDay', 'showWordOfTheDay', 'displayQiraah', 'qiraatComparisonMode',
         'showOtherQiraatReciters', 'betaQiraatEnabled', 'acceptedBetaQiraatNotice', 'riwayahTajweedHiddenRules',
         'tajweedCustomColors', 'showArabicText', 'highlightAllahNames', 'keepAyahSheetOpen', 'keepAyahSheetOpenOnPlay', 'waslSignRaw',
         'ayahSheetKeepsScreenOn', 'ayahPreviewCardScale',
         'cleanArabicText', 'removeArabicDots', 'showTransliteration', 'showEnglishSaheeh', 'showEnglishMustafa',
         'showPageJuzDividers', 'showFullSurahRow', 'englishFontSize', 'fontArabic', 'fontArabicSize', 'useFontArabic',
         'arabicScriptStyleRaw', 'automaticKhatmCompletion'}),
    'QuranContent': (
        'What reading and listening write: bookmarks, favorites, khatm and revision progress, plans, '
        'search history, the daily ayah, the Now Playing bar state, surah counts, the last listened ayah.',
        {'favoriteReciterIDsData', 'favoriteQiraahTagsData', 'favoriteEnglishTranslationIDsData',
         'savedSajdahAyahIDsData', 'savedBrokenLetterAyahIDsData', 'favoriteSurahsData', 'khatmCompletedAyahsData',
         'quranPlanData', 'quranRevisionPlanData', 'quranRevisionRevisedData', 'bookmarkedAyahsData',
         'quranSearchHistoryData', 'ayahOfTheDayHiddenDate', 'ayahOfTheDayOverride', 'nowPlayingExpanded'}),
    'HadithSettings': (
        'The Hadith tab: languages, sizes, Allah highlight, the daily hadith, search history.',
        {'showHadithArabic', 'showHadithEnglish', 'highlightAllahNamesHadith', 'hadithArabicFontSize',
         'hadithEnglishFontSize', 'showHadithOfTheDay', 'hadithOfTheDayHiddenDate', 'hadithSearchHistoryData'}),
    'IslamSettings': (
        'The Islam tab: text size and face, Allah highlight, resource grouping and favorites, the '
        'Arabic alphabet screens, the 99 Names.',
        {'islamTextSize', 'islamArabicFaceRaw', 'highlightAllahNamesIslam', 'islamGroupResources',
         'arabicLetterSizeIndex', 'hideEnglishInArabicLetters', 'quranicSukoonInLetterPractice', 'favoriteLetterData',
         'favoriteIslamResourcesRaw', 'favoriteNameNumbersData', 'showDescription'}),
}
# Families assigned by prefix (the per-prayer notification, nagging, offset and adhan fields).
PREFIX_RULES = [
    ('preNotification', 'AdhanSettings'), ('notification', 'AdhanSettings'), ('nagging', 'AdhanSettings'),
    ('offset', 'AdhanSettings'), ('adhan', 'AdhanSettings'), ('shortAdhan', 'AdhanSettings'),
    ('travel', 'AdhanSettings'), ('calculationAuto', 'AdhanSettings'), ('sky', 'AdhanSettings'),
    ('showSky', 'AdhanSettings'), ('showTajweed', 'QuranDisplay'), ('wordByWord', 'QuranDisplay'),
    ('copyAyah', 'QuranDisplay'), ('quranTestMode', 'QuranDisplay'),
]
# Private to the launch: no slice, no forwarder. (The live prayer state lives on `LiveState`, outside
# the class, so the parse never sees it.)
UNROUTED = {'isReadyForUI'}
# Defaults keys the model writes by hand (no wrapper), routed by key.
EXTRA_KEYS = {
    'QuranContent': ['surahOpenCountsData', 'surahPlayCountsData', 'lastListenedAyahData', 'lastListenedSurahData'],
}
# Computed, settable members of Settings that a view BINDS to (`$slice.x`), forwarded like a field.
EXTRA_FORWARDERS = {
    'AppearanceSettings': [('showLiquidGlass', 'Bool')],
}

# --- Parse ----------------------------------------------------------------------------------------
SETTING = re.compile(r'^\s*@Setting\("([^"]+)"\)\s*((?:private |private\(set\) )?)var\s+([A-Za-z0-9_]+)'
                     r'(?::\s*([A-Za-z?\[\]: ]+?))?\s*(?:=\s*([^{]*?))?\s*(\{.*)?\s*$')
PUBLISHED = re.compile(r'^\s*@Published\s*((?:private\(set\) )?)var\s+([A-Za-z0-9_]+)'
                       r'(?::\s*([A-Za-z?\[\]: ]+?))?\s*(?:=\s*([^{]*?))?\s*(\{.*)?\s*$')
CLASS_START = re.compile(r'^final class Settings\b')
CLASS_END = re.compile(r'^}\s*$')


def infer_type(default):
    d = (default or '').strip()
    if d in ('true', 'false'): return 'Bool'
    if d.startswith('Data('): return 'Data'
    if d.startswith('"'): return 'String'
    if re.match(r'^-?\d+\.\d+$', d): return 'Double'
    if re.match(r'^-?\d+$', d): return 'Int'
    raise SystemExit(f'cannot infer a type from the default {d!r}')


def parse():
    fields = []
    inside = False
    for line in open(SOURCE, encoding='utf-8'):
        if CLASS_START.match(line): inside = True; continue
        if inside and CLASS_END.match(line): break
        if not inside: continue
        m = SETTING.match(line)
        if m:
            key, mod, name, typ, default, _ = m.groups()
            fields.append(dict(name=name, key=key, type=(typ or infer_type(default)).strip(),
                               private='private' in mod, kind='setting'))
            continue
        m = PUBLISHED.match(line)
        if m:
            mod, name, typ, default, _ = m.groups()
            fields.append(dict(name=name, key=name, type=(typ or infer_type(default)).strip(),
                               private='private' in mod, kind='published'))
    return fields


def slice_of(name):
    for slice_name, (_, names) in SLICES.items():
        if name in names: return slice_name
    for prefix, slice_name in PREFIX_RULES:
        if name.startswith(prefix): return slice_name
    return None


def assign(fields):
    by_slice = {name: [] for name in SLICES}
    unassigned = []
    for f in fields:
        if f['name'] in UNROUTED: continue
        s = slice_of(f['name'])
        if s is None: unassigned.append(f['name']); continue
        by_slice[s].append(f)
    if unassigned:
        raise SystemExit('assign these fields to a slice in Scripts/gen_settings_slices.py: ' + ', '.join(unassigned))
    claimed = {n for _, names in SLICES.values() for n in names} | UNROUTED
    known = {f['name'] for f in fields}
    gone = sorted(claimed - known)
    if gone:
        raise SystemExit('listed in the generator but not in Settings.swift any more: ' + ', '.join(gone))
    return by_slice


# --- Emit -----------------------------------------------------------------------------------------
def emit(by_slice):
    out = []
    w = out.append
    w('// GENERATED by Scripts/gen_settings_slices.py from iPhone/Settings/Model/Settings.swift.')
    w('// Do not edit by hand: assign new fields in the script and rerun it.')
    w('//')
    w('// The slices of `Settings` (Performance Guide, section 18). `Settings` keeps every stored setting;')
    w('// a slice owns a set of its KEYS, publishes when one of them is about to change (routed from')
    w('// `Settings.settingWillChange`), and forwards the same properties, so a view observes the slice it')
    w('// reads instead of the whole object and re-renders only for the fields that can change what it shows.')
    w('')
    w('import Foundation')
    w('import Combine')
    w('')
    w('/// One slice: a key set and a publish, so the router can be written once.')
    w('protocol SettingsSlice: AnyObject {')
    w('    static var keys: Set<String> { get }')
    w('    static var label: String { get }')
    w('    /// `objectWillChange`, type-erased, so a subscriber can merge several slices.')
    w('    var willChange: AnyPublisher<Void, Never> { get }')
    w('    func publish()')
    w('}')
    w('')
    w('/// The router: a changed key publishes the ONE slice that owns it; a bulk replace publishes all.')
    w('enum SettingsSlices {')
    w('    static let all: [any SettingsSlice] = [')
    for s in SLICES: w(f'        {s}.shared,')
    w('    ]')
    w('')
    w('    private static let owners: [String: any SettingsSlice] = {')
    w('        var owners: [String: any SettingsSlice] = [:]')
    w('        for slice in all {')
    w('            for key in type(of: slice).keys { owners[key] = slice }')
    w('        }')
    w('        return owners')
    w('    }()')
    w('')
    w('    static func willChange(_ key: String) {')
    w('        owners[key]?.publish()')
    w('    }')
    w('')
    w('    static func willChangeAll() {')
    w('        for slice in all { slice.publish() }')
    w('    }')
    w('}')
    for s, (doc, _) in SLICES.items():
        fields = by_slice[s]
        keys = sorted({f['key'] for f in fields} | set(EXTRA_KEYS.get(s, [])))
        w('')
        w(f'/// {doc}')
        w(f'final class {s}: ObservableObject, SettingsSlice {{')
        w(f'    static let shared = {s}()')
        w(f'    static let label = "{s}"')
        w('    static let keys: Set<String> = [')
        for i in range(0, len(keys), 4):
            w('        ' + ', '.join(f'"{k}"' for k in keys[i:i + 4]) + ',')
        w('    ]')
        w('')
        w('    private init() { ObjectPublishCounter.attach(self, label: Self.label) }')
        w('')
        w('    var willChange: AnyPublisher<Void, Never> { objectWillChange.eraseToAnyPublisher() }')
        w('')
        w('    func publish() { objectWillChange.send() }')
        extra = [dict(name=n, type=t, private=False) for n, t in EXTRA_FORWARDERS.get(s, [])]
        for f in sorted(fields + extra, key=lambda f: f['name']):
            if f['private']: continue
            w('')
            w(f"    var {f['name']}: {f['type']} {{")
            w(f"        get {{ Settings.shared.{f['name']} }}")
            w(f"        set {{ Settings.shared.{f['name']} = newValue }}")
            w('    }')
        w('}')
    return '\n'.join(out) + '\n'


def main():
    fields = parse()
    by_slice = assign(fields)
    swift = emit(by_slice)
    data = {s: {'keys': sorted({f['key'] for f in by_slice[s]} | set(EXTRA_KEYS.get(s, []))),
                'fields': sorted(f['name'] for f in by_slice[s] if not f['private'])} for s in SLICES}
    if '--check' in sys.argv:
        current = open(TARGET, encoding='utf-8').read() if os.path.exists(TARGET) else ''
        if current != swift:
            print('SettingsSlices.swift is stale: rerun Scripts/gen_settings_slices.py'); sys.exit(1)
        print('SettingsSlices.swift is current'); return
    open(TARGET, 'w', encoding='utf-8').write(swift)
    with open(JSON, 'w', encoding='utf-8') as fh: json.dump(data, fh, indent=1, sort_keys=True)
    for s in SLICES: print(f"{s:20s} {len(data[s]['keys']):4d} keys  {len(data[s]['fields']):4d} forwarders")
    print(f'{len(fields)} fields parsed, {len(UNROUTED)} unrouted')


if __name__ == '__main__':
    main()
