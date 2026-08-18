import SwiftUI

#if os(iOS)
import UIKit

// MARK: - Badges

/// Achievements as thresholds on `ProfileStats`, plus a one-way unlock ledger.
///
/// The thresholds are still pure functions of data the app already keeps - nothing here is newly
/// tracked - but the UNLOCK is now recorded (`AchievementsStore`) rather than re-derived. That change
/// exists because the old purely-derived design had a real defect: marking a prayer earned "First
/// Steps", and unmarking it took the badge away again. An achievement is a record of something you
/// did, not a description of the current state of your data, so once the threshold is crossed the
/// ledger keeps it. The threshold is still what CROSSES it, so nothing can be unlocked that wasn't
/// genuinely reached.
///
/// Progress on a locked badge is still live: an unearned tile shows how far along the underlying
/// number is right now, which is the only thing that makes rendering a locked tile worthwhile.
enum AlIslamBadge: String, CaseIterable, Identifiable {
    // Prayer - streaks, perfect days, lifetime totals, coverage.
    case firstPrayer, threeDayStreak, weekOfSalah, fortnightOfSalah, monthOfSalah, fiftyDayStreak
    case steadfast, halfYearOfSalah, yearOfSalah
    case perfectDay, perfectTen, perfectFifty, perfectHundred, perfectYear
    case prayers100, prayers500, prayers1000, prayers5000
    case monthRecorded, yearRecorded, consistency

    // Quran - reading, completion, the planner.
    case openedTheBook, ayahs100, ayahs500
    case juzDone, fiveJuz, tenJuz, halfway, twentyJuz, threeQuarters, khatm
    case firstSurahComplete, tenSurahsComplete, thirtySurahsComplete, sixtySurahsComplete, allSurahsComplete
    case browsing, halfTheSurahs, everySurahOpened, frequentReader, devotedReader
    case planWeek, planMonth, planHundred

    // Listening
    case firstListen, listener, devotedListener, audiophile
    case earForVoices, reciterCollector

    // Library - bookmarks, notes, highlights, favorites.
    case firstBookmark, collector, archivist, curator
    case firstNote, annotator, commentator, scribe
    case firstHighlight, highlighter, illuminator, fullPalette
    case keptClose, wellLoved

    // Hadith
    case firstHadithBook, hadithReader, hadithShelf, wholeShelf
    case firstHadithBookmark, hadithScholar, hadithArchivist, hadithFavorites

    // Dhikr
    case oneTasbih, dhikrHundred, dhikrFiveHundred, dhikrThousand
    case dhikrFiveThousand, dhikrTenThousand, dhikrHundredThousand

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstPrayer:          return "First Steps"
        case .threeDayStreak:       return "Getting Going"
        case .weekOfSalah:          return "Week of Salah"
        case .fortnightOfSalah:     return "Fortnight"
        case .monthOfSalah:         return "Month of Salah"
        case .fiftyDayStreak:       return "Fifty Days"
        case .steadfast:            return "Steadfast"
        case .halfYearOfSalah:      return "Half a Year"
        case .yearOfSalah:          return "Year of Salah"
        case .perfectDay:           return "A Perfect Day"
        case .perfectTen:           return "Ten Perfect Days"
        case .perfectFifty:         return "Fifty Perfect Days"
        case .perfectHundred:       return "A Hundred Perfect Days"
        case .perfectYear:          return "A Perfect Year"
        case .prayers100:           return "A Hundred Prayers"
        case .prayers500:           return "Five Hundred Prayers"
        case .prayers1000:          return "A Thousand Prayers"
        case .prayers5000:          return "Five Thousand Prayers"
        case .monthRecorded:        return "A Month Recorded"
        case .yearRecorded:         return "A Year Recorded"
        case .consistency:          return "Consistency"

        case .openedTheBook:        return "Opened the Book"
        case .ayahs100:             return "A Hundred Ayahs"
        case .ayahs500:             return "Five Hundred Ayahs"
        case .juzDone:              return "A Juz' In"
        case .fiveJuz:              return "Five Juz'"
        case .tenJuz:               return "Ten Juz'"
        case .halfway:              return "Halfway"
        case .twentyJuz:            return "Twenty Juz'"
        case .threeQuarters:        return "Three Quarters"
        case .khatm:                return "Khatm"
        case .firstSurahComplete:   return "First Surah"
        case .tenSurahsComplete:    return "Ten Surahs"
        case .thirtySurahsComplete: return "Thirty Surahs"
        case .sixtySurahsComplete:  return "Sixty Surahs"
        case .allSurahsComplete:    return "Every Surah Finished"
        case .browsing:             return "Browsing"
        case .halfTheSurahs:        return "Half the Surahs"
        case .everySurahOpened:     return "Every Surah Opened"
        case .frequentReader:       return "Frequent Reader"
        case .devotedReader:        return "Devoted Reader"
        case .planWeek:             return "A Week on Plan"
        case .planMonth:            return "A Month on Plan"
        case .planHundred:          return "A Hundred Days on Plan"

        case .firstListen:          return "First Listen"
        case .listener:             return "Listener"
        case .devotedListener:      return "Devoted Listener"
        case .audiophile:           return "Always Listening"
        case .earForVoices:         return "An Ear for Voices"
        case .reciterCollector:     return "Reciter Collector"

