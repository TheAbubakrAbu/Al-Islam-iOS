#if os(iOS)
import SwiftUI

// One place of the Qiraat Explorer, worked out word by word (Abu, 2026-10-09: "qiraat explorer is
// messy and hard to understand and is laggy and is ugly").
//
// The explorer used to say each difference three times: the riwayat grouped by the whole set of words
// each one changes, the Quran.com reference's readings under that, and then every riwayah's whole ayah
// (twelve near-identical cards at 1:4, each repeating one changed word). What all three were circling
// is a SITE: one word, or a short run of words, of the Hafs ayah that some riwayah reads differently.
// A place is built here as its sites, each with every way it is read, who reads it each way, and what
// the reading means where the reference says.
//
// Everything in this file runs off the main thread (the explorer's build task): the resolver, the
// alignment, the tajweed packs and the readings table are lock-guarded, and nothing here reads
// `Settings.shared`.

// MARK: - Alignment units

/// One riwayah against Hafs, cut into the units the word diff pairs them by: a word both read alike
/// once folded (the print may still flag it as read differently), or the gap between two such words.
enum QiraatAlignment {
    struct Unit: Equatable {
        /// Hafs token indices over the change's Hafs text; empty where the riwayah adds words.
        let hafs: Range<Int>
        /// Riwayah token indices over the change's riwayah text; empty where it drops words.
        let riwayah: Range<Int>
        /// Whether the unit counts as a difference under the tier: what earns a word its card.
        let isChange: Bool
        /// Whether it differs at all, down to one letter's marks: what a riwayah is shown reading
        /// once the word has a card (Nafi's يُكَذِّبُونَ at 2:10 is a letter-level change in Warsh's
        /// print, and a word-level one in ad-Duri's; both read it so).
        let differs: Bool
    }

    static func units(of change: QiraatChange, everyDifference: Bool) -> [Unit] {
        let hafsCounted = everyDifference ? Set(change.hafsWords) : change.hafsWordLevel
        let riwayahCounted = everyDifference ? Set(change.riwayahWords) : change.riwayahWordLevel
        let hafsAny = Set(change.hafsWords)
        let riwayahAny = Set(change.riwayahWords)
        var units: [Unit] = []
        var h = 0
        var r = 0
        func gap(to hafsEnd: Int, _ riwayahEnd: Int) {
            guard hafsEnd > h || riwayahEnd > r else { return }
            let hafs = h..<hafsEnd
            let riwayah = r..<riwayahEnd
            units.append(Unit(hafs: hafs, riwayah: riwayah,
                              isChange: hafs.contains(where: hafsCounted.contains) || riwayah.contains(where: riwayahCounted.contains),
                              differs: hafs.contains(where: hafsAny.contains) || riwayah.contains(where: riwayahAny.contains)))
        }
        for (hafsIndex, riwayahIndex) in change.diff.pairs.sorted(by: { $0.key < $1.key }) {
            gap(to: hafsIndex, riwayahIndex)
            units.append(Unit(hafs: hafsIndex..<(hafsIndex + 1), riwayah: riwayahIndex..<(riwayahIndex + 1),
                              isChange: hafsCounted.contains(hafsIndex) || riwayahCounted.contains(riwayahIndex),
                              differs: hafsAny.contains(hafsIndex) || riwayahAny.contains(riwayahIndex)))
            h = hafsIndex + 1
            r = riwayahIndex + 1
        }
        gap(to: change.diff.hafs.count, change.diff.riwayah.count)
        return units
    }
}

// MARK: - The model

/// One riwayah at the place: its text resolved through Hafs and diffed against it.
struct QiraatPlaceSide: Identifiable {
    let tag: String
    /// Nil: the riwayah does not number this ayah on its own (the basmalah in the Madani count).
    let resolved: ResolvedQiraahText?
    let change: QiraatChange?
    /// Where this Hafs ayah's words start in `change.hafsText` (a joined span's earlier ayahs first).
    let hafsBase: Int

    var id: String { tag.isEmpty ? "Hafs" : tag }
}

/// One way a site is read, and the riwayat that read it so.
struct QiraatSiteReading: Identifiable, Equatable {
    let id: Int
    /// The words as read, stop signs dropped; "" when the riwayah reads none of the site's words.
    let text: String
    /// Whose print the words come from, for the face they are set in (the prints mark differently).
    let fontTag: String
    /// Riwayah tags in the classical order; "" is Hafs, and its group is always first.
    var tags: [String]
    var english = ""
    var transliteration = ""
    /// The UTF-16 ranges of `text` to set in the accent when the reading is emphasized: the letters
    /// the print marks as read differently from Hafs in the words it changes, and whole words where
    /// it marks nothing. Nil for Hafs's own reading and for a riwayah without print letters, whose
    /// whole reading takes the accent.
    var letters: [NSRange]? = nil

    var isHafs: Bool { tags.contains(Settings.Riwayah.hafsTag) }
    /// The site's first reading: Hafs's words, read so by Hafs and by every riwayah grouped with him
    /// (Compare Two renames the groups by side and keeps the ids).
    var readsAsHafs: Bool { id == 0 }
}

