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
// Each family ships with its domain: the prayer badges with the prayer times (HAS_ADHAN), the Quran,
// listening and library badges with the Quran (HAS_QURAN), the hadith badges with the Hadith tab
// (HAS_HADITH); only the dhikr badges are in every app. Every switch below is gated the same way, so
// Al-Adhan and Al-Quran compile this file as it is.
enum AlIslamBadge: String, CaseIterable, Identifiable {
    #if HAS_ADHAN
    // Prayer - streaks, perfect days, lifetime totals, coverage.
    case firstPrayer, threeDayStreak, weekOfSalah, fortnightOfSalah, monthOfSalah, fiftyDayStreak
    case steadfast, halfYearOfSalah, yearOfSalah
    case perfectDay, perfectTen, perfectFifty, perfectHundred, perfectYear
    case prayers100, prayers500, prayers1000, prayers5000
    case monthRecorded, yearRecorded, consistency
    #endif

    #if HAS_QURAN
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
    #endif

    #if HAS_HADITH
    // Hadith
    case firstHadithBook, hadithReader, hadithShelf, wholeShelf
    case firstHadithBookmark, hadithScholar, hadithArchivist, hadithFavorites
    #endif

    // Dhikr
    case oneTasbih, dhikrHundred, dhikrFiveHundred, dhikrThousand
    case dhikrFiveThousand, dhikrTenThousand, dhikrHundredThousand
    case dhikrThreeDays, dhikrWeek, dhikrMonth, dhikrHundredDays

    var id: String { rawValue }