        case .firstBookmark:        return "First Bookmark"
        case .collector:            return "Collector"
        case .archivist:            return "Archivist"
        case .curator:              return "Curator"
        case .firstNote:            return "First Note"
        case .annotator:            return "Annotator"
        case .commentator:          return "Commentator"
        case .scribe:               return "Scribe"
        case .firstHighlight:       return "First Highlight"
        case .highlighter:          return "Highlighter"
        case .illuminator:          return "Illuminator"
        case .fullPalette:          return "Full Palette"
        case .keptClose:            return "Kept Close"
        case .wellLoved:            return "Well Loved"

        case .firstHadithBook:      return "First Collection"
        case .hadithReader:         return "Hadith Reader"
        case .hadithShelf:          return "Shelf Reader"
        case .wholeShelf:           return "The Whole Shelf"
        case .firstHadithBookmark:  return "First Narration Kept"
        case .hadithScholar:        return "Hadith Scholar"
        case .hadithArchivist:      return "Hadith Archivist"
        case .hadithFavorites:      return "Favorite Collections"

        case .oneTasbih:            return "One Tasbih"
        case .dhikrHundred:         return "A Hundred Remembrances"
        case .dhikrFiveHundred:     return "Five Hundred Remembrances"
        case .dhikrThousand:        return "A Thousand Remembrances"
        case .dhikrFiveThousand:    return "Five Thousand Remembrances"
        case .dhikrTenThousand:     return "Ten Thousand Remembrances"
        case .dhikrHundredThousand: return "A Hundred Thousand Remembrances"
        }
    }

    var detail: String {
        switch self {
        case .firstPrayer:          return "Mark your first prayer"
        case .threeDayStreak:       return "A 3-day prayer streak"
        case .weekOfSalah:          return "A 7-day prayer streak"
        case .fortnightOfSalah:     return "A 14-day prayer streak"
        case .monthOfSalah:         return "A 30-day prayer streak"
        case .fiftyDayStreak:       return "A 50-day prayer streak"
        case .steadfast:            return "A 100-day prayer streak"
        case .halfYearOfSalah:      return "A 182-day prayer streak"
        case .yearOfSalah:          return "A 365-day prayer streak"
        case .perfectDay:           return "One day with all five prayers"
        case .perfectTen:           return "10 days with all five prayers"
        case .perfectFifty:         return "50 days with all five prayers"
        case .perfectHundred:       return "100 days with all five prayers"
        case .perfectYear:          return "365 days with all five prayers"
        case .prayers100:           return "Mark 100 prayers"
        case .prayers500:           return "Mark 500 prayers"
        case .prayers1000:          return "Mark 1,000 prayers"
        case .prayers5000:          return "Mark 5,000 prayers"
        case .monthRecorded:        return "30 days in the prayer tracker"
        case .yearRecorded:         return "365 days in the prayer tracker"
        case .consistency:          return "80% coverage over at least 30 days"

        case .openedTheBook:        return "Mark your first ayah read"
        case .ayahs100:             return "Read 100 ayahs"
        case .ayahs500:             return "Read 500 ayahs"
        case .juzDone:              return "Read a thirtieth of the Quran"
        case .fiveJuz:              return "Read a sixth of the Quran"
        case .tenJuz:               return "Read a third of the Quran"
        case .halfway:              return "Read half of the Quran"
        case .twentyJuz:            return "Read two thirds of the Quran"
        case .threeQuarters:        return "Read three quarters of the Quran"
        case .khatm:                return "Complete the Quran"
        case .firstSurahComplete:   return "Finish a whole surah"
        case .tenSurahsComplete:    return "Finish 10 surahs"
        case .thirtySurahsComplete: return "Finish 30 surahs"
        case .sixtySurahsComplete:  return "Finish 60 surahs"
        case .allSurahsComplete:    return "Finish all 114 surahs"
        case .browsing:             return "Open 10 different surahs"
        case .halfTheSurahs:        return "Open 57 different surahs"
        case .everySurahOpened:     return "Open all 114 surahs"
        case .frequentReader:       return "100 surah openings"
        case .devotedReader:        return "1,000 surah openings"
        case .planWeek:             return "A 7-day reading-plan streak"
        case .planMonth:            return "A 30-day reading-plan streak"
        case .planHundred:          return "A 100-day reading-plan streak"

        case .firstListen:          return "Play your first surah"
        case .listener:             return "50 surahs played"
        case .devotedListener:      return "500 surahs played"
        case .audiophile:           return "2,000 surahs played"
        case .earForVoices:         return "Favorite 3 reciters"
        case .reciterCollector:     return "Favorite 10 reciters"

        case .firstBookmark:        return "Bookmark your first ayah"
        case .collector:            return "25 bookmarked ayahs"
        case .archivist:            return "100 bookmarked ayahs"
        case .curator:              return "500 bookmarked ayahs"
        case .firstNote:            return "Write your first note"
        case .annotator:            return "10 ayahs with notes"
        case .commentator:          return "50 ayahs with notes"
        case .scribe:               return "200 ayahs with notes"
        case .firstHighlight:       return "Highlight your first ayah"
        case .highlighter:          return "10 highlighted ayahs"
        case .illuminator:          return "50 highlighted ayahs"
        case .fullPalette:          return "Use every highlight color"
        case .keptClose:            return "Favorite 5 surahs"
        case .wellLoved:            return "Favorite 25 surahs"

        case .firstHadithBook:      return "Start reading a hadith book"
        case .hadithReader:         return "Start reading 3 hadith books"
        case .hadithShelf:          return "Start reading 10 hadith books"
        case .wholeShelf:           return "Start reading all 17 hadith books"
        case .firstHadithBookmark:  return "Bookmark your first hadith"
        case .hadithScholar:        return "25 bookmarked hadiths"
        case .hadithArchivist:      return "100 bookmarked hadiths"
        case .hadithFavorites:      return "Favorite 3 hadith collections"

        case .oneTasbih:            return "33 counted on the tasbih"
        case .dhikrHundred:         return "100 counted on the tasbih"
        case .dhikrFiveHundred:     return "500 counted on the tasbih"
        case .dhikrThousand:        return "1,000 counted on the tasbih"
        case .dhikrFiveThousand:    return "5,000 counted on the tasbih"
        case .dhikrTenThousand:     return "10,000 counted on the tasbih"
        case .dhikrHundredThousand: return "100,000 counted on the tasbih"
        }
    }

    /// Every symbol here is SF Symbols 3 (iOS 15) or earlier - the app's deployment floor. Newer
    /// glyphs (`medal.fill`, `laurel.leading`, `flag.checkered`) render as a blank box on iOS 15.
    var systemImage: String {
        switch self {
        case .firstPrayer:          return "figure.stand"
        case .threeDayStreak:       return "arrow.up.right"
        case .weekOfSalah:          return "calendar"
        case .fortnightOfSalah:     return "calendar.badge.clock"
        case .monthOfSalah:         return "calendar.circle.fill"
        case .fiftyDayStreak:       return "flame"
        case .steadfast:            return "flame.fill"
        case .halfYearOfSalah:      return "hourglass"
        case .yearOfSalah:          return "infinity"
        case .perfectDay:           return "checkmark.circle"
        case .perfectTen:           return "checkmark.seal"
        case .perfectFifty:         return "checkmark.shield"
        case .perfectHundred:       return "checkmark.seal.fill"
        case .perfectYear:          return "crown"
        case .prayers100:           return "circle.grid.2x2.fill"
        case .prayers500:           return "circle.grid.3x3.fill"
        case .prayers1000:          return "square.grid.3x3.fill"
        case .prayers5000:          return "trophy.fill"
        case .monthRecorded:        return "chart.bar.fill"
        case .yearRecorded:         return "chart.bar.doc.horizontal"
        case .consistency:          return "scope"

        case .openedTheBook:        return "book"
        case .ayahs100:             return "text.alignleft"
        case .ayahs500:             return "text.justify"
        case .juzDone:              return "book.closed"
        case .fiveJuz:              return "bookmark.square"
        case .tenJuz:               return "book.circle"
        case .halfway:              return "book.closed.fill"
        case .twentyJuz:            return "book.circle.fill"
        case .threeQuarters:        return "chart.pie.fill"
        case .khatm:                return "crown.fill"
        case .firstSurahComplete:   return "1.circle"
        case .tenSurahsComplete:    return "10.circle"
        case .thirtySurahsComplete: return "30.circle"
        // SF Symbols' numbered circles stop at 50, so sixty gets a stack rather than a wrong number.
        case .sixtySurahsComplete:  return "rectangle.stack.fill"
        case .allSurahsComplete:    return "seal.fill"
        case .browsing:             return "list.bullet"
        case .halfTheSurahs:        return "list.bullet.indent"
        case .everySurahOpened:     return "list.bullet.rectangle"
        case .frequentReader:       return "text.book.closed"
        case .devotedReader:        return "books.vertical"
        case .planWeek:             return "calendar.badge.plus"
        case .planMonth:            return "calendar.badge.exclamationmark"
        case .planHundred:          return "sparkles"

        case .firstListen:          return "play.circle"
        case .listener:             return "headphones"
        case .devotedListener:      return "headphones.circle.fill"
        case .audiophile:           return "waveform"
        case .earForVoices:         return "ear"
        case .reciterCollector:     return "person.3.fill"

        case .firstBookmark:        return "bookmark"
        case .collector:            return "bookmark.fill"
        case .archivist:            return "archivebox.fill"
        case .curator:              return "tray.full.fill"
        case .firstNote:            return "pencil"
        case .annotator:            return "note.text"
        case .commentator:          return "quote.bubble.fill"
        case .scribe:               return "square.and.pencil"
        case .firstHighlight:       return "highlighter"
        case .highlighter:          return "paintbrush.fill"
        case .illuminator:          return "sun.max.fill"
        case .fullPalette:          return "paintpalette.fill"
        case .keptClose:            return "heart.fill"
        case .wellLoved:            return "star.fill"

        case .firstHadithBook:      return "text.book.closed"
        case .hadithReader:         return "books.vertical.fill"
        case .hadithShelf:          return "square.stack.3d.up.fill"
        case .wholeShelf:           return "graduationcap.fill"
        case .firstHadithBookmark:  return "bookmark.circle"
        case .hadithScholar:        return "bookmark.circle.fill"
        case .hadithArchivist:      return "folder.fill"
        case .hadithFavorites:      return "star.circle.fill"

        case .oneTasbih:            return "circle.hexagonpath"
        case .dhikrHundred:         return "circle.dashed"
        case .dhikrFiveHundred:     return "circle.circle"
        case .dhikrThousand:        return "circle.hexagonpath.fill"
        case .dhikrFiveThousand:    return "circle.circle.fill"
        case .dhikrTenThousand:     return "hands.sparkles.fill"
        case .dhikrHundredThousand: return "moon.stars.fill"
        }
    }

    /// The family a badge belongs to, so the cabinet groups them instead of presenting one long
    /// undifferentiated wall of tiles.
    enum Family: String, CaseIterable, Identifiable {
        case prayer = "Prayer"
        case quran = "Quran"
        case listening = "Listening"
        case library = "Library"
        case hadith = "Hadith"
        case dhikr = "Dhikr"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .prayer:    return "safari.fill"
            case .quran:     return "character.book.closed.ar"
            case .listening: return "headphones"
            case .library:   return "bookmark.fill"
            case .hadith:    return "text.book.closed.fill"
            case .dhikr:     return "circle.hexagonpath.fill"
            }
        }
    }

    var family: Family {
        switch self {
        case .firstPrayer, .threeDayStreak, .weekOfSalah, .fortnightOfSalah, .monthOfSalah,
             .fiftyDayStreak, .steadfast, .halfYearOfSalah, .yearOfSalah,
             .perfectDay, .perfectTen, .perfectFifty, .perfectHundred, .perfectYear,
             .prayers100, .prayers500, .prayers1000, .prayers5000,
             .monthRecorded, .yearRecorded, .consistency:
            return .prayer

        case .openedTheBook, .ayahs100, .ayahs500,
             .juzDone, .fiveJuz, .tenJuz, .halfway, .twentyJuz, .threeQuarters, .khatm,
             .firstSurahComplete, .tenSurahsComplete, .thirtySurahsComplete, .sixtySurahsComplete,
             .allSurahsComplete, .browsing, .halfTheSurahs, .everySurahOpened,
             .frequentReader, .devotedReader, .planWeek, .planMonth, .planHundred:
            return .quran

        case .firstListen, .listener, .devotedListener, .audiophile,
             .earForVoices, .reciterCollector:
            return .listening

        case .firstBookmark, .collector, .archivist, .curator,
             .firstNote, .annotator, .commentator, .scribe,
             .firstHighlight, .highlighter, .illuminator, .fullPalette,
             .keptClose, .wellLoved:
            return .library

        case .firstHadithBook, .hadithReader, .hadithShelf, .wholeShelf,
             .firstHadithBookmark, .hadithScholar, .hadithArchivist, .hadithFavorites:
            return .hadith

        case .oneTasbih, .dhikrHundred, .dhikrFiveHundred, .dhikrThousand,
             .dhikrFiveThousand, .dhikrTenThousand, .dhikrHundredThousand:
            return .dhikr
        }
    }

    /// `(progress, goal)` in the badge's own unit. An unearned badge shows how far along it is, which
    /// is the only thing that makes a locked tile worth rendering at all.
    func progress(_ stats: ProfileStats) -> (value: Int, goal: Int) {
        // A streak badge counts the BEST run, not the current one - a broken streak shouldn't
        // un-approach a badge you were two days from.
        let streak = max(stats.prayer.currentStreak, stats.prayer.bestStreak)
        let total = max(1, stats.khatmTotal)

        switch self {
        case .firstPrayer:          return (stats.prayer.totalPrayed, 1)
        case .threeDayStreak:       return (streak, 3)
        case .weekOfSalah:          return (streak, 7)
        case .fortnightOfSalah:     return (streak, 14)
        case .monthOfSalah:         return (streak, 30)
        case .fiftyDayStreak:       return (streak, 50)
        case .steadfast:            return (streak, 100)
        case .halfYearOfSalah:      return (streak, 182)
        case .yearOfSalah:          return (streak, 365)
        case .perfectDay:           return (stats.prayer.perfectDays, 1)
        case .perfectTen:           return (stats.prayer.perfectDays, 10)
        case .perfectFifty:         return (stats.prayer.perfectDays, 50)
        case .perfectHundred:       return (stats.prayer.perfectDays, 100)
        case .perfectYear:          return (stats.prayer.perfectDays, 365)
        case .prayers100:           return (stats.prayer.totalPrayed, 100)
        case .prayers500:           return (stats.prayer.totalPrayed, 500)
        case .prayers1000:          return (stats.prayer.totalPrayed, 1_000)
        case .prayers5000:          return (stats.prayer.totalPrayed, 5_000)
        case .monthRecorded:        return (stats.prayer.trackedDays, 30)
        case .yearRecorded:         return (stats.prayer.trackedDays, 365)
        case .consistency:
            // Gated on a month of history: a single perfect day is 100% coverage, and handing out a
            // "Consistency" badge for that would make the word mean nothing.
            let pct = stats.prayer.trackedDays >= 30
                ? Int((stats.prayerCoverageFraction * 100).rounded())
                : 0
            return (pct, 80)

        case .openedTheBook:        return (stats.khatmCompleted, 1)
        case .ayahs100:             return (stats.khatmCompleted, 100)
        case .ayahs500:             return (stats.khatmCompleted, 500)
        case .juzDone:              return (stats.khatmCompleted, max(1, total / 30))
        case .fiveJuz:              return (stats.khatmCompleted, max(1, total / 6))
        case .tenJuz:               return (stats.khatmCompleted, max(1, total / 3))
        case .halfway:              return (stats.khatmCompleted, max(1, total / 2))
        case .twentyJuz:            return (stats.khatmCompleted, max(1, total * 2 / 3))
        case .threeQuarters:        return (stats.khatmCompleted, max(1, total * 3 / 4))
        case .khatm:                return (stats.khatmCompleted, total)
        case .firstSurahComplete:   return (stats.surahsCompleted, 1)
        case .tenSurahsComplete:    return (stats.surahsCompleted, 10)
        case .thirtySurahsComplete: return (stats.surahsCompleted, 30)
        case .sixtySurahsComplete:  return (stats.surahsCompleted, 60)
        case .allSurahsComplete:    return (stats.surahsCompleted, 114)
        case .browsing:             return (stats.surahsOpened, 10)
        case .halfTheSurahs:        return (stats.surahsOpened, 57)
        case .everySurahOpened:     return (stats.surahsOpened, 114)
        case .frequentReader:       return (stats.totalOpens, 100)
        case .devotedReader:        return (stats.totalOpens, 1_000)
        case .planWeek:             return (stats.planStreak ?? 0, 7)
        case .planMonth:            return (stats.planStreak ?? 0, 30)
        case .planHundred:          return (stats.planStreak ?? 0, 100)

        case .firstListen:          return (stats.totalPlays, 1)
        case .listener:             return (stats.totalPlays, 50)
        case .devotedListener:      return (stats.totalPlays, 500)
        case .audiophile:           return (stats.totalPlays, 2_000)
        case .earForVoices:         return (stats.favoriteReciters, 3)
        case .reciterCollector:     return (stats.favoriteReciters, 10)

        case .firstBookmark:        return (stats.bookmarks, 1)
        case .collector:            return (stats.bookmarks, 25)
        case .archivist:            return (stats.bookmarks, 100)
        case .curator:              return (stats.bookmarks, 500)
        case .firstNote:            return (stats.notes, 1)
        case .annotator:            return (stats.notes, 10)
        case .commentator:          return (stats.notes, 50)
        case .scribe:               return (stats.notes, 200)
        case .firstHighlight:       return (stats.highlights, 1)
        case .highlighter:          return (stats.highlights, 10)
        case .illuminator:          return (stats.highlights, 50)
        case .fullPalette:          return (stats.highlightColorsUsed, AyahHighlightColor.allCases.count)
        case .keptClose:            return (stats.favoriteSurahs, 5)
        case .wellLoved:            return (stats.favoriteSurahs, 25)

        case .firstHadithBook:      return (stats.hadithBooksStarted, 1)
        case .hadithReader:         return (stats.hadithBooksStarted, 3)
        case .hadithShelf:          return (stats.hadithBooksStarted, 10)
        case .wholeShelf:           return (stats.hadithBooksStarted, 17)
        case .firstHadithBookmark:  return (stats.hadithBookmarks, 1)
        case .hadithScholar:        return (stats.hadithBookmarks, 25)
        case .hadithArchivist:      return (stats.hadithBookmarks, 100)
        case .hadithFavorites:      return (stats.hadithFavoriteBooks, 3)

        case .oneTasbih:            return (stats.dhikrTotal, 33)
        case .dhikrHundred:         return (stats.dhikrTotal, 100)
        case .dhikrFiveHundred:     return (stats.dhikrTotal, 500)
        case .dhikrThousand:        return (stats.dhikrTotal, 1_000)
        case .dhikrFiveThousand:    return (stats.dhikrTotal, 5_000)
        case .dhikrTenThousand:     return (stats.dhikrTotal, 10_000)
        case .dhikrHundredThousand: return (stats.dhikrTotal, 100_000)
        }
    }

    /// Whether the underlying numbers satisfy the threshold RIGHT NOW. This is what crosses the line;
    /// `AchievementsStore.isUnlocked` is what remembers that it was crossed.
    func isEarned(_ stats: ProfileStats) -> Bool {
        let (value, goal) = progress(stats)
        return value >= goal
    }

    func fraction(_ stats: ProfileStats) -> Double {
        let (value, goal) = progress(stats)
        return goal > 0 ? min(1, Double(value) / Double(goal)) : 0
    }
}