/// A word, or a short run of words, of the Hafs ayah that some riwayah reads differently.
struct QiraatSite: Identifiable {
    /// Token indices of the Hafs ayah (its own text, never a joined span's). Includes the words
    /// either side of a word some riwayah adds or drops, so every reading has words to stand on.
    let range: ClosedRange<Int>
    /// Hafs's reading first (with every riwayah that reads as Hafs here), then the others.
    var readings: [QiraatSiteReading]
    /// Per riwayah that reads the site differently: the Hafs tokens it changes (local to the ayah)...
    var changedHafs: [String: [Int]]
    /// ...and its own tokens that do the changing (over its whole text), for the tints.
    var changedRiwayah: [String: [Int]]
    /// Per riwayah: Hafs token (local) -> its own token, for the words both read alike inside the site.
    var aligned: [String: [Int: Int]]
    /// "Differs in sense" and the like, from the reference.
    var caption: String?
    var note = ""

    var id: Int { range.lowerBound }

    func reading(of tag: String) -> QiraatSiteReading? {
        readings.first { $0.tags.contains(tag) }
    }

    /// The reference renders every reading here alike (or not at all): its English is said once.
    var sharedEnglish: String? {
        let renderings = Set(readings.map(\.english))
        guard renderings.count == 1, let only = renderings.first, !only.isEmpty else { return nil }
        return only
    }
}

/// Everything the explorer shows at one Hafs ayah.
struct QiraatPlace {
    let surah: Int
    let hafsAyah: Int
    let everyDifference: Bool
    let hafsText: String
    let hafsTokens: [QiraatWordDiff.Token]
    let english: String
    /// The compared riwayat in the order asked (Hafs excluded: it is the reference).
    let sides: [QiraatPlaceSide]
    let sites: [QiraatSite]
    /// Riwayat with one reciter's recording of this verse both ways.
    let audioTags: [String]
    /// The reference has readings for this ayah, so its full page has something to show.
    let hasReference: Bool
    /// What the Hafs card tints: every word some riwayah changes, as the letters that differ where
    /// the riwayah's print marks them and whole otherwise (`QiraatPlaceBuilder.tints`).
    var hafsTint: QiraatTint.Spec = .none
    /// Per riwayah, what its whole-ayah card tints: its changed words, as its print's letters or whole.
    var riwayahTints: [String: QiraatTint.Spec] = [:]

    var key: String { "\(surah):\(hafsAyah)" }

    /// Every Hafs word some riwayah changes (the words; `hafsTint` is what the card draws).
    var hafsTinted: Set<Int> {
        Set(sites.flatMap { $0.changedHafs.values.joined() })
    }

    /// The words of `tag`'s own text that differ from Hafs here.
    func tinted(_ tag: String) -> Set<Int> {
        Set(sites.flatMap { $0.changedRiwayah[tag] ?? [] })
    }

    /// What `tag`'s whole-ayah card tints.
    func tint(_ tag: String) -> QiraatTint.Spec {
        riwayahTints[tag] ?? .none
    }

    func side(_ tag: String) -> QiraatPlaceSide? {
        sides.first { $0.tag == tag }
    }

    /// Riwayat that read some site of this ayah differently, in order.
    var differingTags: [String] {
        sides.map(\.tag).filter { tag in sites.contains { $0.changedHafs[tag] != nil || $0.changedRiwayah[tag] != nil } }
    }

    /// Riwayat with a text here that changes none of it.
    var alikeTags: [String] {
        let differing = Set(differingTags)
        return sides.filter { $0.resolved != nil && !differing.contains($0.tag) }.map(\.tag)
    }

    /// Riwayat that do not number this ayah on its own.
    var unavailableTags: [String] {
        sides.filter { $0.resolved == nil }.map(\.tag)
    }
}

/// Two riwayat at one place, read against each other rather than against Hafs.
struct QiraatDuelPlace {
    let a: String
    let b: String
    let place: QiraatPlace
    /// The sites where the two read differently, each with exactly their two readings.
    let sites: [QiraatSite]
    /// What each side's text tints where the two part ways (`QiraatPlaceBuilder.duel`).
    let aTint: QiraatTint.Spec
    let bTint: QiraatTint.Spec

    /// A side's whole text: Hafs's own ayah, or the riwayah's text aligned to it.
    func text(_ tag: String) -> (text: String, tokens: [QiraatWordDiff.Token])? {
        if tag.isEmpty { return (place.hafsText, place.hafsTokens) }
        guard let change = place.side(tag)?.change else { return nil }
        return (change.riwayahText, change.diff.riwayah)
    }

    func resolved(_ tag: String) -> ResolvedQiraahText? {
        tag.isEmpty ? nil : place.side(tag)?.resolved
    }

    func isAvailable(_ tag: String) -> Bool {
        tag.isEmpty || place.side(tag)?.resolved != nil
    }
}

// MARK: - Building a place

enum QiraatPlaceBuilder {
    /// Everything one place shows. `tags` are the riwayat compared (Hafs excluded). `annotate` adds
    /// the reference's meanings and the recordings, which the duel's place finder does not need.
    static func build(surah: Int, hafsAyah: Int, tags: [String], everyDifference: Bool,
                      quranData: QuranData, annotate: Bool = true) async -> QiraatPlace {
        let ayah = quranData.ayah(surah: surah, ayah: hafsAyah)
        let hafsText = ayah?.rawArabicText(surahId: surah, qiraahOverride: "") ?? ""
        let hafsTokens = QiraatWordDiff.tokens(of: hafsText)
        let sides = await Self.sides(surah: surah, hafsAyah: hafsAyah, tags: tags, quranData: quranData)
        var sites = Self.sites(hafsTokens: hafsTokens, sides: sides, everyDifference: everyDifference)
        var hasReference = false
        var audioTags: [String] = []
        if annotate {
            hasReference = Self.annotate(&sites, surah: surah, hafsAyah: hafsAyah)
            if QiraatVariantAudioStore.isBundled {
                audioTags = tags.filter { QiraatVariantAudioStore.shared.pair(tag: $0, surah: surah, ayah: hafsAyah) != nil }
            }
        }
        let tints = Self.tints(hafsText: hafsText, hafsTokens: hafsTokens, sides: sides, sites: sites)
        return QiraatPlace(surah: surah, hafsAyah: hafsAyah, everyDifference: everyDifference,
                           hafsText: hafsText, hafsTokens: hafsTokens, english: ayah?.textEnglishSaheeh ?? "",
                           sides: sides, sites: sites, audioTags: audioTags, hasReference: hasReference,
                           hafsTint: tints.hafs, riwayahTints: tints.riwayah)
    }