    var title: String {
        switch self {
        #if HAS_ADHAN
        case .firstPrayer:          return String(localized: "First Steps")
        case .threeDayStreak:       return String(localized: "Getting Going")
        case .weekOfSalah:          return String(localized: "Week of Salah")
        case .fortnightOfSalah:     return String(localized: "Fortnight")
        case .monthOfSalah:         return String(localized: "Month of Salah")
        case .fiftyDayStreak:       return String(localized: "Fifty Days")
        case .steadfast:            return String(localized: "Steadfast")
        case .halfYearOfSalah:      return String(localized: "Half a Year")
        case .yearOfSalah:          return String(localized: "Year of Salah")
        case .perfectDay:           return String(localized: "A Perfect Day")
        case .perfectTen:           return String(localized: "Ten Perfect Days")
        case .perfectFifty:         return String(localized: "Fifty Perfect Days")
        case .perfectHundred:       return String(localized: "A Hundred Perfect Days")
        case .perfectYear:          return String(localized: "A Perfect Year")
        case .prayers100:           return String(localized: "A Hundred Prayers")
        case .prayers500:           return String(localized: "Five Hundred Prayers")
        case .prayers1000:          return String(localized: "A Thousand Prayers")
        case .prayers5000:          return String(localized: "Five Thousand Prayers")
        case .monthRecorded:        return String(localized: "A Month Recorded")
        case .yearRecorded:         return String(localized: "A Year Recorded")
        case .consistency:          return String(localized: "Consistency")
        #endif

        #if HAS_QURAN
        case .openedTheBook:        return String(localized: "Opened the Book")
        case .ayahs100:             return String(localized: "A Hundred Ayahs")
        case .ayahs500:             return String(localized: "Five Hundred Ayahs")
        case .juzDone:              return String(localized: "A Juz' In")
        case .fiveJuz:              return String(localized: "Five Juz'")
        case .tenJuz:               return String(localized: "Ten Juz'")
        case .halfway:              return String(localized: "Halfway")
        case .twentyJuz:            return String(localized: "Twenty Juz'")
        case .threeQuarters:        return String(localized: "Three Quarters")
        case .khatm:                return String(localized: "Khatm")
        case .firstSurahComplete:   return String(localized: "First Surah")
        case .tenSurahsComplete:    return String(localized: "Ten Surahs")
        case .thirtySurahsComplete: return String(localized: "Thirty Surahs")
        case .sixtySurahsComplete:  return String(localized: "Sixty Surahs")
        case .allSurahsComplete:    return String(localized: "Every Surah Finished")
        case .browsing:             return String(localized: "Browsing")
        case .halfTheSurahs:        return String(localized: "Half the Surahs")
        case .everySurahOpened:     return String(localized: "Every Surah Opened")
        case .frequentReader:       return String(localized: "Frequent Reader")
        case .devotedReader:        return String(localized: "Devoted Reader")
        case .planWeek:             return String(localized: "A Week on Plan")
        case .planMonth:            return String(localized: "A Month on Plan")
        case .planHundred:          return String(localized: "A Hundred Days on Plan")

        case .firstListen:          return String(localized: "First Listen")
        case .listener:             return String(localized: "Listener")
        case .devotedListener:      return String(localized: "Devoted Listener")
        case .audiophile:           return String(localized: "Always Listening")
        case .earForVoices:         return String(localized: "An Ear for Voices")
        case .reciterCollector:     return String(localized: "Reciter Collector")

        case .firstBookmark:        return String(localized: "First Bookmark")
        case .collector:            return String(localized: "Collector")
        case .archivist:            return String(localized: "Archivist")
        case .curator:              return String(localized: "Curator")
        case .firstNote:            return String(localized: "First Note")
        case .annotator:            return String(localized: "Annotator")
        case .commentator:          return String(localized: "Commentator")
        case .scribe:               return String(localized: "Scribe")
        case .firstHighlight:       return String(localized: "First Highlight")
        case .highlighter:          return String(localized: "Highlighter")
        case .illuminator:          return String(localized: "Illuminator")
        case .fullPalette:          return String(localized: "Full Palette")
        case .keptClose:            return String(localized: "Kept Close")
        case .wellLoved:            return String(localized: "Well Loved")
        #endif

        #if HAS_HADITH
        case .firstHadithBook:      return String(localized: "First Collection")
        case .hadithReader:         return String(localized: "Hadith Reader")
        case .hadithShelf:          return String(localized: "Shelf Reader")
        case .wholeShelf:           return String(localized: "The Whole Shelf")
        case .firstHadithBookmark:  return String(localized: "First Narration Kept")
        case .hadithScholar:        return String(localized: "Hadith Scholar")
        case .hadithArchivist:      return String(localized: "Hadith Archivist")
        case .hadithFavorites:      return String(localized: "Favorite Collections")
        #endif

        case .oneTasbih:            return String(localized: "One Tasbih")
        case .dhikrHundred:         return String(localized: "A Hundred Remembrances")
        case .dhikrFiveHundred:     return String(localized: "Five Hundred Remembrances")
        case .dhikrThousand:        return String(localized: "A Thousand Remembrances")
        case .dhikrFiveThousand:    return String(localized: "Five Thousand Remembrances")
        case .dhikrTenThousand:     return String(localized: "Ten Thousand Remembrances")
        case .dhikrHundredThousand: return String(localized: "A Hundred Thousand Remembrances")
        case .dhikrThreeDays:       return String(localized: "Three Days of Dhikr")
        case .dhikrWeek:            return String(localized: "A Week of Dhikr")
        case .dhikrMonth:           return String(localized: "A Month of Dhikr")
        case .dhikrHundredDays:     return String(localized: "A Hundred Days of Dhikr")
        }
    }