// MARK: - The unlock ledger

/// One announcement in flight. `queued` is how many more are waiting behind it, so a burst (opening
/// the app after a long stretch offline, or crossing several thresholds with one tap) reads as
/// "and 4 more" rather than as four seconds of banners with no end in sight.
struct AchievementAnnouncement: Identifiable, Equatable {
    let id = UUID()
    let badge: AlIslamBadge
    let queued: Int
}

/// Persists which badges have EVER been earned, and announces the ones that cross while the app is
/// open.
///
/// Two things make this safe to trust:
///
/// 1. **The ledger only grows.** `sync` unions newly-satisfied thresholds in; nothing removes an
///    entry. Marking a prayer and unmarking it keeps "First Steps" - which is the bug this whole
///    type exists to fix.
/// 2. **The first run seeds silently.** An existing user's very first sync adopts everything they
///    already qualify for without a single banner. Without that, upgrading would fire eighty
///    notifications for work done months ago.
///
/// The seed is also why `performRefresh` refuses to run until the Quran packs and the hadith
/// last-read table have actually loaded: seeding against half-loaded stores would bank a too-small
/// set and then announce the real totals as fresh unlocks a second later.
@MainActor
final class AchievementsStore: ObservableObject {
    static let shared = AchievementsStore()

    private static let unlockedKey = "achievementUnlockedAt"
    private static let seededKey = "achievementsSeeded"

