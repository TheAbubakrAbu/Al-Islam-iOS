#if os(iOS)
import SwiftUI
import Combine

// The study kit: what the Reading Test (Arabic Alphabet) and the Tajweed Test (Tajweed Course) share,
// so the two ladders look like one feature and like the course's own cards (Abu, 2026-10-25: "rework
// arabic test mode and make it better and more comprehensive and match the rest of the app. Add
// Tajweed test mode too for tajweed course").
//
// Here: the ladder's progress store (best score and attempts per tier, mastery, the placement Find My
// Level gave, the missed items kept for review, the Speed Round best), and the views a session is
// built from: the choice button, the hint chip, the full-width result button, the score card, the stage
// header, the tier row, the match-pairs board and the tap-a-word line. Nothing in here knows what a
// question is about: each test keeps its own model and its own session view.

// MARK: - Progress

/// One tier's record: how the scored test went, and the best practice round per skill.
struct StudyRecord: Codable, Equatable {
    /// Best scored test, as right answers out of a hundred.
    var best = 0
    var attempts = 0
    /// A pass with no hint used and nothing missed.
    var mastered = false
    var lastPlayed: Date? = nil
    /// Practice rounds, which never count against the tier: the best round per skill, out of a hundred.
    var skillBest: [String: Int] = [:]

    var passed: Bool { best >= StudyLadderProgress.passMark }

    init(best: Int = 0, attempts: Int = 0, mastered: Bool = false, lastPlayed: Date? = nil, skillBest: [String: Int] = [:]) {
        self.best = best
        self.attempts = attempts
        self.mastered = mastered
        self.lastPlayed = lastPlayed
        self.skillBest = skillBest
    }

    private enum CodingKeys: String, CodingKey { case best, attempts, mastered, lastPlayed, skillBest }

    /// `skillBest` arrived on 2026-10-25; the records already on disk (and in iCloud backups) have no
    /// such field, so it is read as empty rather than failing the whole ladder.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        best = try container.decodeIfPresent(Int.self, forKey: .best) ?? 0
        attempts = try container.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
        mastered = try container.decodeIfPresent(Bool.self, forKey: .mastered) ?? false
        lastPlayed = try container.decodeIfPresent(Date.self, forKey: .lastPlayed)
        skillBest = try container.decodeIfPresent([String: Int].self, forKey: .skillBest) ?? [:]
    }
}

/// Something missed in a scored test, kept so it can be practised again. `id` is whatever the test
/// needs to rebuild the question (a word, a lesson and a source).
struct StudyMissedItem: Codable, Equatable, Identifiable {
    let id: String
    let tier: String
    var count: Int
    var last: Date
}

/// A ladder's progress. Small, in UserDefaults, like `TajweedLessonProgress`. One subclass per test
/// (`ReadingTestProgress`, `TajweedTestProgress`) names its keys and types its tiers.
class StudyLadderProgress: ObservableObject {
    /// Eight in ten passes a tier.
    static let passMark = 80
    /// How many missed items are kept: the review round draws from the newest.
    static let missedCap = 60

    let key: String
    let placementKey: String
    let missedKey: String
    let speedKey: String

    @Published private(set) var records: [String: StudyRecord]
    /// The tier Find My Level last sent the learner to, if they have taken it.
    @Published private(set) var placement: String?
    /// What scored tests missed, newest first.
    @Published private(set) var missed: [StudyMissedItem]
    /// The most right answers in one Speed Round.
    @Published private(set) var speedBest: Int

    /// True once this object has something on disk, so the wipe check below never clears a ladder
    /// that was only ever in memory (the DEBUG seed).
    private var hasSaved = false
    private var defaultsObserver: NSObjectProtocol?
    private var storageObserver: StoredContentObserver?

