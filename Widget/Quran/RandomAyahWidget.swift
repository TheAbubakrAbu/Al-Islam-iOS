import SwiftUI
import WidgetKit

struct AyahOfTheDayWidget: Widget {
    // Keep the original kind string so widgets users already placed as "Random Ayah" keep working after the rename.
    let kind: String = "RandomAyahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranWidgetProvider(kind: .ayahOfTheDay)) { entry in
            QuranWidgetEntryView(entry: entry)
        }
        .supportedFamilies(quranWidgetFamilies())
        .configurationDisplayName("Ayah of the Day")
        .description("Shows a different safe ayah from the Quran each day")
        .disfavoredInCarPlay()
    }
}