    /// Badge id → unix timestamp of the unlock. `0` means "already earned when the ledger started",
    /// i.e. seeded, and the detail sheet then omits a date rather than inventing one.
    @Published private(set) var unlockedAt: [String: Double]

    /// The banner currently on screen, if any. `AchievementBannerHost` renders this.
    @Published private(set) var current: AchievementAnnouncement?

    private var seeded: Bool
    private var queue: [AlIslamBadge] = []
    private var trackingStarted = false
    private var refreshTask: Task<Void, Never>?
    private var dismissTask: Task<Void, Never>?
    private var loadRetries = 0

    private init() {
        unlockedAt = (UserDefaults.standard.dictionary(forKey: Self.unlockedKey) as? [String: Double]) ?? [:]
        seeded = UserDefaults.standard.bool(forKey: Self.seededKey)

        NotificationCenter.default.addObserver(
            forName: Settings.contentErasedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reset() }
        }
    }

    // MARK: Reading

    /// The ledger first, the live threshold second. The fallback matters for the window between a
    /// threshold being crossed and the debounced refresh landing - the profile screen shouldn't show
    /// a badge as locked when the number on the card right above it already says otherwise.
    func isUnlocked(_ badge: AlIslamBadge, _ stats: ProfileStats) -> Bool {
        unlockedAt[badge.id] != nil || badge.isEarned(stats)
    }

    /// When the badge was earned, or nil if it was seeded (earned before the ledger existed).
    func unlockDate(_ badge: AlIslamBadge) -> Date? {
        guard let stamp = unlockedAt[badge.id], stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    func unlockedCount(_ stats: ProfileStats) -> Int {
        AlIslamBadge.allCases.reduce(0) { $0 + (isUnlocked($1, stats) ? 1 : 0) }
    }

    func unlockedCount(in family: AlIslamBadge.Family, _ stats: ProfileStats) -> Int {
        AlIslamBadge.allCases.reduce(0) {
            $0 + (($1.family == family && isUnlocked($1, stats)) ? 1 : 0)
        }
    }

    // MARK: Tracking

    /// Starts the watcher after the launch cover lifts. Idempotent - `AchievementWatcher` calls it
    /// from a `.task` that can re-run.
    func beginTracking() async {
        guard !trackingStarted else { return }
        trackingStarted = true

        await AppReveal.waitUntilRevealed()
        // The hadith last-read table is loaded lazily by whichever screen asks first; the seed needs
        // it loaded, so ask here rather than letting `ProfileStats.current` kick off its deferred
        // load and then read the still-empty dictionary in the same pass.
        HadithStore.shared.loadLastRead()
        try? await Task.sleep(nanoseconds: 2_500_000_000)

        #if DEBUG
        // `-debugAchievement khatm` fires a banner on launch. There is no way to drive the simulator's
        // UI from a test harness here, so this is how the presentation gets looked at without having
        // to actually earn something.
        let arguments = ProcessInfo.processInfo.arguments
        if let flag = arguments.firstIndex(of: "-debugAchievement"),
           flag + 1 < arguments.count,
           let badge = AlIslamBadge(rawValue: arguments[flag + 1]) {
            debugAnnounce(badge)
        }
        #endif

        scheduleRefresh(delay: 0)
    }

    /// Debounced: a burst of writes (scrolling a surah in khatm mode auto-marks ayah after ayah)
    /// rides one recomputation instead of one per ayah.
    func scheduleRefresh(delay: Double = 0.7) {
        guard trackingStarted else { return }
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            self?.performRefresh()
        }
    }

    private func performRefresh() {
        let quranData = QuranData.shared
        guard quranData.quran.count >= 114 else {
            // Packs still loading. Retry a bounded number of times - if the Quran never loads, the
            // ledger simply stays untouched for the session rather than spinning forever.
            guard loadRetries < 10 else { return }
            loadRetries += 1
            scheduleRefresh(delay: 2)
            return
        }
        loadRetries = 0
        sync(stats: ProfileStats.current(settings: .shared, quranData: quranData))
    }

    /// Folds the currently-satisfied thresholds into the ledger, announcing whatever is new.
    func sync(stats: ProfileStats) {
        let earned = AlIslamBadge.allCases.filter { $0.isEarned(stats) }

        guard seeded else {
            unlockedAt = Dictionary(uniqueKeysWithValues: earned.map { ($0.id, 0.0) })
            seeded = true
            persist()
            return
        }

        let fresh = earned.filter { unlockedAt[$0.id] == nil }
        guard !fresh.isEmpty else { return }

        let now = Date().timeIntervalSince1970
        for badge in fresh { unlockedAt[badge.id] = now }
        persist()

        queue.append(contentsOf: fresh)
        showNext()
    }

    private func persist() {
        UserDefaults.standard.set(unlockedAt, forKey: Self.unlockedKey)
        UserDefaults.standard.set(seeded, forKey: Self.seededKey)
    }

    /// Wipes the ledger. Called from `Settings.resetSettings` alongside the data the badges are
    /// thresholds on - a reset that kept the badges would leave the cabinet claiming a khatm the
    /// khatm set no longer records.
    func reset() {
        refreshTask?.cancel()
        dismissTask?.cancel()
        queue.removeAll()
        current = nil
        unlockedAt = [:]
        // Left unseeded on purpose: the next refresh re-seeds from whatever survives the reset,
        // silently, instead of announcing it all back.
        seeded = false
        UserDefaults.standard.removeObject(forKey: Self.unlockedKey)
        UserDefaults.standard.removeObject(forKey: Self.seededKey)
        AchievementBannerPresenter.shared.dismiss()
    }

    // MARK: Announcing

    private func showNext() {
        guard current == nil, !queue.isEmpty else { return }

        let badge = queue.removeFirst()
        current = AchievementAnnouncement(badge: badge, queued: queue.count)
        AchievementBannerPresenter.shared.present()
        playUnlockHaptics()

        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_200_000_000)
            guard !Task.isCancelled else { return }
            self?.dismissCurrent()
        }
    }

    func dismissCurrent() {
        dismissTask?.cancel()
        dismissTask = nil
        guard current != nil else { return }
        current = nil
        // Surrendered the moment the card starts leaving. The card's own frame reporter can't do
        // this - it goes away WITH the card - and the window outlives it by the length of the exit
        // transition, which would otherwise be a few hundred milliseconds of the app swallowing
        // taps in a rectangle where nothing is drawn any more.
        AchievementBannerPresenter.shared.setInteractiveFrame(.zero)

        Task { [weak self] in
            // Long enough for the exit transition to finish before either the next banner slides in
            // or the hosting window goes away underneath it.
            try? await Task.sleep(nanoseconds: 420_000_000)
            guard let self else { return }
            if self.queue.isEmpty {
                AchievementBannerPresenter.shared.dismiss()
            } else {
                self.showNext()
            }
        }
    }

    /// A two-beat pattern: the success notification lands as the card arrives, and a light impact a
    /// moment later coincides with the icon's spring settling, so the banner is felt as one event
    /// with a punctuation mark rather than a single anonymous buzz.
    private func playUnlockHaptics() {
        guard Settings.shared.hapticOn else { return }

        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.success)

        Task {
            try? await Task.sleep(nanoseconds: 260_000_000)
            let impact = UIImpactFeedbackGenerator(style: .rigid)
            impact.prepare()
            impact.impactOccurred(intensity: 0.9)
        }
    }

    #if DEBUG
    /// Fires a banner on demand so the presentation can be exercised without earning anything.
    func debugAnnounce(_ badge: AlIslamBadge) {
        queue.append(badge)
        showNext()
    }
    #endif
}