    init(key: String, placementKey: String, missedKey: String, speedKey: String) {
        self.key = key
        self.placementKey = placementKey
        self.missedKey = missedKey
        self.speedKey = speedKey
        let defaults = UserDefaults.standard
        let storedRecords = defaults.data(forKey: key).flatMap {
            UserDataRescue.decode([String: StudyRecord].self, from: $0, key: key, defaults: defaults)
        }
        let storedPlacement = defaults.string(forKey: placementKey)
        let storedMissed = defaults.data(forKey: missedKey).flatMap {
            UserDataRescue.decodeList(StudyMissedItem.self, from: $0, key: missedKey, defaults: defaults)
        }
        records = storedRecords ?? [:]
        placement = storedPlacement
        missed = storedMissed ?? []
        speedBest = defaults.integer(forKey: speedKey)
        hasSaved = storedRecords != nil || storedPlacement != nil || storedMissed != nil

        // "Erase Everything" removes the whole defaults domain while this object still holds the
        // ladder. Settings.swift compiles into targets this file is not in, so it cannot call in
        // here: notice the keys going instead.
        // `queue: nil` (deliver on the posting thread), NOT `queue: .main`. A main-queue observer
        // of an app-wide notification makes every background post BLOCK on the main thread:
        // NotificationCenter delivers through an NSOperation and waits for it. `UserDefaults.set`
        // posts this notification, and the stores write defaults on their own io queues, so a
        // main-queue observer here put a main-thread hop inside every one of those writes - one
        // half of a deadlock that froze and then killed the app on Mac (2026-10-05, see
        // [[viewedlog-ioqueue-deadlock]]). The work below is a few defaults reads and a decision; it
        // needs no main thread, and the published properties are set on main explicitly.
        let keys = [key, placementKey, missedKey]
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: nil
        ) { [weak self] _ in
            guard let self, self.hasSaved,
                  keys.allSatisfy({ UserDefaults.standard.object(forKey: $0) == nil }) else { return }
            // Observed by views, so they change on main - asynchronously, because the poster may BE
            // the main thread (an erase runs there) and a sync hop would deadlock on itself.
            DispatchQueue.main.async {
                self.hasSaved = false
                if !self.records.isEmpty { self.records = [:] }
                if self.placement != nil { self.placement = nil }
                if !self.missed.isEmpty { self.missed = [] }
                if self.speedBest != 0 { self.speedBest = 0 }
            }
        }
        // The observer above only notices the keys GOING (an erase). A restore writes them, which
        // it cannot tell from this object's own save, so that case is announced instead.
        storageObserver = StoredContentObserver(reload: { [weak self] in self?.reloadFromStorage() })
    }

    /// The ladder on disk changed underneath this object (a restore): take it.
    private func reloadFromStorage() {
        let defaults = UserDefaults.standard
        let stored = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode([String: StudyRecord].self, from: $0) }
        let storedPlacement = defaults.string(forKey: placementKey)
        let storedMissed = defaults.data(forKey: missedKey).flatMap { try? JSONDecoder().decode([StudyMissedItem].self, from: $0) } ?? []
        let storedSpeed = defaults.integer(forKey: speedKey)
        hasSaved = stored != nil || storedPlacement != nil || !storedMissed.isEmpty
        if records != stored ?? [:] { records = stored ?? [:] }
        if placement != storedPlacement { placement = storedPlacement }
        if missed != storedMissed { missed = storedMissed }
        if speedBest != storedSpeed { speedBest = storedSpeed }
    }

    // MARK: Reading

    func record(id: String) -> StudyRecord { records[id] ?? StudyRecord() }

    func passedCount(in ids: [String]) -> Int { ids.filter { record(id: $0).passed }.count }

    func masteredCount(in ids: [String]) -> Int { ids.filter { record(id: $0).mastered }.count }

    /// Where to go next: the first tier not yet passed, from the placement tier on when there is one.
    func nextID(in ids: [String]) -> String? {
        let start = placement.flatMap { id in ids.firstIndex(of: id) } ?? 0
        guard ids.indices.contains(start) else { return ids.first { !record(id: $0).passed } }
        return ids[start...].first { !record(id: $0).passed } ?? ids.first { !record(id: $0).passed }
    }

    /// The missed items of these tiers, newest first.
    func missed(in ids: [String]) -> [StudyMissedItem] {
        let wanted = Set(ids)
        return missed.filter { wanted.contains($0.tier) }
    }

    // MARK: Writing

    /// Files a finished scored test. `hints` and `missedIDs` decide mastery; the best score only ever
    /// rises; what was missed joins the review bank, and what was answered right leaves it.
    func finish(id: String, right: Int, of total: Int, hints: Int, missedIDs: [String], rightIDs: [String] = []) {
        guard total > 0 else { return }
        var record = record(id: id)
        let score = Int((Double(right) / Double(total) * 100).rounded())
        record.best = max(record.best, score)
        record.attempts += 1
        record.lastPlayed = Date()
        if right == total, hints == 0 { record.mastered = true }
        records[id] = record
        noteMissed(missedIDs, tier: id)
        if !rightIDs.isEmpty { forgetMissed(rightIDs, tier: id) }
        save()
    }

    /// Files a practice round: the skill's best only ever rises. Not scored against the tier.
    func recordPractice(id: String, skill: String, right: Int, of total: Int) {
        guard total > 0 else { return }
        var record = record(id: id)
        let score = Int((Double(right) / Double(total) * 100).rounded())
        if score > record.skillBest[skill] ?? -1 {
            record.skillBest[skill] = score
            records[id] = record
            save()
        }
    }

    /// Files a Speed Round: the best only ever rises.
    func recordSpeed(right: Int) {
        guard right > speedBest else { return }
        speedBest = right
        hasSaved = true
        UserDefaults.standard.set(right, forKey: speedKey)
    }

    /// A review round over the missed bank: what was answered right leaves the bank, what was missed
    /// again moves to the front.
    func finishReview(missedIDs: [(id: String, tier: String)], rightIDs: [(id: String, tier: String)]) {
        for (id, tier) in missedIDs { noteMissed([id], tier: tier) }
        for (id, tier) in rightIDs { forgetMissed([id], tier: tier) }
        save()
    }

    private func noteMissed(_ ids: [String], tier: String) {
        guard !ids.isEmpty else { return }
        let now = Date()
        var bank = missed
        for id in ids {
            if let index = bank.firstIndex(where: { $0.id == id && $0.tier == tier }) {
                var entry = bank.remove(at: index)
                entry.count += 1
                entry.last = now
                bank.insert(entry, at: 0)
            } else {
                bank.insert(StudyMissedItem(id: id, tier: tier, count: 1, last: now), at: 0)
            }
        }
        if bank.count > Self.missedCap { bank.removeLast(bank.count - Self.missedCap) }
        missed = bank
    }

    private func forgetMissed(_ ids: [String], tier: String) {
        let gone = Set(ids)
        let kept = missed.filter { !($0.tier == tier && gone.contains($0.id)) }
        if kept.count != missed.count { missed = kept }
    }

    func setPlacement(id: String) {
        placement = id
        hasSaved = true
        UserDefaults.standard.set(id, forKey: placementKey)
    }

    func reset() {
        hasSaved = false
        records = [:]
        placement = nil
        missed = []
        speedBest = 0
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: placementKey)
        defaults.removeObject(forKey: missedKey)
        defaults.removeObject(forKey: speedKey)
    }

    private func save() {
        hasSaved = true
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(records) { defaults.set(data, forKey: key) }
        if missed.isEmpty {
            defaults.removeObject(forKey: missedKey)
        } else if let data = try? JSONEncoder().encode(missed) {
            defaults.set(data, forKey: missedKey)
        }
    }

    #if DEBUG
    /// Marks the first `count` of `ids` passed (every third mastered), for a screenshot of a ladder
    /// in use. Nothing is written to disk.
    func debugSeed(passed count: Int, in ids: [String]) {
        for (index, id) in ids.enumerated() where index < count {
            records[id] = StudyRecord(best: index % 3 == 0 ? 100 : 90, attempts: 2, mastered: index % 3 == 0, lastPlayed: Date())
        }
    }
    #endif
}