    /// Each riwayah resolved and diffed against Hafs, side by side on every core: the first place in
    /// a surah aligns it for each riwayah (about 7 ms a riwayah, optimized) and inflates any tajweed
    /// pack not yet read, which one after another held the first place back for most of a second.
    static func sides(surah: Int, hafsAyah: Int, tags: [String], quranData: QuranData) async -> [QiraatPlaceSide] {
        // Hafs's side of the alignment serves every riwayah: built once here, before the fan-out,
        // rather than by each child at the same moment.
        if let first = tags.first {
            _ = QiraahComparison.alignment(surahID: surah, tag: first, quranData: quranData)
        }
        return await withTaskGroup(of: (Int, QiraatPlaceSide).self) { group in
            for (index, tag) in tags.enumerated() {
                group.addTask {
                    (index, side(tag: tag, surah: surah, hafsAyah: hafsAyah, quranData: quranData))
                }
            }
            var ordered = [QiraatPlaceSide?](repeating: nil, count: tags.count)
            for await (index, side) in group { ordered[index] = side }
            return ordered.compactMap { $0 }
        }
    }

    static func side(tag: String, surah: Int, hafsAyah: Int, quranData: QuranData) -> QiraatPlaceSide {
        guard let resolved = QiraahAyahResolver.resolve(surahNumber: surah, ayahNumber: hafsAyah,
                                                        anchorHafsAyah: hafsAyah, optionTag: tag, clean: false) else {
            return QiraatPlaceSide(tag: tag, resolved: nil, change: nil, hafsBase: 0)
        }
        let change = QiraatChange.at(tag: tag, surah: surah, hafsAyah: hafsAyah, resolved: resolved, quranData: quranData)
        return QiraatPlaceSide(tag: tag, resolved: resolved, change: change, hafsBase: change.hafsStartByAyah[hafsAyah] ?? 0)
    }

    // MARK: Sites

    /// A unit in the ayah's own coordinates.
    private struct LocalUnit {
        /// The Hafs tokens the unit covers (clipped to the ayah); empty for added words.
        let hafs: ClosedRange<Int>?
        /// Added words: the position they sit before (0...count).
        let insertion: Int?
        /// The tokens a site around this unit must cover: added and dropped words take the words
        /// either side with them.
        let site: ClosedRange<Int>
        let riwayah: Range<Int>
        /// Counts under the tier: forms sites.
        let isChange: Bool
        /// Differs at all: decides what a riwayah reads inside a site.
        let differs: Bool

        func isInside(_ range: ClosedRange<Int>, count: Int) -> Bool {
            if let hafs { return hafs.overlaps(range) }
            guard let at = insertion else { return false }
            return (range.lowerBound < at && at <= range.upperBound)
                || (at == 0 && range.lowerBound == 0)
                || (at == count && range.upperBound == count - 1)
        }
    }

    private static func localUnits(_ side: QiraatPlaceSide, count: Int, everyDifference: Bool) -> [LocalUnit] {
        guard let change = side.change, count > 0 else { return [] }
        let base = side.hafsBase
        var out: [LocalUnit] = []
        for unit in QiraatAlignment.units(of: change, everyDifference: everyDifference) {
            if unit.hafs.isEmpty {
                // Words the riwayah adds belong to this ayah when they sit inside it, or open the
                // span (between two ayahs of a joined span they go with the earlier one).
                let at = unit.hafs.lowerBound - base
                guard (1...count).contains(at) || (at == 0 && base == 0) else { continue }
                out.append(LocalUnit(hafs: nil, insertion: at, site: max(at - 1, 0)...min(at, count - 1),
                                     riwayah: unit.riwayah, isChange: unit.isChange, differs: unit.differs))
            } else {
                let lo = unit.hafs.lowerBound - base
                let hi = unit.hafs.upperBound - 1 - base
                guard hi >= 0, lo < count else { continue }
                let hafs = max(lo, 0)...min(hi, count - 1)
                let dropped = unit.riwayah.isEmpty && unit.differs
                let site = dropped ? max(lo - 1, 0)...min(hi + 1, count - 1) : hafs
                out.append(LocalUnit(hafs: hafs, insertion: nil, site: site, riwayah: unit.riwayah,
                                     isChange: unit.isChange, differs: unit.differs))
            }
        }
        return out
    }

