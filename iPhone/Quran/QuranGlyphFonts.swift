import SwiftUI

/// `QuranCommon` (quran-common.ttf), a King Fahd Complex glyph font where a whole ornament is ONE character
/// rather than a run of Arabic letters. Only the bismillah is used: it's drawn as the single calligraphic
/// ornament a mushaf prints at the head of a surah, which no text font can reproduce.
///
/// The font also carries Makkah/Madinah symbols at U+FC22 / U+FC23, but the app deliberately shows the 🕋 / 🕌
/// emoji for those instead — they read at small sizes and in a list, where the glyphs did not.
enum QuranGlyphFont {
    static let commonName = "quran-common"

    /// The full bismillah, drawn as one calligraphic ornament.
    static let bismillahOrnament = "\u{FDFD}"
}