// MARK: - Sessions

/// How a scored round ends. Shared by both sessions' result cards.
enum StudyOutcome {
    case mastered, passed, failed

    var title: String {
        switch self {
        case .mastered: return String(localized: "Mastered")
        case .passed: return String(localized: "Passed")
        case .failed: return String(localized: "Not passed yet")
        }
    }

    var systemImage: String {
        switch self {
        case .mastered: return "checkmark.seal.fill"
        case .passed: return "checkmark.circle.fill"
        case .failed: return "arrow.clockwise.circle"
        }
    }
}

/// How a choice draws once the question is answered.
enum StudyChoiceState {
    /// Not answered yet.
    case idle
    /// The right answer, shown whether or not it was picked.
    case right
    /// The wrong one that was picked.
    case wrong
    /// A wrong one that was not picked: faded.
    case faded

    init(answered: Bool, isAnswer: Bool, picked: Bool) {
        if !answered { self = .idle } else if isAnswer { self = .right } else if picked { self = .wrong } else { self = .faded }
    }
}

/// Speed Round: how long one lasts.
enum StudySpeed {
    static let seconds = 60
}

// MARK: - Shared text

/// Arabic in the Islam tab's face, or in the plain system face for anything printed without marks (a
/// mushaf face draws a final yaa without its dots, and a bare, dotless yaa spells something else).
struct StudyArabicText: View {
    @Environment(\.appearance) private var appearance

