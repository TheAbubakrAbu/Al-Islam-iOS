import SwiftUI
import WidgetKit

struct LastListenedAyahWidget: Widget {
    let kind: String = "LastListenedAyahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranWidgetProvider(kind: .lastListenedAyah)) { entry in
            QuranWidgetEntryView(entry: entry)
        }
        .supportedFamilies(quranWidgetFamilies())
        .configurationDisplayName("Last Listened Ayah")
        .description("Shows the last single ayah or custom range you listened to")
        .disfavoredInCarPlay()
    }
}
