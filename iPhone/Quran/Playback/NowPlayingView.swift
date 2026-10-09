import SwiftUI
import AVFoundation

struct NowPlayingView: View {
    @ObservedObject var settings = Settings.shared
    /// Actions and the `AVPlayer` only: not observed. Playback state comes from `nowPlaying`, which
    /// republishes once per turn instead of once per player write (see `NowPlayingState`).
    private let quranPlayer = QuranPlayer.shared
    @ObservedObject private var nowPlaying = QuranPlayer.shared.nowPlaying
    /// The progress poll runs at 1 s on the reduced tier (Phase 5 step 11).
    @Environment(\.appearance) private var appearance

    @State private var quranView: Bool
    @Binding private var scrollDown: Int
    @Binding private var searchText: String
    private let onOpenPlayback: ((PlaybackContext) -> Void)?
    /// One row even when big: the page reader lays the bar across its whole width when it is wide
    /// (`PageReaderControlsPart.nowPlaying`), where the big player's three stacked rows only cost the
    /// page height.
    private let singleRow: Bool

    @State private var confirmClearQueue = false
    /// Last real playback context, kept so the bar can stay mounted (hidden) after playback stops - tearing
    /// it down inside the stop action was cancelling "Stop Playing". A reference box under `@State`, not a
    /// `@State` value: writing a value here on every context change was a second body evaluation per
    /// ayah advance for every mounted bar, and nothing needs to render when it changes.
    private final class RetainedContext { var value: PlaybackContext? }
    @State private var retained = RetainedContext()

    /// Small (default) vs. big player. Stored on `settings` (not @AppStorage) so `withAnimation` animates it.
    private var isExpanded: Bool { settings.nowPlayingExpanded }

    init(
        quranView: Bool = false,
        scrollDown: Binding<Int> = .constant(-1),
        searchText: Binding<String> = .constant(""),
        singleRow: Bool = false,
        onOpenPlayback: ((PlaybackContext) -> Void)? = nil
    ) {
        self.quranView = quranView
        _scrollDown = scrollDown
        _searchText = searchText
        self.singleRow = singleRow
        self.onOpenPlayback = onOpenPlayback
    }

