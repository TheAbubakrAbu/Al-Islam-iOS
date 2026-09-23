import SwiftUI
#if os(iOS)
import Photos
#endif

private struct Wallpaper: Identifiable {
    let id = UUID()
    let imageName: String
    let description: String
}

private let wallpapers: [Wallpaper] = [
    // Abu's own photo composite of the Dome of the Rock, with "Free Palestine" / فلسطين and the
    // ayah of hope (2:214) burned into the pixels. Two DRAWN vector replacements shipped between
    // 2026-09-16 and 2026-09-18 (a redrawn wallpaper and a "Palestine Poster" beside it); both were
    // dropped 2026-09-23 and this one restored, so there is one Palestine wallpaper again and it is
    // his. `Scripts/build_palestine_wallpaper.py`, which rendered the drawn one, went with them.
    Wallpaper(imageName: "Palestine Wallpaper", description: "FREE PALESTINE PHONE WALLPAPER"),
    // OC Ummah's launch scene (its emerald desert night: crescent, pyramids, masjid) rendered as a
    // wallpaper, without the palms and with the pyramids grown (Abu, 2026-09-16). Above Al-Islam's
    // own wallpaper since 2026-09-18.
    Wallpaper(imageName: "OC Ummah Wallpaper", description: "OC UMMAH PHONE WALLPAPER"),
    Wallpaper(imageName: "Phone Wallpaper", description: "AL-ISLAM PHONE WALLPAPER"),
    Wallpaper(imageName: "Laptop Wallpaper", description: "LAPTOP (16:9) WALLPAPER"),
    Wallpaper(imageName: "Desktop Wallpaper", description: "DESKTOP (21:9) WALLPAPER")
]

struct WallpaperView: View {
    var body: some View {
        List {
            Group {
                wallpaperSections
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Wallpapers")
        #if DEBUG
        .onAppear { MemoryFootprint.logLater("wallpapers") }
        #endif
    }

    @ViewBuilder
    private var wallpaperSections: some View {
        ForEach(wallpapers) { wallpaper in
            WallpaperCell(wallpaper: wallpaper)
        }
    }
}

private struct WallpaperCell: View {
    let wallpaper: Wallpaper

    var body: some View {
        Section(header: Text(wallpaper.description)) {
            wallpaperImage
        }
    }

    private var wallpaperImage: some View {
        // Decoded at row width (Phase 6 step 4); Copy and Save below still take the full asset.
        DownsampledImage(wallpaper.imageName)
            .aspectRatio(contentMode: .fit)
            .cornerRadius(24)
            #if os(iOS)
            .contextMenu {
                Text("Image Actions")
                    .foregroundStyle(.secondary)

                Button {
                    Settings.shared.hapticFeedback()
                    if let uiImage = ImageThumbnails.fullImage(wallpaper.imageName) {
                        UIPasteboard.general.image = uiImage
                    }
                } label: {
                    Label("Copy Image", systemImage: "doc.on.doc")
                }

                Button {
                    Settings.shared.hapticFeedback()
                    guard let uiImage = ImageThumbnails.fullImage(wallpaper.imageName) else { return }

                    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                        guard status == .authorized || status == .limited else { return }
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
                        })
                    }
                } label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                }
            }
            #endif
    }
}

#Preview {
    AlIslamPreviewContainer {
        WallpaperView()
    }
}