    private static func merged(_ ranges: [ClosedRange<Int>]) -> [ClosedRange<Int>] {
        var out: [ClosedRange<Int>] = []
        for range in ranges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if let last = out.last, range.lowerBound <= last.upperBound {
                out[out.count - 1] = last.lowerBound...max(last.upperBound, range.upperBound)
            } else {
                out.append(range)
            }
        }
        return out
    }

    /// The word as a reading shows it: stop signs belong to the print's pauses, not the reading.
    private static func shown(_ word: String) -> String {
        QiraatTint.withoutStopSigns(word).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sites(hafsTokens: [QiraatWordDiff.Token], sides: [QiraatPlaceSide], everyDifference: Bool) -> [QiraatSite] {
        let count = hafsTokens.count
        guard count > 0 else { return [] }
        let perSide = sides.map { side in (side, localUnits(side, count: count, everyDifference: everyDifference)) }

        var ranges = merged(perSide.flatMap { $0.1.filter(\.isChange).map(\.site) })
        guard !ranges.isEmpty else { return [] }
        // A gap is one unit. A site that cuts through one (any riwayah's, counted or not) grows over
        // all of it, or that riwayah's reading would carry words the Hafs side does not show.
        var grew = true
        while grew {
            grew = false
            for (_, units) in perSide {
                for unit in units {
                    guard let hafs = unit.hafs, hafs.count > 1 else { continue }
                    for index in ranges.indices where hafs.overlaps(ranges[index]) {
                        let union = min(hafs.lowerBound, ranges[index].lowerBound)...max(hafs.upperBound, ranges[index].upperBound)
                        if union != ranges[index] {
                            ranges[index] = union
                            grew = true
                        }
                    }
                }
            }
            if grew { ranges = merged(ranges) }
        }

        let order = Dictionary(uniqueKeysWithValues: Settings.Riwayah.allOptions.map { ($0.tag, $0.order) })
        var sites: [QiraatSite] = []
        for range in ranges {
            let hafsWords = range.map { shown(hafsTokens[$0].text) }.filter { !$0.isEmpty }.joined(separator: " ")
            var readings = [QiraatSiteReading(id: 0, text: hafsWords, fontTag: Settings.Riwayah.hafsTag,
                                              tags: [Settings.Riwayah.hafsTag])]
            let hafsKey = QiraahSpelling.key(hafsWords)
            var groupOfKey: [String: Int] = [hafsKey: 0]
            var changedHafs: [String: [Int]] = [:]
            var changedRiwayah: [String: [Int]] = [:]
            var aligned: [String: [Int: Int]] = [:]

            for (side, units) in perSide {
                guard let change = side.change else { continue }
                let inside = units.filter { $0.isInside(range, count: count) }
                var pairs: [Int: Int] = [:]
                for unit in inside where !unit.differs {
                    if let hafs = unit.hafs, hafs.count == 1, unit.riwayah.count == 1 {
                        pairs[hafs.lowerBound] = unit.riwayah.lowerBound
                    }
                }
                if !pairs.isEmpty { aligned[side.tag] = pairs }

                // The tier chose the site; inside it, every riwayah reads what its text says.
                let changes = inside.filter(\.differs)
                guard !changes.isEmpty else {
                    readings[0].tags.append(side.tag)
                    continue
                }
                let ownTokens = Array(Set(inside.flatMap { Array($0.riwayah) })).sorted()
                let changedTokens = Set(changes.flatMap { Array($0.riwayah) })
                // The reading's words, and, for a print with letters, what to accent in them: the
                // marked letters of each changed word (whole where it marks none); a neighbour the
                // site took along stays plain. `shown` drops only stop signs, which are no cluster,
                // so the pack's cluster extents hold on the shown word.
                var text = ""
                var letters: [NSRange] = []
                for token in ownTokens where change.diff.riwayah.indices.contains(token) {
                    let word = shown(change.diff.riwayah[token].text)
                    guard !word.isEmpty else { continue }
                    if !text.isEmpty { text += " " }
                    let at = text.utf16.count
                    if change.hasPrintLetters, changedTokens.contains(token) {
                        if let own = ownWordLetters(change, token: token, word: word) {
                            letters += own.map { NSRange(location: at + $0.location, length: $0.length) }
                        } else {
                            letters.append(NSRange(location: at, length: word.utf16.count))
                        }
                    }
                    text += word
                }
                let key = QiraahSpelling.key(text)
                if key == hafsKey {
                    // The print flags it, but the words come out as Hafs's: nothing to show apart.
                    readings[0].tags.append(side.tag)
                    continue
                }
                changedHafs[side.tag] = changes.compactMap(\.hafs).flatMap { Array($0) }.sorted()
                changedRiwayah[side.tag] = changes.flatMap { Array($0.riwayah) }.sorted()
                if let at = groupOfKey[key] {
                    readings[at].tags.append(side.tag)
                } else {
                    groupOfKey[key] = readings.count
                    readings.append(QiraatSiteReading(id: readings.count, text: text, fontTag: side.tag, tags: [side.tag],
                                                      letters: change.hasPrintLetters && !letters.isEmpty ? letters : nil))
                }
            }

            func rank(_ tag: String) -> Int { order[tag] ?? 99 }
            for index in readings.indices { readings[index].tags.sort { rank($0) < rank($1) } }
            let others = readings.dropFirst().sorted { rank($0.tags.first ?? "") < rank($1.tags.first ?? "") }
            guard !others.isEmpty else { continue }
            sites.append(QiraatSite(range: range, readings: [readings[0]] + others, changedHafs: changedHafs,
                                    changedRiwayah: changedRiwayah, aligned: aligned))
        }
        return sites
    }

    // MARK: The reference

    /// Each site's meanings from the Quran.com qiraat reference: the juncture whose words overlap the
    /// site, or the only one when the ayah has one of each. Returns whether the ayah has any.
    @discardableResult
    static func annotate(_ sites: inout [QiraatSite], surah: Int, hafsAyah: Int) -> Bool {
        let variants = QiraatVariantsStore.shared
        let junctures = variants.junctures(surah: surah, ayah: hafsAyah)
        guard !junctures.isEmpty else { return false }
        let key = "\(surah):\(hafsAyah)"
        var used = Set<Int>()
        for index in sites.indices {
            let range = sites[index].range
            let overlapping = junctures.first { juncture in
                !used.contains(juncture.id) && juncture.segments.contains { segment in
                    segment.key == key && (segment.range?.overlaps(range) ?? false)
                }
            }
            guard let juncture = overlapping ?? (sites.count == 1 && junctures.count == 1 ? junctures.first : nil) else { continue }
            used.insert(juncture.id)
            sites[index].caption = juncture.categoryCaption
            sites[index].note = juncture.note
            for reading in sites[index].readings.indices {
                let followed = sites[index].readings[reading].tags.lazy
                    .compactMap { variants.reading(in: juncture, followedBy: $0) }
                    .first
                sites[index].readings[reading].english = followed?.english ?? ""
                sites[index].readings[reading].transliteration = followed?.transliteration ?? ""
            }
        }
        return true
    }

    // MARK: Two riwayat

    /// The two sides at a place built for them, kept to the sites where they part ways.
    static func duel(a: String, b: String, place: QiraatPlace) -> QiraatDuelPlace {
        var kept: [QiraatSite] = []
        var aTint = QiraatTint.Spec()
        var bTint = QiraatTint.Spec()
        for site in place.sites {
            // A side that does not number this ayah is in no reading group, so it never parts ways.
            guard var readingA = site.reading(of: a), var readingB = site.reading(of: b),
                  readingA.id != readingB.id else { continue }
            readingA.tags = [a]
            readingB.tags = [b]
            // The riwayah first and Hafs's reading second: the emphasized reading is Hafs's words, so
            // the first side's letters are carried onto them (the way the Hafs card gets them).
            if readingB.readsAsHafs, !a.isEmpty, let sideA = place.side(a) {
                readingB.letters = hafsReadingLetters(site, from: sideA, hafsTokens: place.hafsTokens)
            }
            var pair = site
            pair.readings = [readingA, readingB]
            kept.append(pair)
            add(tint(a, against: b, in: site, place: place), to: &aTint)
            add(tint(b, against: a, in: site, place: place), to: &bTint)
        }
        return QiraatDuelPlace(a: a, b: b, place: place, sites: kept, aTint: normalized(aTint), bTint: normalized(bTint))
    }

    /// What `tag`'s text tints where it and `other` part ways at `site`: its own changed words, or,
    /// where it reads as Hafs, its words standing where `other` changes. The letters where they are
    /// exact: a side's print letters are measured from Hafs, so they are the letters that part from
    /// `other` only when `other` reads as Hafs there (and are then carried onto `other`'s words too);
    /// where both sides change the word, each keeps it whole.
    private static func tint(_ tag: String, against other: String, in site: QiraatSite, place: QiraatPlace) -> QiraatTint.Spec {
        var spec = QiraatTint.Spec()
        if !tag.isEmpty, let own = site.changedRiwayah[tag], !own.isEmpty {
            let otherReadsAsHafs = other.isEmpty || (site.reading(of: other)?.readsAsHafs ?? false)
            let change = place.side(tag)?.change
            for token in own {
                if otherReadsAsHafs, let change, let letters = ownLetters(change, token: token) {
                    spec.letters += letters
                } else {
                    spec.words.insert(token)
                }
            }
            return spec
        }
        let hafsWords = site.changedHafs[other] ?? []
        let otherSide = place.side(other)
        if tag.isEmpty {
            for h in hafsWords where place.hafsTokens.indices.contains(h) {
                if let letters = carriedLetters(from: otherSide, hafsToken: h, onto: place.hafsTokens[h], in: place.hafsText) {
                    spec.letters += letters
                } else {
                    spec.words.insert(h)
                }
            }
        } else if let change = place.side(tag)?.change {
            for h in hafsWords {
                guard let own = site.aligned[tag]?[h], change.diff.riwayah.indices.contains(own) else { continue }
                if let letters = carriedLetters(from: otherSide, hafsToken: h, onto: change.diff.riwayah[own], in: change.riwayahText) {
                    spec.letters += letters
                } else {
                    spec.words.insert(own)
                }
            }
        }
        return spec
    }

    // MARK: Letters

    /// The Hafs card's tint and each riwayah's: every changed word whole, or, for a riwayah whose
    /// print marks letters (`QiraatChange.hasPrintLetters`), the letters themselves: its own on its
    /// card, and on the Hafs card their counterparts in the Hafs word (`QiraatLetterDiff`, the same
    /// carrying the reader and the comparison sheet do). A Hafs word the riwayah has no word for, and
    /// a changed word its print leaves black, stay whole.
    static func tints(hafsText: String, hafsTokens: [QiraatWordDiff.Token], sides: [QiraatPlaceSide],
                      sites: [QiraatSite]) -> (hafs: QiraatTint.Spec, riwayah: [String: QiraatTint.Spec]) {
        var hafs = QiraatTint.Spec()
        var riwayah: [String: QiraatTint.Spec] = [:]
        for side in sides {
            guard let change = side.change else { continue }
            var own = QiraatTint.Spec()
            for site in sites {
                for h in site.changedHafs[side.tag] ?? [] where hafsTokens.indices.contains(h) {
                    if let letters = carriedLetters(from: side, hafsToken: h, onto: hafsTokens[h], in: hafsText) {
                        hafs.letters += letters
                    } else {
                        hafs.words.insert(h)
                    }
                }
                for token in site.changedRiwayah[side.tag] ?? [] {
                    if let letters = ownLetters(change, token: token) {
                        own.letters += letters
                    } else {
                        own.words.insert(token)
                    }
                }
            }
            if !own.isEmpty { riwayah[side.tag] = normalized(own) }
        }
        return (normalized(hafs), riwayah)
    }

    /// `change`'s letters inside its own word `token`, given as `word` (the token's text, or the
    /// reading's stop-sign-free copy of it; clusters are the same): the print's, or, where the print
    /// marks none, the letters the word and its Hafs counterpart disagree on. Nil when neither says
    /// anything (no print letters, or the two words agree letter for letter), which tints the word whole.
    private static func ownWordLetters(_ change: QiraatChange, token: Int, word: String) -> [NSRange]? {
        guard change.hasPrintLetters else { return nil }
        if let extents = change.riwayahLetters[token], !extents.isEmpty {
            let ranges = QiraatLetterDiff.ownLetterRanges(word: word, extents: extents)
            return ranges.isEmpty ? nil : ranges
        }
        guard let hafsToken = change.letterPairs.first(where: { $0.value == token })?.key,
              change.diff.hafs.indices.contains(hafsToken) else { return nil }
        let ranges = QiraatLetterDiff.wordDiffRanges(hafsWord: change.diff.hafs[hafsToken].text, riwayahWord: word).riwayah
        return ranges.isEmpty ? nil : ranges
    }

    /// `side`'s letters at the Hafs word `hafsToken` (local to the ayah) carried onto `hafsWord`,
    /// Hafs's own word (or a riwayah's that reads it as Hafs does, or the reading's stop-sign-free
    /// copy): the print's letters projected, or, where the print marks none, the letters the two
    /// words disagree on. Nil when the riwayah pairs no word with it or neither says anything.
    private static func carriedWordLetters(from side: QiraatPlaceSide?, hafsToken: Int, hafsWord: String) -> [NSRange]? {
        guard let side, let change = side.change, change.hasPrintLetters,
              let paired = change.letterPairs[hafsToken + side.hafsBase], change.diff.riwayah.indices.contains(paired)
        else { return nil }
        let riwayahWord = change.diff.riwayah[paired].text
        let ranges: [NSRange]
        if let extents = change.riwayahLetters[paired], !extents.isEmpty {
            ranges = QiraatLetterDiff.projectedRanges(hafsWord: hafsWord, riwayahWord: riwayahWord, extents: extents)
        } else {
            ranges = QiraatLetterDiff.wordDiffRanges(hafsWord: hafsWord, riwayahWord: riwayahWord).hafs
        }
        return ranges.isEmpty ? nil : ranges
    }

    /// `ownWordLetters` over the change's whole text.
    private static func ownLetters(_ change: QiraatChange, token: Int) -> [NSRange]? {
        guard change.diff.riwayah.indices.contains(token) else { return nil }
        let word = change.diff.riwayah[token]
        return ownWordLetters(change, token: token, word: word.text)
            .map { offset($0, by: word.range.lowerBound.utf16Offset(in: change.riwayahText)) }
    }

    /// `carriedWordLetters` onto `word` over `text`.
    private static func carriedLetters(from side: QiraatPlaceSide?, hafsToken: Int, onto word: QiraatWordDiff.Token,
                                       in text: String) -> [NSRange]? {
        carriedWordLetters(from: side, hafsToken: hafsToken, hafsWord: word.text)
            .map { offset($0, by: word.range.lowerBound.utf16Offset(in: text)) }
    }

    /// Hafs's reading of `site` with `side`'s letters carried onto it: the words as the reading
    /// shows them (`shown`, joined by spaces, the way `sites` built its text), each word the side
    /// changes with the carried letters, or whole where neither the print nor the words say which.
    private static func hafsReadingLetters(_ site: QiraatSite, from side: QiraatPlaceSide,
                                           hafsTokens: [QiraatWordDiff.Token]) -> [NSRange]? {
        guard side.change?.hasPrintLetters == true else { return nil }
        let changed = Set(site.changedHafs[side.tag] ?? [])
        var at = 0
        var letters: [NSRange] = []
        for h in site.range where hafsTokens.indices.contains(h) {
            let word = shown(hafsTokens[h].text)
            guard !word.isEmpty else { continue }
            if at > 0 { at += 1 }
            if changed.contains(h) {
                if let carried = carriedWordLetters(from: side, hafsToken: h, hafsWord: word) {
                    letters += offset(carried, by: at)
                } else {
                    letters.append(NSRange(location: at, length: word.utf16.count))
                }
            }
            at += word.utf16.count
        }
        return letters.isEmpty ? nil : letters
    }

    private static func offset(_ ranges: [NSRange], by base: Int) -> [NSRange] {
        ranges.map { NSRange(location: base + $0.location, length: $0.length) }
    }

    private static func add(_ spec: QiraatTint.Spec, to total: inout QiraatTint.Spec) {
        total.words.formUnion(spec.words)
        total.letters += spec.letters
    }

    /// The letter ranges sorted and merged (two riwayat marking one Hafs letter give it once), so
    /// equal tints compare equal and the card's layout is left alone.
    private static func normalized(_ spec: QiraatTint.Spec) -> QiraatTint.Spec {
        var merged: [NSRange] = []
        for range in spec.letters.sorted(by: { $0.location < $1.location }) {
            if let last = merged.last, range.location <= NSMaxRange(last) {
                merged[merged.count - 1] = NSRange(location: last.location, length: max(NSMaxRange(last), NSMaxRange(range)) - last.location)
            } else {
                merged.append(range)
            }
        }
        return QiraatTint.Spec(words: spec.words, letters: merged)
    }

    /// The Hafs ayahs of a surah where either side differs from Hafs under the tier: every place the
    /// two could part ways, from the place index alone.
    static func duelCandidates(surah: Int, a: String, b: String, everyDifference: Bool,
                               store: QiraatPlacesStore) -> [Int] {
        var union = Set<Int>()
        for tag in [a, b] where !tag.isEmpty {
            for (ayah, words) in store.placesOffMain(surah: surah, tag: tag)
            where QiraatPlacesStore.counts(words, everyDifference: everyDifference) {
                union.insert(ayah)
            }
        }
        return union.sorted()
    }

    /// Whether `a` and `b` read this Hafs ayah differently under the tier. The tier picks the words
    /// that count (a word-level change by either side); the place index then answers when one side
    /// differs there at all and the other reads it as Hafs. Where both differ at every counted word,
    /// only their texts can say whether to the same form (Warsh's print flags 2:10's يُكَذِّبُونَ at
    /// letter level, ad-Duri's at word level, and the two read it alike), so that answer is worked
    /// out once and cached.
    static func parts(surah: Int, ayah: Int, a: String, b: String, everyDifference: Bool,
                      store: QiraatPlacesStore, quranData: QuranData) async -> Bool {
        guard a != b, !QiraatProfiles.shareOneText(a, b) else { return false }
        func entry(_ tag: String) -> [Int]? {
            tag.isEmpty ? nil : store.placesOffMain(surah: surah, tag: tag)[ayah]
        }
        let entryA = entry(a)
        let entryB = entry(b)
        let countedA = entryA.map { QiraatPlacesStore.counts($0, everyDifference: everyDifference) } ?? false
        let countedB = entryB.map { QiraatPlacesStore.counts($0, everyDifference: everyDifference) } ?? false
        guard countedA || countedB else { return false }
        let anyA = Set(entryA.map { QiraatPlacesStore.wordIndices($0, everyDifference: true) } ?? [])
        let anyB = Set(entryB.map { QiraatPlacesStore.wordIndices($0, everyDifference: true) } ?? [])
        var counted = Set<Int>()
        if countedA, let entryA { counted.formUnion(QiraatPlacesStore.wordIndices(entryA, everyDifference: everyDifference)) }
        if countedB, let entryB { counted.formUnion(QiraatPlacesStore.wordIndices(entryB, everyDifference: everyDifference)) }
        if counted.contains(where: { anyA.contains($0) != anyB.contains($0) }) { return true }
        let cache = QiraatDuelPlacesCache.shared
        let key = QiraatDuelPlacesCache.key(surah: surah, ayah: ayah, a: a, b: b, everyDifference: everyDifference)
        if let verdict = cache.verdict(key) { return verdict }
        let place = await build(surah: surah, hafsAyah: ayah, tags: [a, b].filter { !$0.isEmpty },
                                everyDifference: everyDifference, quranData: quranData, annotate: false)
        let verdict = !duel(a: a, b: b, place: place).sites.isEmpty
        if !Task.isCancelled { cache.store(verdict: verdict, key) }
        return verdict
    }

    /// The Hafs ayahs of a surah where `a` and `b` read differently, under the tier: the caption's
    /// "place 3 of 12" and the place picker. Cached per surah and pair.
    static func duelAyahs(surah: Int, a: String, b: String, everyDifference: Bool,
                          store: QiraatPlacesStore, quranData: QuranData) async -> [Int] {
        let key = QiraatDuelPlacesCache.key(surah: surah, a: a, b: b, everyDifference: everyDifference)
        if let cached = QiraatDuelPlacesCache.shared.list(key) { return cached }
        var out: [Int] = []
        for ayah in duelCandidates(surah: surah, a: a, b: b, everyDifference: everyDifference, store: store) {
            if Task.isCancelled { return out }
            if await parts(surah: surah, ayah: ayah, a: a, b: b, everyDifference: everyDifference,
                           store: store, quranData: quranData) {
                out.append(ayah)
            }
        }
        guard !Task.isCancelled else { return out }
        QiraatDuelPlacesCache.shared.store(list: out, key)
        return out
    }

    /// The nearest place after (or before) an ayah where the two part ways, across surahs. Lazy: it
    /// checks the candidates in order and stops at the first, so a step never waits for a whole
    /// surah's list (a pair of one imam's narrators checks most of Al-Baqarah's 150 candidates).
    static func duelStep(from surah: Int, ayah: Int, forward: Bool, a: String, b: String, everyDifference: Bool,
                         store: QiraatPlacesStore, quranData: QuranData) async -> QiraatPlaceRef? {
        guard a != b, !QiraatProfiles.shareOneText(a, b) else { return nil }
        var current = surah
        var floor = ayah
        while (1...114).contains(current) {
            let listKey = QiraatDuelPlacesCache.key(surah: current, a: a, b: b, everyDifference: everyDifference)
            let known = QiraatDuelPlacesCache.shared.list(listKey)
            let pool = known ?? duelCandidates(surah: current, a: a, b: b, everyDifference: everyDifference, store: store)
            let ordered = forward ? pool.filter { $0 > floor } : pool.filter { $0 < floor }.reversed()
            for candidate in ordered {
                if Task.isCancelled { return nil }
                if known != nil {
                    return QiraatPlaceRef(surah: current, ayah: candidate)
                }
                if await parts(surah: current, ayah: candidate, a: a, b: b, everyDifference: everyDifference,
                               store: store, quranData: quranData) {
                    return QiraatPlaceRef(surah: current, ayah: candidate)
                }
            }
            current += forward ? 1 : -1
            floor = forward ? 0 : Int.max
        }
        return nil
    }
}

