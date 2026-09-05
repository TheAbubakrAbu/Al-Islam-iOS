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
    Wallpaper(imageName: "Palestine Wallpaper", description: "FREE PALESTINE PHONE WALLPAPER"),
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