    var detail: String {
        switch self {
        #if HAS_ADHAN
        case .firstPrayer:          return String(localized: "Mark your first prayer")
        case .threeDayStreak:       return String(localized: "A 3-day prayer streak")
        case .weekOfSalah:          return String(localized: "A 7-day prayer streak")
        case .fortnightOfSalah:     return String(localized: "A 14-day prayer streak")
        case .monthOfSalah:         return String(localized: "A 30-day prayer streak")
        case .fiftyDayStreak:       return String(localized: "A 50-day prayer streak")
        case .steadfast:            return String(localized: "A 100-day prayer streak")
        case .halfYearOfSalah:      return String(localized: "A 182-day prayer streak")
        case .yearOfSalah:          return String(localized: "A 365-day prayer streak")
        case .perfectDay:           return String(localized: "One day with all five prayers on time")
        case .perfectTen:           return String(localized: "10 days with all five prayers on time")
        case .perfectFifty:         return String(localized: "50 days with all five prayers on time")
        case .perfectHundred:       return String(localized: "100 days with all five prayers on time")
        case .perfectYear:          return String(localized: "365 days with all five prayers on time")
        case .prayers100:           return String(localized: "Mark 100 prayers")
        case .prayers500:           return String(localized: "Mark 500 prayers")
        case .prayers1000:          return String(localized: "Mark 1,000 prayers")
        case .prayers5000:          return String(localized: "Mark 5,000 prayers")
        case .monthRecorded:        return String(localized: "30 days in the prayer tracker")
        case .yearRecorded:         return String(localized: "365 days in the prayer tracker")
        case .consistency:          return String(localized: "80% coverage over at least 30 days")
        #endif

        #if HAS_QURAN
        case .openedTheBook:        return String(localized: "Mark your first ayah read")
        case .ayahs100:             return String(localized: "Read 100 ayahs")
        case .ayahs500:             return String(localized: "Read 500 ayahs")
        case .juzDone:              return String(localized: "Read a thirtieth of the Quran")
        case .fiveJuz:              return String(localized: "Read a sixth of the Quran")
        case .tenJuz:               return String(localized: "Read a third of the Quran")
        case .halfway:              return String(localized: "Read half of the Quran")
        case .twentyJuz:            return String(localized: "Read two thirds of the Quran")
        case .threeQuarters:        return String(localized: "Read three quarters of the Quran")
        case .khatm:                return String(localized: "Complete the Quran")
        case .firstSurahComplete:   return String(localized: "Finish a whole surah")
        case .tenSurahsComplete:    return String(localized: "Finish 10 surahs")
        case .thirtySurahsComplete: return String(localized: "Finish 30 surahs")
        case .sixtySurahsComplete:  return String(localized: "Finish 60 surahs")
        case .allSurahsComplete:    return String(localized: "Finish all 114 surahs")
        case .browsing:             return String(localized: "Open 10 different surahs")
        case .halfTheSurahs:        return String(localized: "Open 57 different surahs")
        case .everySurahOpened:     return String(localized: "Open all 114 surahs")
        case .frequentReader:       return String(localized: "100 surah openings")
        case .devotedReader:        return String(localized: "1,000 surah openings")
        case .planWeek:             return String(localized: "A 7-day reading-plan streak")
        case .planMonth:            return String(localized: "A 30-day reading-plan streak")
        case .planHundred:          return String(localized: "A 100-day reading-plan streak")

        case .firstListen:          return String(localized: "Play your first surah")
        case .listener:             return String(localized: "50 surahs played")
        case .devotedListener:      return String(localized: "500 surahs played")
        case .audiophile:           return String(localized: "2,000 surahs played")
        case .earForVoices:         return String(localized: "Favorite 3 reciters")
        case .reciterCollector:     return String(localized: "Favorite 10 reciters")

        case .firstBookmark:        return String(localized: "Bookmark your first ayah")
        case .collector:            return String(localized: "25 bookmarked ayahs")
        case .archivist:            return String(localized: "100 bookmarked ayahs")
        case .curator:              return String(localized: "500 bookmarked ayahs")
        case .firstNote:            return String(localized: "Write your first note")
        case .annotator:            return String(localized: "10 ayahs with notes")
        case .commentator:          return String(localized: "50 ayahs with notes")
        case .scribe:               return String(localized: "200 ayahs with notes")
        case .firstHighlight:       return String(localized: "Highlight your first ayah")
        case .highlighter:          return String(localized: "10 highlighted ayahs")
        case .illuminator:          return String(localized: "50 highlighted ayahs")
        case .fullPalette:          return String(localized: "Use every highlight color")
        case .keptClose:            return String(localized: "Favorite 5 surahs")
        case .wellLoved:            return String(localized: "Favorite 25 surahs")
        #endif

        #if HAS_HADITH
        case .firstHadithBook:      return String(localized: "Start reading a hadith book")
        case .hadithReader:         return String(localized: "Start reading 3 hadith books")
        case .hadithShelf:          return String(localized: "Start reading 10 hadith books")
        case .wholeShelf:           return String(localized: "Start reading all 17 hadith books")
        case .firstHadithBookmark:  return String(localized: "Bookmark your first hadith")
        case .hadithScholar:        return String(localized: "25 bookmarked hadiths")
        case .hadithArchivist:      return String(localized: "100 bookmarked hadiths")
        case .hadithFavorites:      return String(localized: "Favorite 3 hadith collections")
        #endif

        case .oneTasbih:            return String(localized: "33 counted on the tasbih")
        case .dhikrHundred:         return String(localized: "100 counted on the tasbih")
        case .dhikrFiveHundred:     return String(localized: "500 counted on the tasbih")
        case .dhikrThousand:        return String(localized: "1,000 counted on the tasbih")
        case .dhikrFiveThousand:    return String(localized: "5,000 counted on the tasbih")
        case .dhikrTenThousand:     return String(localized: "10,000 counted on the tasbih")
        case .dhikrHundredThousand: return String(localized: "100,000 counted on the tasbih")
        case .dhikrThreeDays:       return String(localized: "Use the tasbih 3 days in a row")
        case .dhikrWeek:            return String(localized: "Use the tasbih 7 days in a row")
        case .dhikrMonth:           return String(localized: "Use the tasbih 30 days in a row")
        case .dhikrHundredDays:     return String(localized: "Use the tasbih 100 days in a row")
        }
    }

