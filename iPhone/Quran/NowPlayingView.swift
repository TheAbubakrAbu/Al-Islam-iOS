import SwiftUI
import AVFoundation

struct NowPlayingView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

    @State private var quranView: Bool
    @Binding private var scrollDown: Int
    @Binding private var searchText: String
    private let onOpenPlayback: ((PlaybackContext) -> Void)?

    @State private var confirmRemoveNote = false
    @State private var confirmClearQueue = false
    /// Last real playback context, kept so the bar can stay mounted (hidden) after playback stops - tearing
    /// it down inside the stop action was cancelling "Stop Playing".
    @State private var retainedContext: PlaybackContext?

    /// Small (default) vs. big player. Stored on `settings` (not @AppStorage) so `withAnimation` animates it.
    private var isExpanded: Bool { settings.nowPlayingExpanded }

    init(
        quranView: Bool = false,
        scrollDown: Binding<Int> = .constant(-1),
        searchText: Binding<String> = .constant(""),
        onOpenPlayback: ((PlaybackContext) -> Void)? = nil
    ) {
        self.quranView = quranView
        _scrollDown = scrollDown
        _searchText = searchText
        self.onOpenPlayback = onOpenPlayback
    }

    var body: some View {
        #if os(iOS)
        // The parent inset inserts/removes this view with `if isPlaying||isPaused` + `.animation`, which
        // animates BOTH the fade and the height collapse (a `.frame(height:)` between natural and 0 can't
        // animate - it snaps). `retainedContext` keeps the last context so the bar still has content to render
        // while it fades OUT (otherwise `playbackContext` goes nil on stop and there's nothing to fade). The
        // "Stop Playing" action defers `stop()` so this view isn't torn down mid-action (which cancelled it).
        guard let ctx = playbackContext ?? retainedContext else {
            return AnyView(EmptyView())
        }

        return
            AnyView(
                VStack(spacing: 8) {
                    // Tapping the bar goes to what's playing. `onOpenPlayback` is honoured wherever it is
                    // supplied - not just on the Quran list (`quranView`) - so the reader can hand the tap
                    // to its own "go to ayah/surah" navigation (page mode lands on the page holding the
                    // ayah, list mode scrolls the surah to it) instead of pushing a second reader.
                    if let onOpenPlayback {
                        Button {
                            settings.hapticFeedback()
                            onOpenPlayback(ctx)
                        } label: {
                            playerRow(isPlaying: quranPlayer.isPlaying)
                        }
                        .buttonStyle(.plain)
                    } else if quranView {
                        NavigationLink {
                            destinationView(for: ctx)
                        } label: {
                            playerRow(isPlaying: quranPlayer.isPlaying)
                        }
                    } else {
                        playerRow(isPlaying: quranPlayer.isPlaying)
                    }
                }
                // Pin a stable full width so the small and big players are the same size and only the
                // height animates - keeps the card from resizing sideways when expanding/collapsing.
                .overlay(alignment: .topTrailing) {
                    expandToggleButton
                }
                .contextMenu {
                    contextMenu(for: ctx)
                }
                .confirmationDialog("Clear the queue?", isPresented: $confirmClearQueue, titleVisibility: .visible) {
                    Button("Clear Queue", role: .destructive) {
                        settings.hapticFeedback()
                        quranPlayer.clearSurahQueue()
                    }
                    Button("Cancel") {}
                } message: {
                    Text("This removes all surahs you've queued up. This can't be undone.")
                }
                .cornerRadius(24)
                .padding(.horizontal, 8)
                // Always use the rounded-rectangle glass so the shape never morphs between a capsule and a
                // rectangle when expanding/collapsing. Animating the glass shape change crashed the glass
                // renderer (and caused the temporary Quran-layout shift), so we keep one stable shape.
                .conditionalGlassEffect(rectangle: true)
                // Fades in/out as the parent inserts/removes the bar (gated on isPlaying||isPaused).
                .transition(.opacity)
                // Capture the context on appear AND on change. `onChange` alone misses the very first value
                // (continuous surah playback never changes the key), leaving `retainedContext` nil - so on
                // stop the bar fell back to EmptyView and vanished without fading. Capturing on appear fixes it.
                .onAppear {
                    if let pc = playbackContext { retainedContext = pc }
                }
                .onChange(of: playbackContextKey) { _ in
                    if let pc = playbackContext { retainedContext = pc }
                }
            )
        #else
        guard let playbackContext else {
            return AnyView(EmptyView())
        }
        return
            AnyView(
                Section(header: Text("NOW PLAYING")) {
                    VStack(spacing: 8) {
                        playerRow(isPlaying: quranPlayer.isPlaying)
                    }
                    .transition(.opacity)
                }
            )
        #endif
    }

    /// Identity of the current playback context (nil when stopped). Used to refresh `retainedContext`.
    private var playbackContextKey: String? {
        guard let pc = playbackContext else { return nil }
        return "\(pc.surah.id):\(pc.ayahNumber):\(pc.isPlaying)"
    }

    private var playbackContext: PlaybackContext? {
        guard
            let surahNumber = quranPlayer.currentSurahNumber,
            let surah = quranPlayer.quranData.quran.first(where: { $0.id == surahNumber }),
            quranPlayer.isPlaying || quranPlayer.isPaused
        else {
            return nil
        }

        return PlaybackContext(
            surah: surah,
            ayahNumber: quranPlayer.currentAyahNumber ?? 1,
            isPlaying: quranPlayer.isPlaying
        )
    }

    private var bookmarkIndex: Int? {
        let surah = quranPlayer.currentSurahNumber ?? 1
        let ayah = quranPlayer.currentAyahNumber ?? 1
        return settings.bookmarkIndex(surah: surah, ayah: ayah)
    }

    private var bookmark: BookmarkedAyah? {
        settings.bookmarkedAyah(surah: quranPlayer.currentSurahNumber ?? 1, ayah: quranPlayer.currentAyahNumber ?? 1)
    }

    private var isBookmarkedHere: Bool {
        bookmarkIndex != nil
    }

    private var currentNote: String {
        settings.bookmarkNoteText(surah: quranPlayer.currentSurahNumber ?? 1, ayah: quranPlayer.currentAyahNumber ?? 1)
    }

    @ViewBuilder
    private func destinationView(for context: PlaybackContext) -> some View {
        if quranPlayer.isPlayingSurah {
            SurahView(surah: context.surah)
        } else {
            SurahView(surah: context.surah, ayah: context.ayahNumber)
        }
    }

    @ViewBuilder
    private func transportButtons(isPlaying: Bool) -> some View {
        // Skip (previous/next ayah or surah) is the smaller control so the ±10s seek can be the prominent one.
        Image(systemName: "backward.fill")
            .font(.body)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                quranPlayer.skipBackward()
            }

        #if os(iOS)
        // Fine seek (±10s) is the emphasized control in the in-app player, for both surah and ayah playback.
        Image(systemName: "gobackward.10")
            .font(.title3)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                quranPlayer.seek(by: -10)
            }
        #endif

        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.title)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                // No withAnimation: wrapping play/pause in an animation transaction made the glass card
                // briefly flash a black backing behind the (expanded) player. The icon swap alone needs
                // no animation, and isPlaying||isPaused stays true across pause/resume so nothing else moves.
                isPlaying ? quranPlayer.pause() : quranPlayer.resume()
            }

        #if os(iOS)
        Image(systemName: "goforward.10")
            .font(.title3)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                quranPlayer.seek(by: 10)
            }
        #endif

        Image(systemName: "forward.fill")
            .font(.body)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                quranPlayer.skipForward()
            }
    }

    /// Big-player transport row with the live progress bar on top and the elapsed/duration times sharing the
    /// same line as the controls (saves vertical space vs. a separate progress block). Polls on a timeline.
    @ViewBuilder
    private func transportRowWithProgress(isPlaying: Bool) -> some View {
        // Half-second cadence only while audio actually advances. The card persists across pause, and
        // the periodic timeline kept redrawing this subtree twice a second over a frozen progress bar;
        // paused, one lazy tick keeps it alive, and the play/pause @Published change re-renders (and
        // re-schedules) immediately on resume.
        TimelineView(.periodic(from: .now, by: isPlaying ? 0.5 : 3600)) { _ in
            let elapsed = CMTimeGetSeconds(quranPlayer.player?.currentTime() ?? .zero)
            let rawTotal = CMTimeGetSeconds(quranPlayer.player?.currentItem?.duration ?? .zero)
            let total = (rawTotal.isFinite && rawTotal > 0) ? rawTotal : 0
            let safeElapsed = elapsed.isFinite ? max(0, elapsed) : 0

            VStack(spacing: 6) {
                if total > 0 {
                    TinyProgressBar(fraction: safeElapsed / total, color: settings.accentColor.color)
                }

                HStack(spacing: 10) {
                    Text(total > 0 ? Self.formatMMSS(safeElapsed) : "")
                        .frame(width: 40, alignment: .leading)

                    Spacer()

                    HStack(spacing: 18) {
                        transportButtons(isPlaying: isPlaying)
                    }

                    Spacer()

                    Text(total > 0 ? Self.formatMMSS(total) : "")
                        .frame(width: 40, alignment: .trailing)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
            // The progress bar / times tick every 0.5s and on play/resume. Opt this subtree out of any
            // implicit animation inherited from the player card so the bar jumps to its position instead of
            // easing - otherwise resuming (and each tick) shows a weird sliding/lurching animation.
            .transaction { $0.animation = nil }
        }
    }

    private static func formatMMSS(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func customRangeLineOne(start: Int, end: Int) -> String {
        let current = quranPlayer.customRangeCurrentIndex ?? 1
        let total = quranPlayer.customRangeTotalItems
            ?? max(1, (end - start + 1) * quranPlayer.customRangeRepeatPerAyah * quranPlayer.customRangeRepeatSection)
        return "Ayahs \(start)-\(end) (\(current)/\(total))"
    }

    private func customRangeLineTwo() -> String {
        let ayahProgress = quranPlayer.customRangeCurrentRepeatWithinAyah ?? 1
        let ayahTotal = max(1, quranPlayer.customRangeRepeatPerAyah)
        let sectionProgress = quranPlayer.customRangeRepeatSectionIndex ?? 1
        let sectionTotal = max(1, quranPlayer.customRangeRepeatSection)
        return "Ayah \(ayahProgress)/\(ayahTotal) · Section \(sectionProgress)/\(sectionTotal)"
    }

    /// For a custom range, keep the top title short (just "Name S:A") since the per-ayah/section detail
    /// shows on its own lines below. Other playback uses the full now-playing title.
    private var displayTitle: String? {
        if quranPlayer.isPlayingCustomRange,
           let surahNumber = quranPlayer.currentSurahNumber,
           let ayahNumber = quranPlayer.currentAyahNumber,
           let surah = quranPlayer.quranData.quran.first(where: { $0.id == surahNumber }) {
            return "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)"
        }
        return quranPlayer.nowPlayingTitle
    }

    /// Top-right button that toggles between the small and big player.
    private var expandToggleButton: some View {
        Button {
            settings.hapticFeedback()
            // Toggle WITHOUT a global withAnimation. A global transaction animated the whole enclosing
            // List, which squished the ayah/surah rows and scrolled the Quran list back to the top. The
            // compact<->expanded size change is animated locally by `.animation(value: isExpanded)` on
            // playerRow, so only this card animates.
            settings.nowPlayingExpanded.toggle()
        } label: {
            Image(systemName: isExpanded
                  ? "arrow.down.right.and.arrow.up.left"
                  : "arrow.up.left.and.arrow.down.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func playerRow(isPlaying: Bool) -> some View {
        #if os(iOS)
        Group {
            if isExpanded {
                expandedPlayerRow(isPlaying: isPlaying)
            } else {
                compactPlayerRow(isPlaying: isPlaying)
            }
        }
        .transition(.opacity)
        // No `.animation(value: isPlaying || isPaused)` here: the appearance/disappearance of the player on
        // start/stop is already animated by the enclosing inset (`nowPlayingInset`), and a second animation
        // at this level fought with it - producing the weird morph when resuming and when playback ended.
        // Animate only the compact<->expanded size change locally, from this single source. The expand button
        // no longer wraps the toggle in a global `withAnimation` (that animated the whole List - squishing
        // rows and resetting the Quran scroll), so there's no longer a second animation to fight with.
        .animation(.easeInOut, value: isExpanded)
        .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                let surah = quranPlayer.currentSurahNumber ?? 1
                let ayah = quranPlayer.currentAyahNumber ?? 1

                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah, ayah: ayah)
            }
            Button("Cancel") {}
        } message: {
            Text(Settings.bookmarkNoteRemovalDialogMessage)
        }
        #else
        VStack(alignment: .center, spacing: 6) {
            titleBlock(expanded: false)

            HStack(spacing: 12) {
                transportButtons(isPlaying: isPlaying)
            }
            .font(.headline)
            .padding(.top, 2)
        }
        .padding(4)
        .overlay(alignment: .bottomTrailing) {
            stopButton
                .padding(.vertical, 4)
                .padding(.trailing, -2)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: quranPlayer.isPlaying)
        #endif
    }

    #if os(iOS)
    /// Big player: centered title, then a transport row with the progress bar on top and the times inline.
    private func expandedPlayerRow(isPlaying: Bool) -> some View {
        VStack(spacing: 8) {
            VStack(alignment: .center, spacing: 1) {
                titleBlock(expanded: true)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            // Horizontal inset keeps the centered title clear of the top-right expand button.
            .padding(.horizontal, 24)

            if quranPlayer.isPlaying || quranPlayer.isPaused {
                transportRowWithProgress(isPlaying: isPlaying)
            } else {
                HStack(spacing: 22) {
                    transportButtons(isPlaying: isPlaying)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
    }

    /// Small player (matches 4.4.4): one row, three controls, no seek, no progress bar.
    private func compactPlayerRow(isPlaying: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                titleBlock(expanded: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                compactTransportButtons(isPlaying: isPlaying)
            }
            // Clearance for the top-right expand button lives on the controls (not the row) so the row keeps
            // the SAME horizontal padding as the expanded player.
            .padding(.trailing, 30)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func compactTransportButtons(isPlaying: Bool) -> some View {
        Image(systemName: "backward.fill")
            .font(.title3)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                quranPlayer.skipBackward()
            }

        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.title2)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                // No withAnimation: wrapping play/pause in an animation transaction made the glass card
                // briefly flash a black backing behind the (expanded) player. The icon swap alone needs
                // no animation, and isPlaying||isPaused stays true across pause/resume so nothing else moves.
                isPlaying ? quranPlayer.pause() : quranPlayer.resume()
            }

        Image(systemName: "forward.fill")
            .font(.title3)
            .foregroundColor(settings.accentColor.color)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                quranPlayer.skipForward()
            }
    }
    #endif

    @ViewBuilder
    private func titleBlock(expanded: Bool) -> some View {
        // Big player mirrors Control Center exactly (full title, with the custom-range ayah/section detail
        // already inline). Small player uses the short title and breaks the detail out onto its own lines.
        let titleText = expanded ? quranPlayer.nowPlayingTitle : displayTitle
        if let title = titleText {
            Text(title)
                .foregroundColor(.primary)
                #if os(iOS)
                .font(.headline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                #else
                .font(.caption)
                .lineLimit(2)
                #endif
        }

        if let reciter = quranPlayer.nowPlayingReciter {
            Text(reciter)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                #if os(iOS)
                .minimumScaleFactor(0.5)
                #endif
        }

        // Custom range: the "Ayahs X-Y (n/total)" line shows under the reciter in BOTH sizes; the
        // per-ayah/section breakdown line is small-player only.
        if quranPlayer.isPlayingCustomRange,
           let start = quranPlayer.customRangeStartAyah,
           let end = quranPlayer.customRangeEndAyah {
            Text(customRangeLineOne(start: start, end: end))
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)

            if !expanded {
                Text(customRangeLineTwo())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var stopButton: some View {
        Button {
            settings.hapticFeedback()
            // No withAnimation: the player's disappearance is animated by the view's own `.animation(value:)`.
            quranPlayer.stop()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .imageScale(.large)
        }
        .tint(.secondary)
    }

    private func toggleBookmarkWithNoteGuard() {
        let surah = quranPlayer.currentSurahNumber ?? 1
        let ayah = quranPlayer.currentAyahNumber ?? 1

        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah, ayah: ayah) {
            confirmRemoveNote = true
        }
    }

    /// The ±10s seek pair, as a palette-style row at the top of the compact player's context menu.
    ///
    /// Compact-only on purpose: the big player already shows `gobackward.10` / `goforward.10` inline, so
    /// there it would be a duplicate. Small player has room for three controls, and long-pressing is how
    /// you reach the rest - fine seeking included. Calls the player's own `seek(by:)`, the same API the
    /// expanded transport row uses.
    @ViewBuilder
    private var seekControlGroup: some View {
        // iOS-only: watchOS has no `ControlGroup` at all, and no context menu on this bar either.
        #if os(iOS)
        if #available(iOS 16.4, *) {
            ControlGroup {
                seekButton(by: -10)
                seekButton(by: 10)
            }
            .controlGroupStyle(.compactMenu)
        } else {
            // Pre-16.4 has no compact/palette control group; the same two actions as ordinary menu rows.
            seekButton(by: -10)
            seekButton(by: 10)
        }
        #endif
    }

    private func seekButton(by seconds: Double) -> some View {
        Button {
            settings.hapticFeedback()
            quranPlayer.seek(by: seconds)
        } label: {
            Label(
                seconds < 0 ? "Back 10 Seconds" : "Forward 10 Seconds",
                systemImage: seconds < 0 ? "gobackward.10" : "goforward.10"
            )
        }
    }

    @ViewBuilder
    private func contextMenu(for context: PlaybackContext) -> some View {
        let isFavorite = settings.isSurahFavorite(surah: context.surah.id)
        let isBookmarked = settings.isBookmarked(surah: context.surah.id, ayah: context.ayahNumber)

        Button(role: .destructive) {
            settings.hapticFeedback()
            // Defer stop so the menu action fully completes before this bar (the menu's host) is removed - 
            // removing it synchronously inside the action cancelled the stop.
            DispatchQueue.main.async { quranPlayer.stop() }
        } label: {
            Label("Stop Playing", systemImage: "xmark.circle.fill")
        }

        Divider()

        Button {
            settings.hapticFeedback()
            quranPlayer.playSurah(surahNumber: context.surah.id, surahName: context.surah.nameTransliteration)
        } label: {
            Label("Play from Beginning", systemImage: "memories")
        }

        Button {
            settings.hapticFeedback()
            quranPlayer.addSurahToQueue(surahNumber: context.surah.id, surahName: context.surah.nameTransliteration)
        } label: {
            Label("Add Current Surah to Queue", systemImage: "text.line.last.and.arrowtriangle.forward")
        }

        if !quranPlayer.surahQueue.isEmpty {
            Button(role: .destructive) {
                settings.hapticFeedback()
                confirmClearQueue = true
            } label: {
                Label("Clear Queue (\(quranPlayer.surahQueue.count))", systemImage: "text.badge.xmark")
            }
        }

        Divider()

        Button(role: isFavorite ? .destructive : nil) {
            settings.hapticFeedback()
            settings.toggleSurahFavorite(surah: context.surah.id)
        } label: {
            Label(
                isFavorite ? "Unfavorite Surah" : "Favorite Surah",
                systemImage: isFavorite ? "star.fill" : "star"
            )
        }

        Button(role: isBookmarked ? .destructive : nil) {
            settings.hapticFeedback()
            toggleBookmarkWithNoteGuard()
        } label: {
            Label(
                isBookmarked ? "Unbookmark Ayah" : "Bookmark Ayah",
                systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
            )
        }

        Divider()

        if quranView {
            Button {
                settings.hapticFeedback()
                searchText = ""
                scrollDown = context.surah.id
                self.endEditing()
            } label: {
                Label("Scroll To Surah", systemImage: "arrow.down.circle")
            }
        }

        // Last, nearest the thumb: the compact player has no inline transport, so these are the
        // scrub controls. The expanded player already shows them inline and skips this.
        if !isExpanded {
            Divider()

            seekControlGroup
        }
    }
}

struct PlaybackContext {
    let surah: Surah
    let ayahNumber: Int
    let isPlaying: Bool
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        NowPlayingView()
    }
}
