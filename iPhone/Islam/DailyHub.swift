#if os(iOS)
import SwiftUI

// Today, all of it in one place (2026-09-16): the Ayah, Word, Hadith, Dua, Name of Allah and
// Reminder of the Day, each with where it lives a tap away. Every daily card in the app carries a
// small door to this screen (`DailyHubDoorLabel`), so a reader who likes one of them finds the rest
// without knowing which tab each hides in. The day turns over with every other daily feature
// (`DailyRollover`: Fajr by default), and the footer says when.

struct DailyHubView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var hadithStore = HadithStore.shared
    @ObservedObject private var names = NamesViewModel.shared

    /// Opens an ayah in the reader; nil where there is no reader in the stack, in which case the hub
    /// lands on the Quran tab through `AppNavigation`.
    var onOpenAyah: ((Int, Int) -> Void)? = nil

    /// The Fortress of the Muslim, parsed off the main thread on appear (the Dua screen's pattern).
    @State private var hisnLibrary: HisnDuasStore.Library?
    /// Whether the Word of the Day corpus is in memory (see `WordOfDayStore.isLoaded`).
    @State private var wordReady = WordOfDayStore.shared.isLoaded
    /// The living line under today's Name, from the names' depth pack (parsed off-main once).
    @State private var nameLiving: String?

    private var accent: Color { settings.accentColor.color }

    var body: some View {
        List {
            Group {
                dateSection
                ayahSection
                wordSection
                hadithSection
                duaSection
                nameSection
                // Only on a Sunnah or dhikr day: on the other four the reminder IS one of the picks above.
                ReminderOfTheDaySection(showsHubDoor: false, hidesAppPicks: true)
                footerSection
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .compactListSectionSpacing()
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if hisnLibrary == nil, HisnDuasStore.isBundled {
                hisnLibrary = await Task.detached(priority: .userInitiated) { HisnDuasStore.shared.loaded() }.value
            }
            if !wordReady, WordOfDayStore.isBundled {
                await WordOfDayStore.shared.waitUntilLoaded()
                wordReady = true
            }
            if nameLiving == nil, let number = todaysName?.number {
                nameLiving = await Task.detached(priority: .utility) { NamesDetailsStore.shared.detail(number)?.living ?? "" }.value
            }
        }
    }

    // MARK: The day

    private var dateSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.headline)
                if let hijri = settings.hijriDate {
                    Text(hijri.english)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("Everything of the day, in one place. Each card opens where it lives.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 4)
        }
    }

    private var footerSection: some View {
        Section {
            HStack(spacing: 10) {
                AccentIconChip(systemImage: "arrow.triangle.2.circlepath", size: 26)
                Text(rolloverLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
    }

    /// "Turns over at Fajr, 5:46 AM" or "at midnight", from the same boundary every daily feature uses.
    private var rolloverLine: String {
        let next = settings.nextDailyRollover()
        if settings.dailyRolloverAtFajr, settings.dailyFajr(for: next) != nil {
            return "Everything here turns over at Fajr, \(settings.formatDate(next))."
        }
        return "Everything here turns over at midnight."
    }

    // MARK: Ayah

    @ViewBuilder
    private var ayahSection: some View {
        if let ref = settings.ayahOfTheDayReference(),
           let surah = quranData.surah(ref.surahID),
           let ayah = quranData.ayah(surah: ref.surahID, ayah: ref.ayahID) {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    cardHeader("AYAH OF THE DAY", symbol: "sparkles") {
                        shuffleButton(label: "Shuffle the Ayah of the Day") {
                            withAnimation(.easeInOut) { settings.shuffleAyahOfTheDay() }
                        }
                    }

                    Text("\(surah.nameTransliteration) \(surah.id):\(ayah.id)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(accent)

                    Text(ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText))
                        .font(Font.arabic(settings.quranDisplayFontName, size: 24))
                        .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(ayah.textEnglishSaheeh)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)

                    openRow("Read in the Quran", symbol: "book") {
                        openAyah(surah.id, ayah.id)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: Word

    @ViewBuilder
    private var wordSection: some View {
        if wordReady, let word = WordOfDayStore.shared.entryIfLoaded(), let surah = quranData.surah(word.surah) {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    cardHeader("WORD OF THE DAY", symbol: "character.book.closed.fill")

                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(word.meaning)
                                .font(.subheadline.weight(.semibold))
                            Text("\(word.transliteration) · first in \(surah.nameTransliteration) \(word.surah):\(word.ayah) · \(word.count) times")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 12)
                        Text(settings.cleanedQuranArabic(word.arabic))
                            .font(Font.arabic(settings.quranDisplayFontName, size: 30))
                            .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                            .foregroundColor(accent)
                    }

                    NavigationLink(destination: LazyDestination {
                        WordOfDayDetailView(word: word) { surahID, ayahID in openAyah(surahID, ayahID) }
                    }) {
                        openLabel("Every ayah with this word", symbol: "text.magnifyingglass")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: Hadith

    @ViewBuilder
    private var hadithSection: some View {
        if let pick = hadithStore.daily {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    cardHeader("HADITH OF THE DAY", symbol: "text.book.closed.fill") {
                        shuffleButton(label: "Pick a random hadith of the day") {
                            Task { await hadithStore.shuffleDailyHadith() }
                        }
                    }

                    Text("\(pick.book.englishTitle) \(pick.hadith.displayNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(accent)

                    if settings.showHadithArabic, !pick.arabicPreview.isEmpty {
                        HadithArabicPreview(text: pick.arabicPreview, size: 18, lineLimit: 3)
                    }

                    if settings.showHadithEnglish, !pick.englishPreview.isEmpty {
                        Text(pick.englishPreview)
                            .font(.subheadline)
                            .lineLimit(4)
                    }

                    NavigationLink(destination: LazyDestination {
                        HadithBookView(book: pick.book, autoOpenHadithID: pick.hadith.idInBook)
                    }) {
                        openLabel("Read the hadith", symbol: "book")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: Dua

    @ViewBuilder
    private var duaSection: some View {
        if let library = hisnLibrary, let dua = HisnDuasStore.shared.duaOfTheDay() {
            let category = library.categories.first { $0.id == dua.categoryID }
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    cardHeader("DUA OF THE DAY", symbol: "hands.sparkles.fill") {
                        if let category {
                            Text(category.label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Text.islamArabic(dua.arabic, highlightAllah: settings.highlightAllahNamesIslam)
                        .font(.custom(settings.nonQuranArabicFontName, size: 22))
                        .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(dua.translation)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        if !dua.sourceLine.isEmpty {
                            Text(dua.sourceLine)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        if let audio = dua.audio {
                            HisnDuaAudioButton(url: audio)
                        }
                    }

                    if let category {
                        NavigationLink(destination: LazyDestination {
                            DuaCollectionView(collection: HisnDuaLibraryView.collection(for: category, library: library))
                        }) {
                            openLabel("More duas for this situation", symbol: "arrow.right.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: Name of Allah

    /// Today's Name: the same walk through the 99 the Name of Allah widget makes, on the app's day counter.
    private var todaysName: NameOfAllah? {
        let all = names.namesOfAllah
        guard !all.isEmpty else { return nil }
        let index = settings.dailyDayIndex()
        return all[((index % all.count) + all.count) % all.count]
    }

    @ViewBuilder
    private var nameSection: some View {
        if let name = todaysName {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    cardHeader("NAME OF ALLAH · \(name.number) OF 99", symbol: "signature")

                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.transliteration)
                                .font(.subheadline.weight(.semibold))
                            Text(name.meaning)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 12)
                        Text(name.displayArabicName.replacingOccurrences(of: "\n", with: " "))
                            .font(.custom(settings.nonQuranArabicFontName, size: 30))
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                            .foregroundColor(accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }

                    if let living = nameLiving, !living.isEmpty {
                        Text(living)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    openRow("Open in the 99 Names", symbol: "arrow.up.right.square") {
                        AppNavigation.shared.openIslam(.names(name.number))
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: Pieces

    private func cardHeader<Trailing: View>(_ title: String, symbol: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 8) {
            AccentIconChip(systemImage: symbol, size: 26)
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            trailing()
        }
    }

    private func cardHeader(_ title: String, symbol: String) -> some View {
        cardHeader(title, symbol: symbol) { EmptyView() }
    }

    private func shuffleButton(label: String, action: @escaping () -> Void) -> some View {
        Image(systemName: "shuffle")
            .font(.caption2.weight(.semibold))
            .foregroundColor(accent)
            .frame(width: SectionPillHeader.pillHeight, height: SectionPillHeader.pillHeight)
            .conditionalGlassEffect(circle: true)
            .onTapGesture {
                settings.hapticFeedback()
                action()
            }
            .accessibilityLabel(label)
    }

    private func openLabel(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundColor(accent)
            .padding(.top, 2)
    }

    private func openRow(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            openLabel(title, symbol: symbol)
        }
        .buttonStyle(.plain)
    }

    private func openAyah(_ surah: Int, _ ayah: Int) {
        if let onOpenAyah {
            onOpenAyah(surah, ayah)
        } else {
            AppNavigation.shared.open(.ayah(surah, ayah))
        }
    }
}

extension View {
    /// Makes the view a navigation link WITHOUT the List's disclosure chevron: the link is an invisible
    /// overlay (opacity, not `hidden`, so it still takes the tap) with an empty label, the classic recipe
    /// for a row that holds more than one door, or a pill that must not drag a chevron to the row's edge.
    func chevronlessLink<Destination: View>(@ViewBuilder destination: @escaping () -> Destination) -> some View {
        overlay(
            NavigationLink(destination: LazyDestination(build: destination)) { EmptyView() }
                .opacity(0)
        )
    }
}

/// The door every daily card carries: a small "Today" pill in the card's header. On the tab roots'
/// section headers it is a plain NavigationLink; inside a card that is itself a List row it goes
/// through `chevronlessLink`, or the row grows a chevron.
struct DailyHubDoorLabel: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sun.horizon.fill")
            Text("Today")
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(appearance.accent)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(appearance.accent.opacity(0.12)))
        .accessibilityLabel("Everything of the day")
    }
}
#endif