    let text: String
    let base: CGFloat
    let style: Font.TextStyle
    var plain = false

    var body: some View {
        let custom = appearance.useFontArabic && !plain
        Text(text)
            .font(custom ? appearance.islamArabicFont(base: base, relativeTo: style) : .system(size: base * 0.9))
            .arabicFontDesign(custom: custom && appearance.islamUsesCustomArabicFace)
    }
}

/// An icon and a title side by side. Not a `Label`: inside a List row a Label's icon is given a column
/// of its own (so that titles line up down the list), which opens a wide gap in a button or a capsule.
struct StudyIconText: View {
    let title: String
    let systemImage: String

    init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)

            Text(title)
        }
    }
}

// MARK: - Buttons

/// One answer of a multiple-choice question: a rounded tile that takes the answer's colour once the
/// question is settled. The label is whatever the test draws (Arabic in its face, a reading, a word).
struct StudyChoiceButton<Label: View>: View {
    @Environment(\.appearance) private var appearance

    let state: StudyChoiceState
    /// A long answer (an ayah, a sentence) draws in one column with a lower tile.
    var long = false
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        let accent = appearance.accent
        let stroke: Color = state == .right ? .green : state == .wrong ? .red : .clear

        Button {
            guard state == .idle else { return }
            Settings.shared.hapticFeedback()
            action()
        } label: {
            label()
                .multilineTextAlignment(.center)
                .lineLimit(long ? 4 : 1)
                .minimumScaleFactor(0.45)
                .frame(maxWidth: .infinity, minHeight: long ? 52 : 64)
                .padding(.horizontal, 8)
                .padding(.vertical, long ? 8 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.opacity(state == .right ? 0.18 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(stroke, lineWidth: 2)
                )
                .opacity(state == .faded ? 0.45 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A full-width row button on a results or tier page: filled in the accent when prominent, washed
/// otherwise. Result buttons in a Section need the separator hidden or stray hairlines cut between them.
struct StudyResultButton: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let systemImage: String
    var prominent = false
    let action: () -> Void

    var body: some View {
        let accent = appearance.accent
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            StudyIconText(title, systemImage: systemImage)
                .font(.body.weight(.semibold))
                .foregroundColor(prominent ? .white : accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(prominent ? accent : accent.opacity(0.12))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
    }
}

/// The "Next" / "See Results" button under an answered question: glass, in the accent.
struct StudyAdvanceButton: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundColor(appearance.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .conditionalGlassEffect(rectangle: true)
        }
        .buttonStyle(.plain)
    }
}

/// A hint, as a capsule under the question.
struct StudyHintChip: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        let accent = appearance.accent
        Button {
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) { action() }
        } label: {
            StudyIconText(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundColor(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(accent.opacity(0.12)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Undo, Clear, Check: the small controls of a hands-on question, in one row.
struct StudyControlButton: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let systemImage: String
    var enabled = true
    var filled = false
    let action: () -> Void

    var body: some View {
        let accent = appearance.accent
        Button {
            guard enabled else { return }
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.15)) { action() }
        } label: {
            StudyIconText(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(filled ? .white : accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(filled ? accent : accent.opacity(0.12))
                )
                .opacity(enabled ? 1 : 0.4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A round speaker that says `text` in the device's Arabic voice; louder while it is speaking.
struct StudySpeakerButton: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var speech = ArabicSpeech.shared

    let text: String
    var size: CGFloat = 44

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            speech.speak(text)
        } label: {
            Image(systemName: speech.currentText == text ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(appearance.accent)
                .frame(width: size, height: size)
                .background(Circle().fill(appearance.accent.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Hear it")
    }
}

/// The two small buttons of a hero's footer: Start/Continue and Find My Level.
struct StudyHeroButton: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let systemImage: String
    var filled = false
    let action: () -> Void

    var body: some View {
        let accent = appearance.accent
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundColor(filled ? .white : accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(filled ? accent : accent.opacity(0.12))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Headers and rows

/// A stage of a ladder, as the course heads its stages: the symbol and the title in heavy type, the
/// Arabic name in the accent beside them, and what the stage covers under them.
struct StudyStageHeader: View {
    @Environment(\.appearance) private var appearance

    let systemImage: String
    let title: String
    var arabic: String? = nil
    var blurb: String? = nil
    /// The symbol's colour where the stage wears one of its own (a tajweed lesson's rule colour);
    /// nil is the accent. `TajweedLessonHeader` is this header with its colour set.
    var tint: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(tint ?? appearance.accent)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.headline.weight(.heavy))
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 8)

                if let arabic, !arabic.isEmpty {
                    StudyArabicText(text: arabic, base: 17, style: .body)
                        .foregroundColor(appearance.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }

            if let blurb, !blurb.isEmpty {
                Text(blurb)
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .textCase(nil)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

/// A plain uppercase section title with an icon: the smaller sections of a test page (REVIEW, MORE,
/// THE TEST), in the List's own header grey.
struct StudySectionHeader: View {
    let title: String
    let systemImage: String

    init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .accessibilityHidden(true)
            Text(title)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

/// One tier on a ladder: its number, a glyph or a symbol, its name in both languages, one line about
/// it, and where the learner stands.
struct StudyTierRow: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.layoutDirection) private var layoutDirection

    let number: Int
    /// The Arabic glyph in the tile, or nil to draw `systemImage` instead.
    var specimen: String? = nil
    var specimenPlain = false
    var systemImage: String = "target"
    /// The tile's colour: the accent, or a rule's colour where the tier wears one.
    var tint: Color? = nil
    let title: String
    var arabic: String? = nil
    let summary: String
    let record: StudyRecord
    let isNext: Bool

    var body: some View {
        let accent = tint ?? appearance.accent
        HStack(alignment: .center, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let specimen {
                        StudyArabicText(text: specimen, base: 22, style: .title2, plain: specimenPlain)
                            .lineLimit(1)
                            .minimumScaleFactor(0.35)
                            .padding(.horizontal, 3)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 19, weight: .semibold))
                    }
                }
                .foregroundColor(accent)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(isNext ? 0.22 : 0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isNext ? accent : .clear, lineWidth: 1.5)
                )

                Text("\(number)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Circle().fill(accent))
                    // Out past the tile's trailing corner, whichever side that is.
                    .offset(x: layoutDirection == .rightToLeft ? -5 : 5, y: 5)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let arabic, !arabic.isEmpty {
                    Text(arabic)
                        .font(.caption)
                        .foregroundColor(accent.opacity(0.9))
                        .lineLimit(1)
                }

                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            StudyRecordBadge(record: record, isNext: isNext, tint: accent)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tier \(number), \(title). \(summary). \(StudyRecordBadge.label(record, isNext: isNext))")
    }
}

/// A tier's standing, at the end of its row: a seal for mastered, a check for passed, the best score
/// after a failed attempt, NEXT for the tier the ladder points at.
struct StudyRecordBadge: View {
    @Environment(\.appearance) private var appearance

    let record: StudyRecord
    let isNext: Bool
    var tint: Color? = nil

    static func label(_ record: StudyRecord, isNext: Bool) -> String {
        if record.mastered { return String(localized: "Mastered") }
        if record.passed { return String(localized: "Passed, best \(record.best) percent") }
        if record.attempts > 0 { return String(localized: "Best \(record.best) percent") }
        return isNext ? String(localized: "Up next") : String(localized: "Not started")
    }

    var body: some View {
        let accent = tint ?? appearance.accent
        if record.mastered {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundColor(accent)
        } else if record.passed {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(accent)
        } else if record.attempts > 0 {
            Text("\(record.best)%")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
        } else if isNext {
            Text("NEXT")
                .font(.caption2.weight(.bold))
                .foregroundColor(accent)
        }
    }
}

/// A row that starts something: an icon chip, a title, a caption, and a play symbol at the end. The
/// REVIEW rows of a ladder and the PRACTICE ONE SKILL rows of a tier page.
struct StudyActionRow: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let systemImage: String
    let caption: String
    /// A small figure at the end, before the play symbol: a practice best, a count.
    var detail: String? = nil
    var tint: Color? = nil
    var trailingSymbol: String? = "play.circle.fill"
    let action: () -> Void

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            action()
        } label: {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: systemImage, tint: tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(tint ?? .primary)

                    Text(caption)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if let detail {
                    Text(detail)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }

                if let trailingSymbol {
                    Image(systemName: trailingSymbol)
                        .font(.title3)
                        .foregroundColor(tint ?? appearance.accent)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The header over a question: QUESTION n OF N (or a tier's name during Find My Level), the streak
/// when there is one, and the clock during a Speed Round.
struct StudyQuestionHeader: View {
    @Environment(\.appearance) private var appearance

    let title: String
    var streak = 0
    var secondsLeft: Int? = nil

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            if let secondsLeft {
                StudyIconText(String(localized: "\(secondsLeft) s"), systemImage: "timer")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundColor(secondsLeft <= 10 ? .red : appearance.accent)
                    .textCase(nil)
            } else if streak > 1 {
                StudyIconText(String(localized: "\(streak) in a row"), systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .textCase(nil)
            }
        }
    }
}

/// The right-or-wrong line that opens a question's feedback.
struct StudyVerdictLine: View {
    let wasRight: Bool
    var hinted = false

    var body: some View {
        StudyIconText(wasRight ? (hinted ? String(localized: "Right, with a hint") : String(localized: "Right")) : String(localized: "Not quite"),
                      systemImage: wasRight ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(wasRight ? .green : .red)
    }
}

/// The top of a results page: the score set large, the outcome, a sentence about it, the hints used.
struct StudyScoreCard: View {
    @Environment(\.appearance) private var appearance

    let right: Int
    let total: Int
    /// nil for a round that is not scored against a tier (practice, review).
    var outcome: StudyOutcome? = nil
    let message: String
    var hints = 0
    /// A Speed Round shows its best instead of "n of N".
    var speedBest: Int? = nil

    var body: some View {
        let accent = appearance.accent
        VStack(spacing: 8) {
            if speedBest != nil {
                Text("\(right)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(accent)

                Text(right == 1 ? String(localized: "1 right in \(StudySpeed.seconds) seconds") : String(localized: "\(right) right in \(StudySpeed.seconds) seconds"))
                    .font(.headline)
                    .foregroundColor(accent)
            } else {
                Text("\(right) of \(total)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
            }

            if let outcome {
                StudyIconText(outcome.title, systemImage: outcome.systemImage)
                    .font(.headline)
                    .foregroundColor(outcome == .failed ? .secondary : accent)
            }

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let speedBest, speedBest > 0 {
                StudyIconText(String(localized: "Best so far: \(speedBest)"), systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(accent)
            }

            if hints > 0 {
                StudyIconText(hints == 1 ? String(localized: "1 answer used a hint") : String(localized: "\(hints) answers used a hint"), systemImage: "lightbulb")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .listRowSeparator(.hidden)
    }

    /// The sentence under a scored round's outcome, the same on both ladders.
    static func message(right: Int, total: Int, outcome: StudyOutcome?, passMark: Int) -> String {
        switch outcome {
        case .mastered: return String(localized: "Every answer right, and no hints. This tier is yours.")
        case .passed:
            return right == total ? String(localized: "Every answer right. Do it once more without a hint to master the tier.")
                : String(localized: "That is a pass. The ones you missed are below.")
        case .failed: return String(localized: "\(passMark)% passes. Look at the ones you missed, practise that skill on its own, and take it again.")
        case nil:
            return right == total ? String(localized: "Every one right.") : String(localized: "Look at the ones you missed, then go again.")
        }
    }
}

// MARK: - Match pairs

/// Two columns to pair up: tap one on each side. A right pair locks in the accent, a wrong pair flashes
/// red and comes apart. Finished when every pair is made; `onFinish` hears how many wrong pairs it took.
struct StudyMatchBoard<Left: View, Right: View>: View {
    @Environment(\.appearance) private var appearance

    struct Pair: Identifiable {
        let id: Int
        /// Where this pair's halves sit in the two shuffled columns.
        let leftSlot: Int
        let rightSlot: Int
    }

    let pairs: [Pair]
    let finished: Bool
    let onFinish: (Int) -> Void
    @ViewBuilder let left: (Int) -> Left
    @ViewBuilder let right: (Int) -> Right

    @State private var pickedLeft: Int?
    @State private var pickedRight: Int?
    @State private var locked: Set<Int> = []
    @State private var wrongFlash: (left: Int, right: Int)?
    @State private var wrongCount = 0

    private var slotCount: Int { pairs.count }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 8) {
                ForEach(0..<slotCount, id: \.self) { slot in
                    tile(side: .left, slot: slot) { left(slot) }
                }
            }
            VStack(spacing: 8) {
                ForEach(0..<slotCount, id: \.self) { slot in
                    tile(side: .right, slot: slot) { right(slot) }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private enum Side { case left, right }

    private func pair(side: Side, slot: Int) -> Pair? {
        pairs.first { side == .left ? $0.leftSlot == slot : $0.rightSlot == slot }
    }

    private func tile<Content: View>(side: Side, slot: Int, @ViewBuilder content: () -> Content) -> some View {
        let accent = appearance.accent
        let isLocked = pair(side: side, slot: slot).map { locked.contains($0.id) } ?? false
        let isPicked = side == .left ? pickedLeft == slot : pickedRight == slot
        let isFlashing = side == .left ? wrongFlash?.left == slot : wrongFlash?.right == slot
        let stroke: Color = isFlashing ? .red : isLocked ? .green : isPicked ? accent : .clear

        return Button {
            guard !isLocked, !finished, wrongFlash == nil else { return }
            Settings.shared.hapticFeedback()
            pick(side: side, slot: slot)
        } label: {
            content()
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.45)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.opacity(isLocked ? 0.18 : isPicked ? 0.14 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(stroke, lineWidth: 2)
                )
                .opacity(isLocked && !finished ? 0.7 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isPicked ? .isSelected : [])
    }

    private func pick(side: Side, slot: Int) {
        switch side {
        case .left: pickedLeft = pickedLeft == slot ? nil : slot
        case .right: pickedRight = pickedRight == slot ? nil : slot
        }
        guard let leftSlot = pickedLeft, let rightSlot = pickedRight else { return }
        let leftPair = pair(side: .left, slot: leftSlot)
        let rightPair = pair(side: .right, slot: rightSlot)
        if let leftPair, leftPair.id == rightPair?.id {
            withAnimation(.easeInOut(duration: 0.2)) { locked.insert(leftPair.id) }
            pickedLeft = nil
            pickedRight = nil
            if locked.count == pairs.count { onFinish(wrongCount) }
        } else {
            wrongCount += 1
            withAnimation(.easeInOut(duration: 0.15)) { wrongFlash = (leftSlot, rightSlot) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    wrongFlash = nil
                    pickedLeft = nil
                    pickedRight = nil
                }
            }
        }
    }
}

// MARK: - Tap a word

/// An ayah (or a phrase) laid out word by word, from the right, each word a tile to tap. Once answered,
/// the right words show green, the tapped wrong one red, the rest fade.
struct StudyWordTapLine: View {
    @Environment(\.appearance) private var appearance

    let words: [String]
    let rightWords: Set<Int>
    /// The word tapped, nil until answered.
    let picked: Int?
    let fontName: String
    let size: CGFloat
    let onPick: (Int) -> Void

    var body: some View {
        let accent = appearance.accent
        FlowLayoutView(spacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                let answered = picked != nil
                let isRight = rightWords.contains(index)
                let isWrongPick = answered && picked == index && !isRight
                let stroke: Color = !answered ? .clear : isRight ? .green : isWrongPick ? .red : .clear
                Button {
                    guard picked == nil else { return }
                    Settings.shared.hapticFeedback()
                    onPick(index)
                } label: {
                    Text(word)
                        .font(.custom(fontName, size: size))
                        .arabicFontDesign(custom: true)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .frame(minWidth: 46, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(accent.opacity(answered && isRight ? 0.18 : 0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(stroke, lineWidth: 2)
                        )
                        .opacity(answered && !isRight && !isWrongPick ? 0.45 : 1)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(word)
            }
        }
        .frame(maxWidth: .infinity)
        // Read from the right, as the ayah is, in either interface.
        .environment(\.layoutDirection, .rightToLeft)
    }
}
#endif
