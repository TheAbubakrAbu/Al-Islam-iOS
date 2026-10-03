import SwiftUI
import WidgetKit

struct LastReadSurahWidget: Widget {
    let kind: String = "LastReadSurahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranWidgetProvider(kind: .lastReadAyah)) { entry in
            QuranWidgetEntryView(entry: entry)
        }
        .supportedFamilies(quranWidgetFamilies())
        .configurationDisplayName("Last Read Ayah")
        .description("Shows the ayah you last read")
        .disfavoredInCarPlay()
    }
}
