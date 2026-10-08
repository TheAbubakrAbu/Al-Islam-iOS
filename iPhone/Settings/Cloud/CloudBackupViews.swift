#if os(iOS) && HAS_ICLOUD_BACKUP
import SwiftUI
import UniformTypeIdentifiers

// MARK: - The welcome offer (a root stage, after About You)

/// "Save your progress to iCloud?": one screen, once, right after the About You welcome
/// (docs/iCloud Sync Guide.md, section 8). Optional; "Not Now" is never asked again, the page in
/// Settings takes over from there. A stage and not a sheet for the reason About You is one: every
/// launch prompt waits behind it instead of racing it.
///
/// Three states, one screen: no iCloud account (explains, offers Not Now), an account with no
/// profiles yet (name this device, start), an account with profiles already in it (pick one to
/// restore onto this device, or start a new one).
struct CloudOfferView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var manager = CloudBackupManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dismiss) private var dismiss

    /// True when Settings shows it again as a sheet ("Set Up iCloud Backup").
    var presentedAsSheet = false

    @State private var nickname = CloudDevice.suggestedNickname
    @State private var checked = false
    @State private var working = false
    @State private var errorMessage: String?
    @State private var restoreCandidate: CloudBackupManager.ProfileSummary?

    private var isDarkMode: Bool { (settings.colorScheme ?? systemColorScheme) == .dark }
    private var accent: Color { settings.accentColor.color }

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        header
                        if !checked {
                            ProgressView().padding(.top, 24)
                        } else if manager.accountAvailable == false {
                            noAccountCard
                        } else {
                            if !manager.profiles.isEmpty { existingProfiles }
                            newProfileCard
                        }
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 22)
                    .padding(.top, presentedAsSheet ? 24 : 36)
                    .padding(.bottom, 16)
                }

                actions
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .task { await check() }
        .sheet(item: $restoreCandidate) { profile in
            CloudRestoreSheet(source: .profile(profile), claimAfterwards: true) { finish() }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "icloud.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(accent)
                .padding(.bottom, 2)

            Text("Save your progress to iCloud?")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Your bookmarks, prayer tracker, khatm, tasbih counts, journal and settings, kept in your own iCloud so a new \(CloudDevice.kind) can pick up where this one left off. Optional, and off until you turn it on. Your location is never included.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var noAccountCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Not signed in to iCloud", systemImage: "person.crop.circle.badge.exclamationmark")
                .font(.headline)
            Text("Sign in to iCloud in the Settings app, then turn on iCloud Backup in \(AppIdentifiers.appName)'s Settings whenever you like.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardSurface(selected: false))
    }

    private var existingProfiles: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ALREADY IN YOUR ICLOUD")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            ForEach(manager.profiles) { profile in
                Button {
                    settings.hapticFeedback()
                    restoreCandidate = profile
                } label: {
                    CloudProfileCard(profile: profile, isOwn: false, selected: false)
                }
                .buttonStyle(.plain)
                .disabled(working)
            }
            Text("Choosing one restores it onto this \(CloudDevice.kind) and carries it on from here.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)
        }
    }

    private var newProfileCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !manager.profiles.isEmpty {
                Text("OR START A NEW ONE")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Name this backup")
                    .font(.headline)
                TextField("Abu's iPhone", text: $nickname)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .disabled(working)
                Text(manager.profiles.count >= CloudBackupManager.maxProfiles
                     ? "You already have \(CloudBackupManager.maxProfiles) profiles. Delete one in Settings to add another."
                     : "Up to \(CloudBackupManager.maxProfiles) people or devices can share one iCloud account, each with a backup of their own.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardSurface(selected: true))
        }
    }

    private func cardSurface(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(selected ? accent.opacity(0.12) : Color(UIColor.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(selected ? accent.opacity(0.6) : Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private var canStart: Bool {
        checked && manager.accountAvailable == true && !working && manager.profiles.count < CloudBackupManager.maxProfiles
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if manager.accountAvailable != false {
                Button {
                    settings.hapticFeedback()
                    start()
                } label: {
                    HStack(spacing: 8) {
                        if working { ProgressView().tint(.primary) }
                        Text(working ? "Saving..." : (manager.profiles.isEmpty ? "Save to iCloud" : "Start a New Backup"))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .conditionalGlassEffect(rectangle: true, useColor: 0.38, customTint: AppIdentifiers.mainColor.color)
                .disabled(!canStart)
                .opacity(canStart ? 1 : 0.5)
            }

            Button {
                settings.hapticFeedback()
                finish()
            } label: {
                Text(manager.accountAvailable == false ? "Continue" : "Not Now")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(working)
        }
    }

    private func check() async {
        guard !checked else { return }
        if await manager.refreshAccountStatus() {
            _ = try? await manager.listProfiles()
        }
        checked = true
    }

    private func start() {
        working = true
        errorMessage = nil
        Task {
            do {
                try await manager.createProfile(nickname: nickname)
                finish()
            } catch {
                errorMessage = error.localizedDescription
            }
            working = false
        }
    }

    /// Ends the stage (or the sheet). Answered or skipped, the offer is not made again.
    private func finish() {
        if presentedAsSheet {
            dismiss()
            return
        }
        withAnimation {
            settings.cloudOfferVersionSeen = Settings.cloudOfferCurrentVersion
        }
    }

    private var backdrop: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemBackground)
            RadialGradient(
                colors: [accent.opacity(isDarkMode ? 0.22 : 0.14), .clear],
                center: .top, startRadius: 10, endRadius: 380
            )
            .frame(height: 420)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - One profile, as a card

struct CloudProfileCard: View {
    @Environment(\.appearance) private var appearance
    let profile: CloudBackupManager.ProfileSummary
    let isOwn: Bool
    let selected: Bool

    private var accent: Color { appearance.accent }

    private var deviceSymbol: String {
        switch profile.deviceKind {
        case "iPad": return "ipad"
        case "Mac": return "desktopcomputer"
        default: return "iphone"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            AccentIconChip(systemImage: deviceSymbol, size: 40)
            details
            Spacer(minLength: 8)
            trailing
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(surface)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(profile.nickname)
                    .font(.headline)
                    .foregroundColor(.primary)
                if isOwn {
                    Text("This \(CloudDevice.kind)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(accent.opacity(0.18)))
                }
            }
            // Leading on purpose: inside a Menu's label a wrapped line centred itself.
            Text(Self.detailLine(profile))
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            if !profile.summary.isEmpty {
                Text(profile.summary)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if selected {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(accent)
        } else if profile.isNewerThanThisApp {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .accessibilityLabel("Made by a newer version of the app")
        }
    }

    private var surface: some View {
        let fill: Color = selected ? accent.opacity(0.16) : Color(UIColor.secondarySystemBackground)
        let stroke: Color = selected ? accent : Color.primary.opacity(0.08)
        return RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(stroke, lineWidth: selected ? 2 : 1)
            )
    }

    static func detailLine(_ profile: CloudBackupManager.ProfileSummary) -> String {
        var parts = [profile.deviceKind.isEmpty ? "Device" : profile.deviceKind]
        parts.append("saved " + relative(profile.updatedAt))
        if profile.payloadBytes > 0 { parts.append(ByteCountFormatter.string(fromByteCount: Int64(profile.payloadBytes), countStyle: .file)) }
        return parts.joined(separator: " · ")
    }

    static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Restore: what changes, and how?

/// The one question every restore asks (decision 4 of the guide): Replace, or Merge. Since round
/// two it downloads the backup FIRST and shows it against this device category by category
/// (`ContentInventory`), so the choice is made with the numbers in view. `claimAfterwards` makes
/// this device the profile's writer once the restore lands (the welcome's "this is mine" and
/// Settings' "switch to this profile"); a file is never claimed.
struct CloudRestoreSheet: View {
    enum Source {
        case profile(CloudBackupManager.ProfileSummary)
        case file(name: String, snapshot: CloudSnapshot, bytes: Int)
    }

    @ObservedObject private var manager = CloudBackupManager.shared
    @Environment(\.dismiss) private var dismiss

    let source: Source
    var claimAfterwards: Bool
    var onDone: (() -> Void)? = nil

    @State private var mode: CloudSnapshot.RestoreMode = .replace
    @State private var working = false
    @State private var errorMessage: String?
    @State private var snapshot: CloudSnapshot?
    @State private var backup: ContentInventory?
    @State private var local: ContentInventory?
    @State private var loadError: String?

    init(source: Source, claimAfterwards: Bool, onDone: (() -> Void)? = nil) {
        self.source = source
        self.claimAfterwards = claimAfterwards
        self.onDone = onDone
        if case .file(_, let snapshot, let bytes) = source {
            _snapshot = State(initialValue: snapshot)
            _backup = State(initialValue: ContentInventory(snapshot, bytes: bytes))
        }
    }

    /// The card at the top: the profile, or the file described the same way.
    private var card: CloudBackupManager.ProfileSummary {
        switch source {
        case .profile(let profile):
            return profile
        case .file(let name, let snapshot, let bytes):
            return CloudBackupManager.ProfileSummary(
                id: "file", nickname: name, deviceKind: snapshot.deviceKind, ownerDeviceID: snapshot.deviceID,
                updatedAt: snapshot.createdAt, schemaVersion: snapshot.schemaVersion, appVersion: snapshot.appVersion,
                payloadBytes: bytes, summary: snapshot.summaryLine)
        }
    }

    private var isFile: Bool {
        if case .file = source { return true }
        return false
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    CloudProfileCard(profile: card, isOwn: !isFile && manager.isOwn(card), selected: false)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .listRowBackground(Color.clear)
                }

                changesSection

                Section(header: Text("HOW"), footer: Text(footer)) {
                    choice(.replace, title: "Replace", subtitle: "This \(CloudDevice.kind) becomes the backup: its content and its settings. What is here now is replaced.", systemImage: "arrow.triangle.2.circlepath")
                    choice(.merge, title: "Merge", subtitle: "The backup's bookmarks, marks and counts are added to what is here. Your settings on this \(CloudDevice.kind) stay as they are.", systemImage: "arrow.triangle.merge")
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundColor(.red) }
                }

                Section {
                    Button {
                        Settings.shared.hapticFeedback()
                        restore()
                    } label: {
                        HStack {
                            Spacer()
                            if working { ProgressView().padding(.trailing, 6) }
                            Text(working ? "Restoring..." : (mode == .replace ? "Replace and Restore" : "Merge and Restore"))
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(working || card.isNewerThanThisApp || snapshot == nil)
                }
            }
            .navigationTitle("Restore")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            .interactiveDismissDisabled(working)
            .task { await load() }
        }
    }

    // MARK: The preview

    @ViewBuilder
    private var changesSection: some View {
        Section(header: changesHeader, footer: Text(changesFooter)) {
            if let loadError {
                Text(loadError).font(.footnote).foregroundColor(.red)
            } else if let backup, let local {
                let rows = zip(local.rows, backup.rows).filter { !$0.0.isEmpty || !$0.1.isEmpty }
                if rows.isEmpty {
                    Text("Neither side holds any content yet: only settings.").foregroundColor(.secondary)
                }
                ForEach(rows, id: \.0.id) { here, there in
                    CloudComparisonRow(title: here.category.title, noun: here.measure.plural, systemImage: here.category.systemImage,
                                       here: here.measure.count, backup: there.measure.count)
                }
                CloudComparisonRow(title: "Settings", noun: "changed from the default", systemImage: "slider.horizontal.3",
                                   here: local.settingsChanged, backup: backup.settingsChanged, dimmed: mode == .merge)
            } else {
                HStack { Spacer(); ProgressView(); Spacer() }
            }
        }
    }

    private var changesHeader: some View {
        HStack(spacing: 0) {
            Text("WHAT CHANGES")
            Spacer(minLength: 8)
            Text("HERE")
                .lineLimit(1).minimumScaleFactor(0.6)
                .frame(width: CloudComparisonRow.columnWidth, alignment: .trailing)
            Text(isFile ? "FILE" : "BACKUP")
                .lineLimit(1).minimumScaleFactor(0.6)
                .frame(width: CloudComparisonRow.columnWidth, alignment: .trailing)
        }
    }

    private var changesFooter: String {
        guard backup != nil, local != nil else { return "" }
        switch mode {
        case .replace:
            return "After Replace this \(CloudDevice.kind) holds the \(isFile ? "file" : "backup") column, settings included."
        case .merge:
            return "After Merge each line is at least the larger of the two: the \(isFile ? "file" : "backup")'s things are added to what is here, item by item. The settings here stay as they are."
        }
    }

    private func load() async {
        guard snapshot == nil, case .profile(let profile) = source else {
            if local == nil { local = ContentInventory.current() }
            return
        }
        do {
            let downloaded = try await manager.download(profile)
            snapshot = downloaded
            backup = ContentInventory(downloaded, bytes: profile.payloadBytes)
            local = ContentInventory.current()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private var footer: String {
        if card.isNewerThanThisApp { return "This backup was made by a newer version of \(AppIdentifiers.appName). Update the app, then restore." }
        var text = "A Merge never removes anything from this \(CloudDevice.kind). Something you deleted here that is still in the backup comes back."
        if claimAfterwards, !isFile { text += " Afterwards this \(CloudDevice.kind) keeps this profile up to date." }
        return text
    }

    private func choice(_ value: CloudSnapshot.RestoreMode, title: String, subtitle: String, systemImage: String) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            mode = value
        } label: {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: systemImage, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundColor(.primary)
                    Text(subtitle).font(.footnote).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: mode == value ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(mode == value ? Settings.shared.accentColor.color : Color.secondary.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func restore() {
        guard let snapshot else { return }
        working = true
        errorMessage = nil
        Task {
            do {
                switch source {
                case .profile(let profile):
                    try await manager.restore(snapshot, from: profile, mode: mode, claim: claimAfterwards)
                case .file(let name, _, _):
                    manager.restore(file: snapshot, named: name, mode: mode)
                }
                dismiss()
                onDone?()
            } catch {
                errorMessage = error.localizedDescription
            }
            working = false
        }
    }
}

/// One line of the restore preview: a category, this device's count, the backup's count.
struct CloudComparisonRow: View {
    static let columnWidth: CGFloat = 70

    let title: String
    let noun: String
    let systemImage: String
    let here: Int
    let backup: Int
    /// Merge leaves the settings alone: the row stays, greyed, so the reader sees it was considered.
    var dimmed = false

    var body: some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline).foregroundColor(.primary)
                // "Bookmarks / bookmarks" says nothing twice; "Tasbih / dhikr" says what is counted.
                if noun.lowercased() != title.lowercased() {
                    Text(noun).font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 4)
            Text(ContentCategory.Measure.formatted(here))
                .font(.subheadline.monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: Self.columnWidth, alignment: .trailing)
            Text(ContentCategory.Measure.formatted(backup))
                .font(.subheadline.monospacedDigit().weight(backup > here ? .semibold : .regular))
                .foregroundColor(.primary)
                .frame(width: Self.columnWidth, alignment: .trailing)
        }
        .opacity(dimmed ? 0.45 : 1)
    }
}

// MARK: - Settings: iCloud Backup

/// The row under Your Progress and About You.
struct CloudBackupSettingsRow: View {
    @ObservedObject private var manager = CloudBackupManager.shared
    var tint: Color? = nil
    var secondaryTint: Color? = nil

    var body: some View {
        NavigationLink(destination: LazyDestination { CloudBackupSettingsView() }) {
            SettingsRowLabel(title: "iCloud Backup", systemImage: "icloud.fill",
                             subtitle: "Profiles, restore, what's included, backup file",
                             tint: tint, secondaryTint: secondaryTint,
                             value: manager.isEnabled ? "On" : "Off")
        }
        .tint(Settings.shared.accentColor.color)
    }
}

struct CloudBackupSettingsView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var manager = CloudBackupManager.shared

    @State private var showOffer = false
    @State private var renaming = false
    @State private var newName = ""
    @State private var restoreCandidate: CloudBackupManager.ProfileSummary?
    @State private var switchCandidate: CloudBackupManager.ProfileSummary?
    @State private var fileCandidate: FileCandidate?
    @State private var importing = false
    /// Shown beside the file buttons, where the tap was: a refused file must not report at the top
    /// of a page scrolled to its bottom.
    @State private var fileMessage: String?
    @State private var errorMessage: String?
    @State private var listing = false
    @State private var inventory: ContentInventory?

    /// A backup file the user picked, decoded and waiting for the restore sheet.
    struct FileCandidate: Identifiable {
        let name: String
        let snapshot: CloudSnapshot
        let bytes: Int
        var id: String { name + "\(bytes)" }
    }

    var body: some View {
        List {
            statusSection
            if manager.isEnabled { profileSection }
            contentsSection
            profilesSection
            fileSection
            aboutSection
        }
        .navigationTitle("iCloud Backup")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh() }
        .refreshable { await refresh() }
        .sheet(isPresented: $showOffer) {
            CloudOfferView(presentedAsSheet: true)
                .onDisappear { Task { await refresh() } }
        }
        .sheet(item: $restoreCandidate) { profile in
            CloudRestoreSheet(source: .profile(profile), claimAfterwards: false) { Task { await refresh() } }
        }
        .sheet(item: $switchCandidate) { profile in
            CloudRestoreSheet(source: .profile(profile), claimAfterwards: true) { Task { await refresh() } }
        }
        .sheet(item: $fileCandidate) { file in
            CloudRestoreSheet(source: .file(name: file.name, snapshot: file.snapshot, bytes: file.bytes), claimAfterwards: false) { Task { await refresh() } }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item]) { result in
            pickedFile(result)
        }
        .alert("Rename Profile", isPresented: $renaming) {
            TextField("Name", text: $newName)
            Button("Rename") { rename() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The name shown when choosing a profile to restore.")
        }
    }

    // MARK: Sections

    private var statusSection: some View {
        Section(footer: Text(statusFooter)) {
            if manager.isEnabled {
                HStack {
                    Label("Backing Up", systemImage: "icloud.fill")
                    Spacer()
                    if manager.isBusy {
                        ProgressView()
                    } else if let saved = manager.lastSavedAt {
                        Text(CloudProfileCard.relative(saved)).foregroundColor(.secondary)
                    } else {
                        Text("Not yet").foregroundColor(.secondary)
                    }
                }
                Button {
                    settings.hapticFeedback()
                    backUpNow()
                } label: {
                    Label("Back Up Now", systemImage: "arrow.clockwise.icloud")
                }
                .disabled(manager.isBusy || manager.status == .takenOver)
            } else {
                Button {
                    settings.hapticFeedback()
                    showOffer = true
                } label: {
                    Label("Set Up iCloud Backup", systemImage: "icloud.and.arrow.up")
                }
            }
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundColor(.red)
            }
        }
    }

    private var statusFooter: String {
        if manager.isEnabled {
            switch manager.status {
            case .idle, .saved, .saving:
                var text = "Saved automatically when you leave the app, if something changed."
                if manager.lastSavedAt != nil, manager.lastSavedBytes > 0 {
                    let size = ByteCountFormatter.string(fromByteCount: Int64(manager.lastSavedBytes), countStyle: .file)
                    text += " Last backup \(size), \(manager.lastSavedAutomatically ? "automatic" : "with Back Up Now")."
                }
                return text + " Your location is never included."
            default:
                return manager.status.line
            }
        }
        return "Keep your bookmarks, prayer tracker, khatm, tasbih counts, journal and settings in your own iCloud. Your location is never included."
    }

    private var profileSection: some View {
        Section(header: Text("THIS \(CloudDevice.kind.uppercased())'S PROFILE")) {
            HStack {
                Text("Name")
                Spacer()
                Text(manager.nickname).foregroundColor(.secondary)
            }
            Button("Rename") {
                newName = manager.nickname
                renaming = true
            }
            Button("Stop Backing Up on This \(CloudDevice.kind)", role: .destructive) {
                settings.hapticFeedback()
                RemovalConfirmation.present(
                    title: "Stop backing up?",
                    message: "This \(CloudDevice.kind) stops saving to iCloud. The profile \u{201C}\(manager.nickname)\u{201D} stays in iCloud and can be restored later.",
                    confirmTitle: "Stop Backing Up"
                ) { manager.disable() }
            }
        }
    }

    /// What a backup of this device holds right now, and what has happened so far.
    private var contentsSection: some View {
        Section(header: Text("WHAT GETS BACKED UP")) {
            NavigationLink(destination: LazyDestination { CloudContentsView() }) {
                // The size leads the caption rather than sitting at the trailing edge: a long
                // summary squeezed "6 KB" down to "6" there.
                SettingsRowLabel(title: "What's Included", systemImage: "list.bullet.rectangle.fill",
                                 subtitle: inventory.map { "\($0.sizeLine) \u{00B7} \($0.summaryLine)" } ?? "Everything you made, category by category")
            }
            if manager.isEnabled || !manager.history.isEmpty {
                NavigationLink(destination: LazyDestination { CloudHistoryView() }) {
                    SettingsRowLabel(title: "History", systemImage: "clock.arrow.circlepath",
                                     subtitle: manager.latestEventLine ?? "Nothing yet")
                }
            }
        }
    }

    private var profilesSection: some View {
        Section(header: Text("PROFILES IN YOUR ICLOUD"), footer: Text(profilesFooter)) {
            if listing && manager.profiles.isEmpty {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if manager.profiles.isEmpty {
                Text(manager.accountAvailable == false ? "Sign in to iCloud in the Settings app to see your profiles." : "No profiles yet.")
                    .foregroundColor(.secondary)
            }
            ForEach(manager.profiles) { profile in
                Menu {
                    Button {
                        restoreCandidate = profile
                    } label: {
                        Label("Restore onto This \(CloudDevice.kind)", systemImage: "arrow.down.circle")
                    }
                    if !manager.isOwn(profile) {
                        Button {
                            switchCandidate = profile
                        } label: {
                            Label("Restore and Switch to This Profile", systemImage: "arrow.triangle.swap")
                        }
                    }
                    Button(role: .destructive) {
                        confirmDelete(profile)
                    } label: {
                        Label("Delete from iCloud", systemImage: "trash")
                    }
                } label: {
                    CloudProfileCard(profile: profile, isOwn: manager.isOwn(profile), selected: false)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }

    private var profilesFooter: String {
        "Up to \(CloudBackupManager.maxProfiles) profiles. Each device backs up to its own; restoring another profile's things onto this \(CloudDevice.kind) never changes that profile. Tap a profile for its options; every restore shows what changes first."
    }

    /// The same backup as a file the user keeps: for a family member moving to an Apple ID of their
    /// own, or for anyone who does not use iCloud.
    private var fileSection: some View {
        Section(header: Text("BACKUP FILE"), footer: Text("A file you keep yourself, holding the same things as an iCloud backup. AirDrop it to a family member's \(CloudDevice.kind) or save it in Files, then restore it from here: it asks the same Replace or Merge question and shows what changes first.")) {
            Button {
                settings.hapticFeedback()
                exportFile()
            } label: {
                Label("Export a Backup File", systemImage: "square.and.arrow.up")
            }
            Button {
                settings.hapticFeedback()
                fileMessage = nil
                importing = true
            } label: {
                Label("Restore from a File", systemImage: "doc.badge.arrow.up")
            }
            if let fileMessage {
                Text(fileMessage).font(.footnote).foregroundColor(.red)
            }
        }
    }

    private var aboutSection: some View {
        Section(footer: Text("Backups live in your private iCloud database. Nobody else can read them, and nothing is sent anywhere else. Downloaded recitations are not included; they can be downloaded again.")) {
            EmptyView()
        }
    }

    // MARK: Actions

    private func refresh() async {
        listing = true
        errorMessage = nil
        inventory = ContentInventory.current()
        if await manager.refreshAccountStatus() {
            do { _ = try await manager.listProfiles() } catch { errorMessage = error.localizedDescription }
        }
        listing = false
    }

    private func backUpNow() {
        errorMessage = nil
        Task {
            do { try await manager.backUpNow() } catch { errorMessage = error.localizedDescription }
        }
    }

    private func rename() {
        Task {
            do { try await manager.rename(newName) } catch { errorMessage = error.localizedDescription }
        }
    }

    private func exportFile() {
        fileMessage = nil
        do {
            let url = try manager.exportFile()
            presentSystemShareSheet(items: [url])
        } catch {
            fileMessage = error.localizedDescription
        }
    }

    private func pickedFile(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            fileMessage = error.localizedDescription
        case .success(let url):
            do {
                let imported = try CloudBackupManager.importFile(url)
                fileCandidate = FileCandidate(name: url.lastPathComponent, snapshot: imported.snapshot, bytes: imported.bytes)
            } catch {
                fileMessage = "\u{201C}\(url.lastPathComponent)\u{201D}: \(error.localizedDescription)"
                manager.noteRefusedFile(url.lastPathComponent, reason: error.localizedDescription)
            }
        }
    }

    private func confirmDelete(_ profile: CloudBackupManager.ProfileSummary) {
        let own = manager.isOwn(profile)
        RemovalConfirmation.present(
            title: "Delete \u{201C}\(profile.nickname)\u{201D} from iCloud?",
            message: (profile.summary.isEmpty ? "" : "It holds \(profile.summary). ")
                + (own ? "This is this \(CloudDevice.kind)'s own profile; backing up here stops too. " : "")
                + "This cannot be undone.",
            confirmTitle: "Delete Profile"
        ) {
            Task {
                do { try await manager.delete(profile) } catch { errorMessage = error.localizedDescription }
            }
        }
    }
}

// MARK: - What's Included

/// What a backup of this device holds right now, category by category, and what one never holds.
struct CloudContentsView: View {
    @State private var inventory: ContentInventory?

    var body: some View {
        List {
            Section(header: Text("ON THIS \(CloudDevice.kind.uppercased()) NOW"), footer: Text(footer)) {
                if let inventory {
                    ForEach(inventory.rows) { row in
                        line(row.category.title, systemImage: row.category.systemImage,
                             value: row.isEmpty ? "None yet" : row.measure.phrase, empty: row.isEmpty)
                    }
                    line("Settings", systemImage: "slider.horizontal.3",
                         value: inventory.settingsChanged == 0 ? "All at their defaults" : "\(inventory.settingsChanged) changed",
                         empty: inventory.settingsChanged == 0)
                } else {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            }

            Section(header: Text("NEVER INCLUDED")) {
                ForEach(ContentCategory.neverIncluded, id: \.title) { item in
                    HStack(alignment: .top, spacing: 12) {
                        AccentIconChip(systemImage: item.systemImage, size: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.subheadline).foregroundColor(.primary)
                            Text(item.detail).font(.footnote).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("What's Included")
        .navigationBarTitleDisplayMode(.inline)
        .task { inventory = ContentInventory.current() }
    }

    private var footer: String {
        guard let inventory else { return "" }
        var text = "Together \(inventory.sizeLine), compressed. Every backup is this whole set, saved again whenever something changed."
        if inventory.settingsChanged > 0 {
            text += " Only settings you changed are included, so a setting still at its default follows the app's default on every device."
        }
        return text
    }

    private func line(_ title: String, systemImage: String, value: String, empty: Bool) -> some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage, size: 30)
            Text(title).font(.subheadline).foregroundColor(.primary)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .opacity(empty ? 0.7 : 1)
        }
    }
}

// MARK: - History

/// Every save, skipped save, restore, export, failure and change of claim: the last 30, on this device.
struct CloudHistoryView: View {
    @ObservedObject private var manager = CloudBackupManager.shared

    var body: some View {
        List {
            Section(footer: Text("Kept on this \(CloudDevice.kind) only, the last \(CloudBackupManager.historyLimit) events. Nothing here is sent anywhere.")) {
                if manager.history.isEmpty {
                    Text("Nothing yet.").foregroundColor(.secondary)
                }
                ForEach(manager.history) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: event.systemImage)
                            .font(.body)
                            .foregroundColor(event.isProblem ? .orange : Settings.shared.accentColor.color)
                            .frame(width: 26, alignment: .center)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.line).font(.subheadline).foregroundColor(.primary).fixedSize(horizontal: false, vertical: true)
                            Text(Self.stamp(event.at)).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    static func stamp(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

extension SettingsSearchEntry {
    static let cloudBackupEntries: [SettingsSearchEntry] = [
        .init(title: "iCloud Backup", path: "Settings", keywords: "icloud backup sync save restore transfer new phone device profile family cloud export import progress data", destination: .cloudBackup),
        .init(title: "Back Up Now", path: "Settings → iCloud Backup", keywords: "icloud backup now save upload manual", destination: .cloudBackup),
        .init(title: "Restore from a Profile", path: "Settings → iCloud Backup", keywords: "icloud restore replace merge profile new phone transfer bookmarks tracker preview what changes", destination: .cloudBackup),
        .init(title: "What's Included in a Backup", path: "Settings → iCloud Backup", keywords: "icloud backup included contents what size categories never location privacy", destination: .cloudBackup),
        .init(title: "Backup History", path: "Settings → iCloud Backup", keywords: "icloud backup history log when last saved failed events", destination: .cloudBackup),
        .init(title: "Export a Backup File", path: "Settings → iCloud Backup", keywords: "backup file export share airdrop save files transfer without icloud", destination: .cloudBackup),
        .init(title: "Restore from a Backup File", path: "Settings → iCloud Backup", keywords: "backup file import restore open files airdrop transfer without icloud", destination: .cloudBackup),
        .init(title: "Stop Backing Up on This Device", path: "Settings → iCloud Backup", keywords: "icloud backup off stop disable turn off", destination: .cloudBackup),
    ]
}
#endif