    /// Every symbol here is SF Symbols 3 (iOS 15) or earlier - the app's deployment floor. Newer
    /// glyphs (`medal.fill`, `laurel.leading`, `flag.checkered`) render as a blank box on iOS 15.
    var systemImage: String {
        switch self {
        #if HAS_ADHAN
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
        #endif

        #if HAS_QURAN
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
        #endif

        #if HAS_HADITH
        case .firstHadithBook:      return "text.book.closed"
        case .hadithReader:         return "books.vertical.fill"
        case .hadithShelf:          return "square.stack.3d.up.fill"
        case .wholeShelf:           return "graduationcap.fill"
        case .firstHadithBookmark:  return "bookmark.circle"
        case .hadithScholar:        return "bookmark.circle.fill"
        case .hadithArchivist:      return "folder.fill"
        case .hadithFavorites:      return "star.circle.fill"
        #endif

        case .oneTasbih:            return "circle.hexagonpath"
        case .dhikrHundred:         return "circle.dashed"
        case .dhikrFiveHundred:     return "circle.circle"
        case .dhikrThousand:        return "circle.hexagonpath.fill"
        case .dhikrFiveThousand:    return "circle.circle.fill"
        case .dhikrTenThousand:     return "hands.sparkles.fill"
        case .dhikrHundredThousand: return "moon.stars.fill"
        case .dhikrThreeDays:       return "flame"
        case .dhikrWeek:            return "flame.fill"
        case .dhikrMonth:           return "calendar.badge.checkmark"
        case .dhikrHundredDays:     return "sparkles"
        }
    }

    /// The family a badge belongs to, so the cabinet groups them instead of presenting one long
    /// undifferentiated wall of tiles.
    enum Family: String, CaseIterable, Identifiable {
        #if HAS_ADHAN
        case prayer = "Prayer"
        #endif
        #if HAS_QURAN
        case quran = "Quran"
        case listening = "Listening"
        case library = "Library"
        #endif
        #if HAS_HADITH
        case hadith = "Hadith"
        #endif
        case dhikr = "Dhikr"

        var id: String { rawValue }

        /// The family's name as the reader sees it (the raw value stays English).
        var title: String {
            switch self {
            #if HAS_ADHAN
            case .prayer:    return String(localized: "Prayer")
            #endif
            #if HAS_QURAN
            case .quran:     return String(localized: "Quran")
            case .listening: return String(localized: "Listening")
            case .library:   return String(localized: "Library")
            #endif
            #if HAS_HADITH
            case .hadith:    return String(localized: "Hadith")
            #endif
            case .dhikr:     return String(localized: "Dhikr")
            }
        }

