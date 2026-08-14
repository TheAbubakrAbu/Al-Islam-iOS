import SwiftUI

#if os(iOS)

// Guided dua sessions - the collection screens read as a reference list, which is right for looking
// something up and wrong for actually SAYING them. A session takes one collection and walks it a
// supplication at a time, full screen, with a tally for the ones meant to be repeated.
//
// What this deliberately does NOT do: invent repeat counts. Al-Islam's dua corpus carries the Arabic,
// the transliteration, the translation, and the source - no authored "say this 33 times", because that
// number belongs to the narration and is not recorded per-item here. So the target is the user's to
// set (1 by default, with the counts the Sunnah actually uses as quick picks), and the app never
// asserts a number the source didn't give it.

// MARK: - Resume state

/// Where each collection was left off, so reopening a session continues rather than restarting.
/// Keyed by the collection's title (its own `id`), which is stable across launches.
///
/// The tally is NOT stored: a count belongs to a sitting. Resuming tomorrow at dua 7 is helpful;
/// resuming at "you were 19 of 33 through this tasbih" is a claim about an act of worship that the
/// app has no business making on the user's behalf.
@MainActor
final class DuaSessionProgress: ObservableObject {
    static let shared = DuaSessionProgress()

    private static let storageKey = "duaSessionProgressData"

    @Published private var positions: [String: Int] {
        didSet {
            guard let data = try? JSONEncoder().encode(positions) else { return }
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private init() {
        let data = UserDefaults.standard.data(forKey: Self.storageKey) ?? Data()
        positions = (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
    }

    /// The saved position, clamped to the collection as it exists NOW - a content update that shortens
    /// a collection must not resume past its end.
    func position(for collection: DuaCollection) -> Int {
        guard let saved = positions[collection.id] else { return 0 }
        return min(max(0, saved), max(0, collection.items.count - 1))
    }

    func isStarted(_ collection: DuaCollection) -> Bool {
        (positions[collection.id] ?? 0) > 0
    }

    func record(_ index: Int, for collection: DuaCollection) {
        positions[collection.id] = index
    }

    func clear(_ collection: DuaCollection) {
        positions.removeValue(forKey: collection.id)
    }
}

// MARK: - Entry point

/// The button that starts (or resumes) a session, shown at the top of a collection screen.
struct DuaSessionStartButton: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var progress = DuaSessionProgress.shared
    @State private var showingSession = false

    let collection: DuaCollection

    var body: some View {
        let resumeIndex = progress.position(for: collection)
        let resuming = progress.isStarted(collection)

        Button {
            settings.hapticFeedback()
            showingSession = true
        } label: {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: resuming ? "play.circle.fill" : "play.fill", size: 30)

                VStack(alignment: .leading, spacing: 1) {
                    Text(resuming ? "Resume Session" : "Start Session")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(resuming
                         ? "Continue at \(resumeIndex + 1) of \(collection.items.count)"
                         : "Go through all \(collection.items.count) one at a time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingSession) {
            DuaSessionView(collection: collection)
        }
    }
}

// MARK: - Session

struct DuaSessionView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var progress = DuaSessionProgress.shared
    @ObservedObject private var speech = ArabicSpeech.shared
    @Environment(\.dismiss) private var dismiss

    let collection: DuaCollection

    @State private var index = 0
    /// The tally for the CURRENT dua only - moving on resets it (see the note on `DuaSessionProgress`).
    @State private var count = 0
    @State private var target = 1
    @State private var finished = false
    /// Invalidates the delayed auto-advance. `tapCount` schedules its advance 0.45s out so the full
    /// ring is seen; if the user taps Next (or Back, or Restart) inside that window, the stale closure
    /// would land on the NEXT dua - where a fresh count of 1 against the default target of 1 satisfies
    /// its `count >= target` re-check and double-advances, silently skipping a supplication. Every
    /// movement bumps the generation; a pending closure from an older generation is a no-op.
    @State private var advanceGeneration = 0

    /// The counts the Sunnah actually uses, offered as quick picks rather than asserted per dua.
    private static let targetChoices = [1, 3, 7, 10, 33, 100]

    private var item: DuaItem? {
        collection.items.indices.contains(index) ? collection.items[index] : nil
    }

    private var isLast: Bool { index >= collection.items.count - 1 }

    // MARK: Movement

    private func advance() {
        advanceGeneration += 1
        speech.stop()
        guard !isLast else {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { finished = true }
            // A completed pass starts clean next time rather than resuming at the last item.
            progress.clear(collection)
            return
        }
        settings.hapticFeedback()
        withAnimation(.easeInOut) {
            index += 1
            count = 0
            target = 1
        }
        progress.record(index, for: collection)
    }

    private func goBack() {
        guard index > 0 else { return }
        advanceGeneration += 1
        settings.hapticFeedback()
        speech.stop()
        withAnimation(.easeInOut) {
            index -= 1
            count = 0
            target = 1
        }
        progress.record(index, for: collection)
    }

    private func tapCount() {
        guard count < target else { return }
        settings.hapticFeedback()
        count += 1
        // Hitting the target advances on its own - the point of setting one is not having to watch it.
        // Deferred a beat so the full ring is actually seen; the generation guard keeps the deferred
        // closure from acting after any other movement (see `advanceGeneration`).
        if count >= target {
            let generation = advanceGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard generation == advanceGeneration, count >= target, !finished else { return }
                advance()
            }
        }
    }

    // MARK: Body

    var body: some View {
        NavigationView {
            Group {
                if finished {
                    completionView
                } else if let item {
                    sessionBody(item)
                } else {
                    // A collection with no items can't be walked; say so rather than showing a blank
                    // card with dead controls.
                    ContentUnavailableFallback(
                        title: "Nothing to read",
                        message: "This collection has no supplications yet."
                    )
                }
            }
            .navigationTitle(collection.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        settings.hapticFeedback()
                        speech.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close the session")
                }
            }
            .accentWashedBackground()
        }
        .navigationViewStyle(.stack)
        .onAppear {
            index = progress.position(for: collection)
        }
        .onDisappear {
            speech.stop()
        }
    }