// MARK: - Banner window

/// The banner lives in its own `UIWindow`, not in an overlay on the app root.
///
/// That is the whole reason it can be trusted: achievements are crossed from inside sheets (the
/// tasbih counter, the ayah bookmark sheet, the prayer nag dialog) and a root overlay renders
/// UNDERNEATH a presented sheet, so the celebration for the thing you just did would be invisible
/// exactly when it fires. A window above `.alert` level always wins.
///
/// The window is created on demand and torn down when the queue drains, so the app carries no extra
/// window in the ordinary case.
@MainActor
final class AchievementBannerPresenter {
    static let shared = AchievementBannerPresenter()

    private var window: PassthroughWindow?

    private init() {}

    func present() {
        if let window {
            window.isHidden = false
            window.applyAppearance()
            return
        }

        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        else { return }

        let host = UIHostingController(rootView: AchievementBannerHost().appFontDesign())
        host.view.backgroundColor = .clear

        let window = PassthroughWindow(windowScene: scene)
        window.rootViewController = host
        window.backgroundColor = .clear
        window.windowLevel = .alert + 1
        window.applyAppearance()
        window.isHidden = false
        self.window = window
    }

    func dismiss() {
        // Take the window OUT of the stored property before letting it deallocate. Releasing it
        // inside the `window = nil` assignment ran UIWindow dealloc - and the hosting view's
        // teardown - while the property's exclusive write access was still open; the teardown
        // re-entered `setInteractiveFrame`, whose read of `window` then trapped ("Simultaneous
        // accesses ... modification requires exclusive access", live crash on dismissing a
        // bookmark achievement's banner). The local keeps it alive until this scope ends, after
        // the write access has closed.
        let retiring = window
        window = nil
        retiring?.isHidden = true
    }