        var systemImage: String {
            switch self {
            #if HAS_ADHAN
            case .prayer:    return "safari.fill"
            #endif
            #if HAS_QURAN
            case .quran:     return "character.book.closed.ar"
            case .listening: return "headphones"
            case .library:   return "bookmark.fill"
            #endif
            #if HAS_HADITH
            case .hadith:    return "text.book.closed.fill"
            #endif
            case .dhikr:     return "circle.hexagonpath.fill"
            }
        }
    }

    var family: Family {
        switch self {
        #if HAS_ADHAN
        case .firstPrayer, .threeDayStreak, .weekOfSalah, .fortnightOfSalah, .monthOfSalah,
             .fiftyDayStreak, .steadfast, .halfYearOfSalah, .yearOfSalah,
             .perfectDay, .perfectTen, .perfectFifty, .perfectHundred, .perfectYear,
             .prayers100, .prayers500, .prayers1000, .prayers5000,
             .monthRecorded, .yearRecorded, .consistency:
            return .prayer
        #endif

        #if HAS_QURAN
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
        #endif

        #if HAS_HADITH
        case .firstHadithBook, .hadithReader, .hadithShelf, .wholeShelf,
             .firstHadithBookmark, .hadithScholar, .hadithArchivist, .hadithFavorites:
            return .hadith
        #endif

        case .oneTasbih, .dhikrHundred, .dhikrFiveHundred, .dhikrThousand,
             .dhikrFiveThousand, .dhikrTenThousand, .dhikrHundredThousand,
             .dhikrThreeDays, .dhikrWeek, .dhikrMonth, .dhikrHundredDays:
            return .dhikr
        }
    }

