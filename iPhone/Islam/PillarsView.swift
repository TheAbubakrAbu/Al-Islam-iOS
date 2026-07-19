import SwiftUI

struct PillarsView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("THE BASICS")) {
                    NavigationLink(destination: LazyDestination { GodPillarView() }) {
                        Text("Does God Exist?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { IslamPillarView() }) {
                        Text("What is Islam?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { MuslimPillarView() }) {
                        Text("What is a Muslim?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { AllahPillarView() }) {
                        Text("Who is Allah ﷻ‎?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { QuranPillarView() }) {
                        Text("What is the Quran?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { ProphetPillarView() }) {
                        Text("Who is Prophet Muhammad ﷺ?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { SunnahPillarView() }) {
                        Text("What is the Sunnah?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { HadithPillarView() }) {
                        Text("What are Hadiths?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }

                IslamicPillarsView()

                ImanPillarsView()

                MosquesView()

                BeliefsQuranView()

                BeliefsHistoricalView()
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Pillars & Beliefs")
    }
}

/// The practical "how-to" companion to `PillarsView`: step-by-step guides to the acts of worship.
/// A quoted ayah or hadith in the Beliefs and How-to guides: the larger accented text every guide uses,
/// now one reusable view with a context menu to copy the full quote - source included (the citation is
/// part of the text itself, e.g. "(Quran 2:43)" or "(Sahih al-Bukhari 631)").
struct ScriptureQuote: View {
    @ObservedObject private var settings = Settings.shared

    let text: String
    /// Hadith quotes render slightly softened (0.85 opacity) so ayat keep the fullest accent.
    var dimmed: Bool = false

    var body: some View {
        let quote = Text(text)
            .font(.title3)
            .foregroundColor(settings.accentColor.color.opacity(dimmed ? 0.85 : 1))
        #if os(iOS)
        quote
            .contextMenu {
                Text("Copy")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = text
                } label: {
                    Label("Copy Quote", systemImage: "doc.on.doc")
                }
            }
        #else
        quote
        #endif
    }
}