/// A place in the Quran by its Hafs number.
struct QiraatPlaceRef: Equatable, Hashable {
    let surah: Int
    let ayah: Int
}

/// Compare Two's findings, worked out off the main thread once each: per surah, pair and tier the
/// list of places, and per ayah whether two sides that change the same words change them alike.
final class QiraatDuelPlacesCache: @unchecked Sendable {
    static let shared = QiraatDuelPlacesCache()
    private init() {}

    private let lock = NSLock()
    private var lists: [String: [Int]] = [:]
    private var verdicts: [String: Bool] = [:]

    /// The pair is unordered: Hafs against Warsh and Warsh against Hafs part ways in the same places.
    static func key(surah: Int, ayah: Int? = nil, a: String, b: String, everyDifference: Bool) -> String {
        let pair = [Settings.Riwayah.canonicalTag(a), Settings.Riwayah.canonicalTag(b)].sorted()
        return "\(surah):\(ayah ?? 0)|\(pair[0])|\(pair[1])|\(everyDifference ? 1 : 0)"
    }

    func list(_ key: String) -> [Int]? {
        lock.lock(); defer { lock.unlock() }
        return lists[key]
    }

    func store(list: [Int], _ key: String) {
        lock.lock(); defer { lock.unlock() }
        lists[key] = list
    }