    /// `(progress, goal)` in the badge's own unit. An unearned badge shows how far along it is, which
    /// is the only thing that makes a locked tile worth rendering at all.
    func progress(_ stats: ProfileStats) -> (value: Int, goal: Int) {
        // A streak badge counts the BEST run, not the current one - a broken streak shouldn't
        // un-approach a badge you were two days from.
        #if HAS_ADHAN
        let streak = max(stats.prayer.currentStreak, stats.prayer.bestStreak)
        #endif
        #if HAS_QURAN
        let total = max(1, stats.khatmTotal)
        #endif

        switch self {
        #if HAS_ADHAN
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
        #endif

        #if HAS_QURAN
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
        #endif

        #if HAS_HADITH
        case .firstHadithBook:      return (stats.hadithBooksStarted, 1)
        case .hadithReader:         return (stats.hadithBooksStarted, 3)
        case .hadithShelf:          return (stats.hadithBooksStarted, 10)
        case .wholeShelf:           return (stats.hadithBooksStarted, 17)
        case .firstHadithBookmark:  return (stats.hadithBookmarks, 1)
        case .hadithScholar:        return (stats.hadithBookmarks, 25)
        case .hadithArchivist:      return (stats.hadithBookmarks, 100)
        case .hadithFavorites:      return (stats.hadithFavoriteBooks, 3)
        #endif

        case .oneTasbih:            return (stats.dhikrTotal, 33)
        case .dhikrHundred:         return (stats.dhikrTotal, 100)
        case .dhikrFiveHundred:     return (stats.dhikrTotal, 500)
        case .dhikrThousand:        return (stats.dhikrTotal, 1_000)
        case .dhikrFiveThousand:    return (stats.dhikrTotal, 5_000)
        case .dhikrTenThousand:     return (stats.dhikrTotal, 10_000)
        case .dhikrHundredThousand: return (stats.dhikrTotal, 100_000)
        // The best run, like the prayer streaks: a broken streak must not un-approach a badge.
        case .dhikrThreeDays:       return (max(stats.dhikrStreak, stats.dhikrBestStreak), 3)
        case .dhikrWeek:            return (max(stats.dhikrStreak, stats.dhikrBestStreak), 7)
        case .dhikrMonth:           return (max(stats.dhikrStreak, stats.dhikrBestStreak), 30)
        case .dhikrHundredDays:     return (max(stats.dhikrStreak, stats.dhikrBestStreak), 100)
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
        storageObserver = StoredContentObserver(reload: { AchievementsStore.shared.reloadFromStorage() })
    }

    private var storageObserver: StoredContentObserver?

    /// Set by a restore: the next `sync` banks whatever the restored content already earns WITHOUT
    /// a banner. A merge can lift several counts over their thresholds at once, and a run of
    /// "Achievement unlocked" cards for work done on another device months ago is the launch-day
    /// flood the seed exists to prevent, one restore later.
    private var banksNextSyncSilently = false

    /// The ledger on disk changed underneath this object (a restore, a reset): take it, drop any
    /// banner in flight, and look at the new content once it has settled.
    private func reloadFromStorage() {
        refreshTask?.cancel()
        dismissTask?.cancel()
        queue.removeAll()
        current = nil
        AchievementBannerPresenter.shared.dismiss()
        unlockedAt = (UserDefaults.standard.dictionary(forKey: Self.unlockedKey) as? [String: Double]) ?? [:]
        seeded = UserDefaults.standard.bool(forKey: Self.seededKey)
        banksNextSyncSilently = true
        scheduleRefresh(delay: 1.5)
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
        #if HAS_HADITH
        // The hadith last-read table is loaded lazily by whichever screen asks first; the seed needs
        // it loaded, so ask here rather than letting `ProfileStats.current` kick off its deferred
        // load and then read the still-empty dictionary in the same pass.
        HadithStore.shared.loadLastRead()
        #endif
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
        #if HAS_QURAN
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
        #else
        sync(stats: ProfileStats.current(settings: .shared))
        #endif
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

        let silent = banksNextSyncSilently
        banksNextSyncSilently = false
        let fresh = earned.filter { unlockedAt[$0.id] == nil }
        guard !fresh.isEmpty else { return }

        let now = Date().timeIntervalSince1970
        for badge in fresh { unlockedAt[badge.id] = now }
        persist()

        guard !silent else { return }
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

/// The achievement banner's window. The mechanism (its own `UIWindow` above `.alert`, the
/// passthrough hit-testing, the appearance override, the dismiss-ordering crash fix) lives in
/// `BannerWindow`, shared with the adhan banner.
@MainActor
final class AchievementBannerPresenter {
    static let shared = AchievementBannerPresenter()

    private let window = BannerWindow { AchievementBannerHost() }

    private init() {}

    func present() { window.present() }
    func dismiss() { window.dismiss() }
    func setInteractiveFrame(_ frame: CGRect) { window.setInteractiveFrame(frame) }
}

// MARK: - Banner UI

struct AchievementBannerHost: View {
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
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
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

                Text(badge.detail.localizedDigits)
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
        .background(BannerFrameReporter { AchievementBannerPresenter.shared.setInteractiveFrame($0) })
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
    private let settings = Settings.shared
    @ObservedObject private var hadithSettings = HadithSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var prayerTracker = PrayerTracker.shared
    @ObservedObject private var quranContent = QuranContent.shared
    #if HAS_QURAN
    @ObservedObject private var quranData = QuranData.shared
    #endif
    @ObservedObject private var tasbih = TasbihCounters.shared
    #if HAS_HADITH
    @ObservedObject private var hadithUserData = HadithUserData.shared
    @ObservedObject private var hadithStore = HadithStore.shared
    #endif

    private var signature: Int {
        var hasher = Hasher()
        hasher.combine(settings.profileStatsStamp)
        #if HAS_QURAN
        hasher.combine(quranData.quran.count)
        #endif
        hasher.combine(tasbih.totalCount)
        #if HAS_HADITH
        hasher.combine(hadithUserData.bookmarks.count)
        hasher.combine(hadithUserData.favoriteSlugs.count)
        hasher.combine(hadithStore.lastReadByBook.count)
        #endif
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
