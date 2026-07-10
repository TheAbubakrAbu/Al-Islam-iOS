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
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        List {
            Group {
                wallpaperSections
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Wallpapers")
    }

    @ViewBuilder
    private var wallpaperSections: some View {
        ForEach(wallpapers) { wallpaper in
            WallpaperCell(wallpaper: wallpaper)
        }
    }
}

private struct WallpaperCell: View {
    @ObservedObject private var settings = Settings.shared

    let wallpaper: Wallpaper

    var body: some View {
        Section(header: Text(wallpaper.description)) {
            wallpaperImage
        }
    }

    private var wallpaperImage: some View {
        Image(wallpaper.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(24)
            #if os(iOS)
            .contextMenu {
                Text("Image Actions")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    if let uiImage = UIImage(named: wallpaper.imageName) {
                        UIPasteboard.general.image = uiImage
                    }
                } label: {
                    Label("Copy Image", systemImage: "doc.on.doc")
                }

                Button {
                    settings.hapticFeedback()
                    guard let uiImage = UIImage(named: wallpaper.imageName) else { return }

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