    private func sessionBody(_ item: DuaItem) -> some View {
        VStack(spacing: 0) {
            progressHeader

            ScrollView {
                VStack(spacing: 18) {
                    duaCard(item)
                    counterRing
                    targetPicker
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 18)
            }

            controls(item)
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(index + 1) of \(collection.items.count)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()

                if index > 0 {
                    Button {
                        settings.hapticFeedback()
                        advanceGeneration += 1
                        withAnimation(.easeInOut) {
                            index = 0
                            count = 0
                            target = 1
                        }
                        progress.clear(collection)
                    } label: {
                        Label("Restart", systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)
                }
            }

            ProgressView(value: Double(index + 1), total: Double(max(1, collection.items.count)))
                .progressViewStyle(.linear)
                .tint(settings.accentColor.color)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func duaCard(_ item: DuaItem) -> some View {
        VStack(spacing: 14) {
            Text(item.arabicText)
                .font(
                    settings.islamUsesCustomArabicFace
                        ? Font.arabic(settings.nonQuranArabicFontName, size: 26, relativeTo: .title2)
                        : .title2
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .frame(maxWidth: .infinity)

            Divider()

            Text(item.transliteration)
                .font(.subheadline.italic())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(item.translation)
                .font(.body)
                .multilineTextAlignment(.center)

            if let reference = item.reference {
                Text(reference)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(settings.accentColor.color)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .conditionalGlassEffect(rectangle: true, interactive: false)
    }

    /// The tally. A ring rather than a plain number so a target you set is visible as distance
    /// remaining, and the whole circle is the tap target - this is meant to be tapped without looking.
    private var counterRing: some View {
        let fraction = target > 0 ? min(1, Double(count) / Double(target)) : 0

        return Button {
            tapCount()
        } label: {
            ZStack {
                Circle()
                    .stroke(settings.accentColor.color.opacity(0.16), lineWidth: 11)

                if fraction > 0 {
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(
                            LinearGradient(colors: [settings.accentColor.color.opacity(0.75),
                                                    settings.accentColor.color],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 11, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.2), value: fraction)
                }

                VStack(spacing: 2) {
                    Text("\(count)")
                        .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(.primary)

                    Text(target > 1 ? "of \(target)" : "tap to count")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 150, height: 150)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Counter, \(count) of \(target). Tap to count.")
    }

    private var targetPicker: some View {
        HStack(spacing: 8) {
            ForEach(Self.targetChoices, id: \.self) { choice in
                let selected = target == choice

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        target = choice
                        // Lowering the target below what is already counted would strand the ring past
                        // full; the tally restarts against the new intention instead.
                        if count > choice { count = 0 }
                    }
                } label: {
                    Text("\(choice)×")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(selected ? .white : settings.accentColor.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selected
                                      ? settings.accentColor.color
                                      : settings.accentColor.color.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func controls(_ item: DuaItem) -> some View {
        HStack(spacing: 10) {
            Button {
                settings.hapticFeedback()
                goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 46, height: 46)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(index > 0 ? settings.accentColor.color : Color.secondary.opacity(0.4))
            .disabled(index == 0)
            .conditionalGlassEffect(circle: true)

            Button {
                settings.hapticFeedback()
                if speech.currentText == item.arabicText {
                    speech.stop()
                } else {
                    speech.speak(item.arabicText, rate: 0.4)
                }
            } label: {
                let speaking = speech.currentText == item.arabicText
                Label(speaking ? "Stop" : "Listen",
                      systemImage: speaking ? "stop.fill" : "speaker.wave.2")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(settings.accentColor.color)
            .conditionalGlassEffect(rectangle: true)

            Button {
                advance()
            } label: {
                Label(isLast ? "Finish" : "Next", systemImage: isLast ? "checkmark" : "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(settings.accentColor.color)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    private var completionView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(settings.accentColor.color)

            Text("Session complete")
                .font(.title3.weight(.bold))

            Text("You went through all \(collection.items.count) of \(collection.title).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // No streak, no badge, no "you're on fire" - finishing is the reward, and inventing a
            // scoreboard around dhikr is exactly the thing this app doesn't do.
            Text("تَقَبَّلَ اللهُ مِنَّا وَمِنْكُمْ")
                .font(
                    settings.islamUsesCustomArabicFace
                        ? Font.arabic(settings.nonQuranArabicFontName, size: 20, relativeTo: .body)
                        : .body
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            Spacer()

            VStack(spacing: 10) {
                Button {
                    settings.hapticFeedback()
                    advanceGeneration += 1
                    withAnimation(.easeInOut) {
                        finished = false
                        index = 0
                        count = 0
                        target = 1
                    }
                } label: {
                    Text("Go Again")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(settings.accentColor.color)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    settings.hapticFeedback()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
    }
}

/// Small stand-in for `ContentUnavailableView`, which needs iOS 17 - this app still targets 15.
private struct ContentUnavailableFallback: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
    }
}

#endif