    var body: some View {
        let _ = RenderCounter.hit(quranView ? "NowPlayingView.quran" : (onOpenPlayback != nil ? "NowPlayingView.reader" : "NowPlayingView.bar"))
        #if os(iOS)
        // The parent inset inserts/removes this view with `if isPlaying||isPaused` + `.animation`, which
        // animates BOTH the fade and the height collapse (a `.frame(height:)` between natural and 0 can't
        // animate - it snaps). `retainedContext` keeps the last context so the bar still has content to render
        // while it fades OUT (otherwise `playbackContext` goes nil on stop and there's nothing to fade). The
        // "Stop Playing" action defers `stop()` so this view isn't torn down mid-action (which cancelled it).
        guard let ctx = playbackContext ?? retained.value else {
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
                            playerRow(isPlaying: nowPlaying.isPlaying)
                        }
                        .buttonStyle(.plain)
                    } else if quranView {
                        NavigationLink {
                            LazyDestination {
                                destinationView(for: ctx)
                            }
                        } label: {
                            playerRow(isPlaying: nowPlaying.isPlaying)
                        }
                    } else {
                        playerRow(isPlaying: nowPlaying.isPlaying)
                    }
                }
                // Pin a stable full width so the small and big players are the same size and only the
                // height animates - keeps the card from resizing sideways when expanding/collapsing.
                // Centred on the one-row bar, which is only as tall as its controls.
                .overlay(alignment: singleRow ? .trailing : .topTrailing) {
                    expandToggleButton
                }
                // The quit button takes the corner opposite the expand button, on the same alignment
                // rule, so the pair reads as one row of card controls.
                //
                // BIG PLAYER ONLY (Abu, 2026-10-07: "remove it from small playing view only keep it for
                // big"). The compact bar is narrow and its title already runs close to both corners, so
                // a second corner control there crowded the one line that matters. Stopping playback
                // from the small bar is still a long press away ("Stop Playing" in the context menu),
                // and expanding puts the button back.
                .overlay(alignment: singleRow ? .leading : .topLeading) {
                    if isExpanded {
                        quitButton
                    }
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
                    if let pc = playbackContext { retained.value = pc }
                }
                .onChange(of: playbackContextKey) { _ in
                    if let pc = playbackContext { retained.value = pc }
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
                        playerRow(isPlaying: nowPlaying.isPlaying)
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
            let surahNumber = nowPlaying.currentSurahNumber,
            let surah = quranPlayer.quranData.quran.first(where: { $0.id == surahNumber }),
            nowPlaying.isPlaying || nowPlaying.isPaused
        else {
            return nil
        }

        return PlaybackContext(
            surah: surah,
            ayahNumber: nowPlaying.currentAyahNumber ?? 1,
            isPlaying: nowPlaying.isPlaying
        )
    }

    private var bookmarkIndex: Int? {
        let surah = nowPlaying.currentSurahNumber ?? 1
        let ayah = nowPlaying.currentAyahNumber ?? 1
        return settings.bookmarkIndex(surah: surah, ayah: ayah)
    }

    private var bookmark: BookmarkedAyah? {
        settings.bookmarkedAyah(surah: nowPlaying.currentSurahNumber ?? 1, ayah: nowPlaying.currentAyahNumber ?? 1)
    }

    private var isBookmarkedHere: Bool {
        bookmarkIndex != nil
    }

    private var currentNote: String {
        settings.bookmarkNoteText(surah: nowPlaying.currentSurahNumber ?? 1, ayah: nowPlaying.currentAyahNumber ?? 1)
    }

    @ViewBuilder
    private func destinationView(for context: PlaybackContext) -> some View {
        if nowPlaying.isPlayingSurah {
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
        TimelineView(.periodic(from: .now, by: isPlaying ? (appearance.isReducedTier ? 1 : 0.5) : 3600)) { _ in
            let elapsed = CMTimeGetSeconds(quranPlayer.player?.currentTime() ?? .zero)
            let rawTotal = CMTimeGetSeconds(quranPlayer.player?.currentItem?.duration ?? .zero)
            let total = (rawTotal.isFinite && rawTotal > 0) ? rawTotal : 0
            let safeElapsed = elapsed.isFinite ? max(0, elapsed) : 0

            VStack(spacing: 6) {
                if total > 0 {
                    TinyProgressBar(fraction: safeElapsed / total, color: settings.accentColor.color)
                }

                // This row must never be wider than the card it sits in. Two rigid 40 pt time labels,
                // two spacers with their default minimum, and 18 pt between five icons added up to a
                // minimum width of ~323 pt, and a phone's reader offers this card 314: the row pushed
                // the WHOLE reader out to 411 pt on a 402 pt screen (measured 2026-09-21). The page
                // reader then composed every page 9 pt wider than the screen, every cached render
                // missed (the width is in the cache key), and expanding the player, and stopping
                // playback while expanded, both showed the spinner over a page that was just there.
                // Flexible everything: the labels shrink to their text, the spacers to nothing.
                HStack(spacing: 8) {
                    Text(total > 0 ? Self.formatMMSS(safeElapsed) : "")
                        .frame(minWidth: 0, idealWidth: 40, maxWidth: 40, alignment: .leading)

                    Spacer(minLength: 0)

                    HStack(spacing: 14) {
                        transportButtons(isPlaying: isPlaying)
                    }

                    Spacer(minLength: 0)

                    Text(total > 0 ? Self.formatMMSS(total) : "")
                        .frame(minWidth: 0, idealWidth: 40, maxWidth: 40, alignment: .trailing)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
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

    /// A range set to repeat forever (`QuranPlayer.infiniteRepeat`): its counts are per pass.
    private var customRangeLoops: Bool {
        nowPlaying.customRangeRepeatSection == QuranPlayer.infiniteRepeat
    }

    private func customRangeLineOne(start: Int, end: Int) -> String {
        let current = nowPlaying.customRangeCurrentIndex ?? 1
        let section = customRangeLoops ? 1 : nowPlaying.customRangeRepeatSection
        let total = nowPlaying.customRangeTotalItems
            ?? max(1, (end - start + 1) * nowPlaying.customRangeRepeatPerAyah * section)
        return "Ayahs \(start)-\(end) (\(current)/\(total))"
    }

    private func customRangeLineTwo() -> String {
        let ayahProgress = nowPlaying.customRangeCurrentRepeatWithinAyah ?? 1
        let ayahTotal = max(1, nowPlaying.customRangeRepeatPerAyah)
        let sectionProgress = nowPlaying.customRangeRepeatSectionIndex ?? 1
        let sectionTotal = customRangeLoops ? "\u{221E}" : "\(max(1, nowPlaying.customRangeRepeatSection))"
        return "Ayah \(ayahProgress)/\(ayahTotal) · Section \(sectionProgress)/\(sectionTotal)"
    }

    /// For a custom range, keep the top title short (just "Name S:A") since the per-ayah/section detail
    /// shows on its own lines below. Other playback uses the full now-playing title.
    private var displayTitle: String? {
        if nowPlaying.isPlayingCustomRange,
           let surahNumber = nowPlaying.currentSurahNumber,
           let ayahNumber = nowPlaying.currentAyahNumber,
           let surah = quranPlayer.quranData.quran.first(where: { $0.id == surahNumber }) {
            return "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)"
        }
        return nowPlaying.nowPlayingTitle
    }

    /// Top-LEFT button that stops playback and dismisses the bar, mirroring the expand button opposite
    /// it (Abu, 2026-10-07: "top left should be quit button"). Same action as the context menu's "Stop
    /// Playing", including the deferred `stop()`: this bar is the button's own host, so tearing it down
    /// synchronously inside the action cancels the action before it runs.
    private var quitButton: some View {
        Button {
            settings.hapticFeedback()
            DispatchQueue.main.async { quranPlayer.stop() }
        } label: {
            Image(systemName: "xmark")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop playing")
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
            if isExpanded && singleRow {
                singleRowExpandedPlayer(isPlaying: isPlaying)
            } else if isExpanded {
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
        .animation(.easeInOut, value: nowPlaying.isPlaying)
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

            if nowPlaying.isPlaying || nowPlaying.isPaused {
                transportRowWithProgress(isPlaying: isPlaying)
            } else {
                HStack(spacing: 14) {
                    transportButtons(isPlaying: isPlaying)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
    }

    /// The big player as ONE row (`singleRow`): the title leading, the progress bar with its times in
    /// the middle, the whole transport trailing (Abu, 2026-09-29: "should be all horizontal and take up
    /// both sides" under the two-page spread).
    private func singleRowExpandedPlayer(isPlaying: Bool) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 1) {
                titleBlock(expanded: true)
            }
            .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
            // Clearance for the leading quit button, mirroring the trailing clearance on the controls.
            .padding(.leading, 30)

            if nowPlaying.isPlaying || nowPlaying.isPaused {
                inlineProgress(isPlaying: isPlaying)
                    .frame(minWidth: 120, maxWidth: .infinity)
            }

            HStack(spacing: 14) {
                transportButtons(isPlaying: isPlaying)
            }
            .fixedSize()
            // Clearance for the expand button, as on the small player.
            .padding(.trailing, 30)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    /// The elapsed time, the progress bar and the duration on one line, for the one-row big player.
    /// The same timeline and cadence as `transportRowWithProgress`.
    private func inlineProgress(isPlaying: Bool) -> some View {
        TimelineView(.periodic(from: .now, by: isPlaying ? (appearance.isReducedTier ? 1 : 0.5) : 3600)) { _ in
            let elapsed = CMTimeGetSeconds(quranPlayer.player?.currentTime() ?? .zero)
            let rawTotal = CMTimeGetSeconds(quranPlayer.player?.currentItem?.duration ?? .zero)
            let total = (rawTotal.isFinite && rawTotal > 0) ? rawTotal : 0
            let safeElapsed = elapsed.isFinite ? max(0, elapsed) : 0

            HStack(spacing: 8) {
                Text(total > 0 ? Self.formatMMSS(safeElapsed) : "")
                    .frame(minWidth: 0, idealWidth: 40, maxWidth: 48, alignment: .trailing)

                TinyProgressBar(fraction: total > 0 ? safeElapsed / total : 0, color: settings.accentColor.color)

                Text(total > 0 ? Self.formatMMSS(total) : "")
                    .frame(minWidth: 0, idealWidth: 40, maxWidth: 48, alignment: .leading)
            }
            .font(.caption2)
            .monospacedDigit()
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            // Jumps to each tick, never eases (see `transportRowWithProgress`).
            .transaction { $0.animation = nil }
        }
    }

    /// Small player (matches 4.4.4): one row, three controls, no seek, no progress bar.
    private func compactPlayerRow(isPlaying: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                titleBlock(expanded: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // No leading clearance: the quit button is BIG-PLAYER ONLY now (Abu, 2026-10-07), so this
            // corner is empty on the small bar and the title takes the 30pt back. The trailing
            // clearance below stays - the expand button is still in that corner.

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
        let titleText = expanded ? nowPlaying.nowPlayingTitle : displayTitle
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

        if let reciter = nowPlaying.nowPlayingReciter {
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
        if nowPlaying.isPlayingCustomRange,
           let start = nowPlaying.customRangeStartAyah,
           let end = nowPlaying.customRangeEndAyah {
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

    /// Bookmarks the playing ayah, or asks before removing its bookmark (`Settings.toggleBookmarkOrConfirm`).
    private func toggleBookmarkOrConfirm() {
        settings.toggleBookmarkOrConfirm(
            surah: nowPlaying.currentSurahNumber ?? 1,
            ayah: nowPlaying.currentAyahNumber ?? 1
        )
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

        if !nowPlaying.surahQueue.isEmpty {
            Button(role: .destructive) {
                settings.hapticFeedback()
                confirmClearQueue = true
            } label: {
                Label("Clear Queue (\(nowPlaying.surahQueue.count))", systemImage: "text.badge.xmark")
            }
        }

        Divider()

        Button(role: isFavorite ? .destructive : nil) {
            settings.hapticFeedback()
            settings.toggleSurahFavoriteOrConfirm(surah: context.surah.id)
        } label: {
            Label(
                isFavorite ? "Unfavorite Surah" : "Favorite Surah",
                systemImage: isFavorite ? "star.fill" : "star"
            )
        }

        Button(role: isBookmarked ? .destructive : nil) {
            settings.hapticFeedback()
            toggleBookmarkOrConfirm()
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

#if DEBUG
/// Real playback state for the canvas. The card renders from `QuranPlayer.shared.nowPlaying`, which in
/// a preview is the STOPPED snapshot - so an unseeded preview of this file shows an empty bar and tells
/// you nothing about the thing you are editing. `previewSeed` writes the slice the card reads, using a
/// real surah out of `QuranData.shared` so the Arabic name, the transliteration and the ayah count are
/// the shipped ones rather than invented strings.
private func seedNowPlaying(expanded: Bool,
                            playing: Bool = true,
                            ayah: Int = 5,
                            queue: Bool = false) -> Surah {
    let surah = AlIslamPreviewData.quranData.quran.first(where: { $0.id == 18 })
        ?? AlIslamPreviewData.surah
    AlIslamPreviewData.seedPersisted("nowPlayingExpanded", expanded)
    QuranPlayer.shared.nowPlaying.previewSeed { snapshot in
        snapshot.isPlaying = playing
        snapshot.isPaused = !playing
        snapshot.isLoading = false
        snapshot.currentSurahNumber = surah.id
        snapshot.currentAyahNumber = ayah
        snapshot.isPlayingSurah = true
        snapshot.nowPlayingTitle = "\(surah.nameTransliteration) \(surah.id):\(ayah)"
        snapshot.nowPlayingReciter = "Mishary Rashid Alafasy"
        snapshot.surahQueue = queue
            ? [SurahQueueItem(surahNumber: 36, surahName: "Ya-Sin"),
               SurahQueueItem(surahNumber: 55, surahName: "Ar-Rahman"),
               SurahQueueItem(surahNumber: 67, surahName: "Al-Mulk")]
            : []
    }
    // The bar only mounts under a list when playback is live.
    PlaybackVisibility.shared.update(showsBar: playing)
    return surah
}

/// Both corners at once - the quit button added 2026-10-07 (top LEFT) against the expand button it
/// mirrors (top RIGHT) - in the two shapes that position them differently. Compact pins them to the
/// top corners over a leading-aligned title; the one-row player centres them vertically at the edges.
/// Check in this preview that neither button overlaps the title at its longest.
#Preview("Player - compact vs expanded") {
    let surah = seedNowPlaying(expanded: false)
    return AlIslamPreviewContainer(embedInNavigation: false) {
        ScrollView {
            VStack(spacing: 28) {
                Group {
                    Text("Compact - quit (top left) + expand (top right)")
                    NowPlayingView(quranView: true)

                    Text("Expanded - transport, scrubber, both corner buttons")
                    NowPlayingView(quranView: true)
                        .onAppear { AlIslamPreviewData.seedPersisted("nowPlayingExpanded", true) }

                    Text("One row (wide page reader) - buttons centre at the edges")
                    NowPlayingView(quranView: false, singleRow: true)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 24)
        }
        .overlay(alignment: .bottom) {
            Text("Now playing: \(surah.nameArabic) - \(surah.numberOfAyahs) ayahs")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

/// Paused, and with a queue behind it: the title block and the transport both change, and the context
/// menu's "Clear the queue?" path only exists when `surahQueue` is non-empty.
#Preview("Player - paused with a queue") {
    _ = seedNowPlaying(expanded: true, playing: false, ayah: 12, queue: true)
    return AlIslamPreviewContainer(embedInNavigation: false) {
        NowPlayingView(quranView: true)
    }
}

/// The bar as every non-Quran tab actually gets it: installed by `PlaybackVisibility` as a bottom
/// safe-area inset UNDER a real List. This is the shape the 2026-10-07 inset-order fix was about - the
/// player must sit ABOVE a screen's own floating bottom bar, never beneath it.
///
/// iOS only: `SearchBar` and `adaptiveSafeArea` are both iOS-only, and the watch has no floating bar.
#if os(iOS)
#Preview("Player - over a list, with a search bar") {
    _ = seedNowPlaying(expanded: false)
    return AlIslamPreviewContainer {
        List {
            Section("A list under the player") {
                ForEach(AlIslamPreviewData.quranData.quran.prefix(12), id: \.id) { surah in
                    HStack {
                        Text("\(surah.id)").foregroundStyle(.secondary).monospacedDigit()
                        Text(surah.nameTransliteration)
                        Spacer()
                        Text(surah.nameArabic)
                    }
                }
            }
        }
        .navigationTitle("Inset order")
        .applyConditionalListStyle()
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: .constant(""))
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
        }
    }
}
#endif
#endif