    func verdict(_ key: String) -> Bool? {
        lock.lock(); defer { lock.unlock() }
        return verdicts[key]
    }

    func store(verdict: Bool, _ key: String) {
        lock.lock(); defer { lock.unlock() }
        verdicts[key] = verdict
    }

    /// The beta gate changes which texts exist, and memory warnings want the space back.
    func purge() {
        lock.lock(); defer { lock.unlock() }
        lists.removeAll()
        verdicts.removeAll()
    }
}

// MARK: - Who reads it

enum QiraatReaderNames {
    /// "Nafi, Ibn Kathir, ad-Duri": an imam where every compared narrator of his reads alike (both,
    /// when both are compared), otherwise the narrators by name, in the classical order of the ten.
    /// `compared` is every riwayah on the screen, Hafs included. `display`: the names as the reader
    /// sees them (through the catalog); false keeps the English data.
    static func names(_ tags: [String], compared: Set<String>, display: Bool = false) -> [String] {
        let group = Set(tags.map(Settings.Riwayah.canonicalTag))
        let options = Settings.Riwayah.allOptions
        var out: [String] = []
        for teacher in classicalTeacherOrder {
            let narrators = options.filter { $0.teacher == teacher && compared.contains($0.tag) }
            let reading = narrators.filter { group.contains($0.tag) }
            guard !reading.isEmpty else { continue }
            if narrators.count == 2, reading.count == 2 {
                out.append(display ? teacher.localizedDisplay : teacher)
            } else {
                out.append(contentsOf: reading.map { narratorName($0.tag, compared: compared, display: display) })
            }
        }
        return out
    }