    /// The card reports its own frame so the window can pass every touch outside it straight
    /// through. Without this the window would swallow the whole screen: a SwiftUI hosting view
    /// answers `hitTest` for any point it covers, so "is the hit view the root view?" is not a
    /// usable test once the card carries gestures of its own.
    func setInteractiveFrame(_ frame: CGRect) {
        window?.interactiveFrame = frame
    }
}

private final class PassthroughWindow: UIWindow {
    var interactiveFrame: CGRect = .zero

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard interactiveFrame.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }

    /// A separate window doesn't inherit the app's `preferredColorScheme`, so a user who has pinned
    /// the app to dark while the phone is light would get a light banner over a dark app.
    func applyAppearance() {
        switch Settings.shared.colorScheme {
        case .some(.dark):  overrideUserInterfaceStyle = .dark
        case .some(.light): overrideUserInterfaceStyle = .light
        default:            overrideUserInterfaceStyle = .unspecified
        }
    }
}

// MARK: - Banner UI

private struct AchievementBannerHost: View {
    @ObservedObject private var store = AchievementsStore.shared

    var body: some View {
        VStack(spacing: 0) {
            if let announcement = store.current {
                AchievementBannerCard(announcement: announcement)
                    .id(announcement.id)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        // Clears the Dynamic Island the way a system notification does, rather than tucking up
        // against it.
        .padding(.top, 16)
        .animation(.spring(response: 0.48, dampingFraction: 0.78), value: store.current?.id)
        .onDisappear { AchievementBannerPresenter.shared.setInteractiveFrame(.zero) }
    }
}

private struct AchievementBannerCard: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let announcement: AchievementAnnouncement

    @State private var iconIn = false
    @State private var shine = false
    @State private var burst = false
    @State private var dragOffset: CGFloat = 0

    private var badge: AlIslamBadge { announcement.badge }

    var body: some View {
        let accent = settings.accentColor.color

        HStack(spacing: 12) {
            icon(accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("ACHIEVEMENT UNLOCKED")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(accent)

                Text(badge.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(badge.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            // Only shown when a burst is queued behind this one, so the user knows the banners are
            // finite and roughly how many are coming.
            if announcement.queued > 0 {
                Text("+\(announcement.queued)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(accent.opacity(0.15)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(background(accent))
        .overlay(shineSweep(accent))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(accent.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
        .shadow(color: accent.opacity(0.22), radius: 18, y: 2)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                // Upward only: dragging down would fight the notification-shade pull the banner sits
                // under, and there is nothing below it to reveal anyway.
                .onChanged { dragOffset = min(0, $0.translation.height) }
                .onEnded { value in
                    if value.translation.height < -18 {
                        AchievementsStore.shared.dismissCurrent()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dragOffset = 0 }
                    }
                }
        )
        .onTapGesture { AchievementsStore.shared.dismissCurrent() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Achievement unlocked. \(badge.title). \(badge.detail).")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { AchievementsStore.shared.dismissCurrent() }
        .background(frameReporter)
        .onAppear(perform: animateIn)
    }

    // MARK: Pieces

    private func icon(_ accent: Color) -> some View {
        ZStack {
            // A ring of short strokes flung outward as the badge lands. Cheap (eight capsules, one
            // animation) and it is what makes the moment read as a celebration rather than as a
            // notification.
            if !reduceMotion {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(accent.opacity(burst ? 0 : 0.85))
                        .frame(width: 2.5, height: burst ? 9 : 3)
                        .offset(y: burst ? -30 : -17)
                        .rotationEffect(.degrees(Double(index) / 8 * 360))
                        .scaleEffect(burst ? 1.05 : 0.5)
                }
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.95), accent.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .shadow(color: accent.opacity(0.45), radius: 7, y: 2)

            Image(systemName: badge.systemImage)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(iconIn ? 1 : 0.45)
        .rotationEffect(.degrees(iconIn ? 0 : -28))
        .opacity(iconIn ? 1 : 0)
        .frame(width: 46, height: 46)
    }

    private func background(_ accent: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.20), accent.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    @ViewBuilder
    private func shineSweep(_ accent: Color) -> some View {
        if reduceMotion {
            EmptyView()
        } else {
            GeometryReader { proxy in
                let width = proxy.size.width
                LinearGradient(
                    colors: [.clear, .white.opacity(0.32), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: 90)
                .rotationEffect(.degrees(22))
                .offset(x: shine ? width + 90 : -90)
                .blendMode(.plusLighter)
            }
            .allowsHitTesting(false)
        }
    }

    /// Publishes the card's on-screen rect to the hosting window so everything outside it stays
    /// tappable (see `AchievementBannerPresenter.setInteractiveFrame`).
    private var frameReporter: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { AchievementBannerPresenter.shared.setInteractiveFrame(proxy.frame(in: .global)) }
                .onChange(of: proxy.frame(in: .global)) { frame in
                    AchievementBannerPresenter.shared.setInteractiveFrame(frame)
                }
        }
    }

    private func animateIn() {
        guard !reduceMotion else {
            iconIn = true
            return
        }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.55).delay(0.08)) { iconIn = true }
        withAnimation(.easeOut(duration: 0.55).delay(0.18)) { burst = true }
        withAnimation(.easeInOut(duration: 0.85).delay(0.22)) { shine = true }
    }
}

// MARK: - Tracking hook

extension View {
    /// Watches the stores the badges are thresholds on and unlocks/announces as they cross. Attached
    /// once, at the app root.
    func achievementTracking() -> some View {
        background(AchievementWatcher().allowsHitTesting(false))
    }
}

/// A zero-size leaf whose only job is to hold the subscriptions.
///
/// It observes `Settings` (and four smaller stores) deliberately, which the tab host explicitly does
/// NOT do - but the cost is different here: this body is `Color.clear` plus an `onChange`, so a
/// publish re-evaluates a single empty view rather than five tab view trees. The stamp it hashes is
/// the same one `ProfileSettingsRow` already recomputes on every pass of the Settings list.
private struct AchievementWatcher: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var tasbih = TasbihCounters.shared
    @ObservedObject private var hadithUserData = HadithUserData.shared
    @ObservedObject private var hadithStore = HadithStore.shared

    private var signature: Int {
        var hasher = Hasher()
        hasher.combine(settings.profileStatsStamp)
        hasher.combine(quranData.quran.count)
        hasher.combine(tasbih.totalCount)
        hasher.combine(hadithUserData.bookmarks.count)
        hasher.combine(hadithUserData.favoriteSlugs.count)
        hasher.combine(hadithStore.lastReadByBook.count)
        return hasher.finalize()
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: signature) { _ in
                AchievementsStore.shared.scheduleRefresh()
            }
            .task { await AchievementsStore.shared.beginTracking() }
    }
}

#endif