    /// The narrator's short name, with his imam when another compared narrator shares it (the two
    /// ad-Duris, of Abu Amr and of al-Kisai). The clash is found on the English names; `display`
    /// only changes what is returned.
    static func narratorName(_ tag: String, compared: Set<String>, display: Bool = false) -> String {
        let name = QiraatProfiles.shortName(of: tag)
        let clash = compared.contains { $0 != tag && QiraatProfiles.shortName(of: $0) == name }
        let teacher = Settings.Riwayah.option(for: tag).teacher
        guard display else { return clash ? "\(name) (\(teacher))" : name }
        return clash ? "\(name.localizedDisplay) (\(teacher.localizedDisplay))" : name.localizedDisplay
    }

    /// The ten in their classical order (the seven, then the three), not the menus' alphabetical one.
    static let classicalTeacherOrder: [String] = [
        Settings.Riwayah.nafiTeacher, Settings.Riwayah.ibnKathirTeacher, Settings.Riwayah.abiAmrTeacher,
        Settings.Riwayah.ibnAmirTeacher, Settings.Riwayah.asimTeacher, Settings.Riwayah.hamzahTeacher,
        Settings.Riwayah.kisaiTeacher, Settings.Riwayah.abiJafarTeacher, Settings.Riwayah.yaqubTeacher,
        Settings.Riwayah.khalafAshirTeacher,
    ]

    /// "Nafi, Ibn Kathir and ad-Duri". In Arabic the language's own list ("نافع وابن كثير"), never
    /// a Latin ", " between Arabic names.
    static func list(_ names: [String]) -> String {
        names.sentenceList { names in
            switch names.count {
            case 0: return ""
            case 1: return names[0]
            case 2: return String(localized: "\(names[0]) and \(names[1])")
            default: return String(localized: "\(names.dropLast().joined(separator: ", ")) and \(names.last ?? "")")
            }
        }
    }
}
#endif
