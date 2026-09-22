#if DEBUG && os(iOS)
import Foundation

/// What every content store holds IN MEMORY, one line each, for `-cloudStoreProbe` (see
/// `CloudBackupDebug`). After a restore in the same launch these lines are the proof that each
/// store took the restored bytes: before 2026-09-21 seventeen of them kept what they had loaded at
/// launch and wrote it back over the restore with their next save.
///
/// Its own file, apart from `CloudBackupDebug`, because it names the stores: a sibling app that
/// ships only some of them excludes this file and passes no probe.
enum CloudBackupStoreProbe {
    @MainActor
    static func report() -> String {
        let settings = Settings.shared
        let tasbih = TasbihCounters.shared
        let activity = ActivityLog.shared
        let hadith = HadithStore.shared
        let marks = HadithUserData.shared
        let player = QuranPlayer.shared
        let lines: [String] = [
            "tasbih lifetime=\(tasbih.lifetimeCount) total=\(tasbih.totalCount) today=\(tasbih.todayCount) days=\(tasbih.activeDayCount)",
            "activity activeDays=\(activity.summary.activeDayCount) streak=\(activity.summary.streak.current)",
            "journal entries=\(JournalStore.shared.entries.count)",
            "reflections items=\(SavedReflectionsStore.shared.items.count)",
            "achievements unlocked=\(AchievementsStore.shared.unlockedAt.count)",
            "hadith bookmarks=\(marks.bookmarks.count) favoriteBooks=\(marks.favoriteSlugs.count) favoriteChapters=\(marks.favoriteChapterKeys.count)",
            "hadith lastReadBooks=\(hadith.lastReadByBook.count) viewed=\(hadith.viewed.count) dailyHistory=\(HadithStore.loadDailyHistory().count)",
            "readingTest passed=\(ReadingTestProgress.shared.passedCount) placement=\(ReadingTestProgress.shared.placement ?? "none")",
            "tajweedLessons done=\(TajweedLessonProgress.shared.done.count)",
            "themes lit=\(ThemeHighlights.shared.lit.count) allSections=\(ThemeHighlights.shared.allSectionsLit) sections=\(ThemeHighlights.shared.litSectionIDs.count)",
            "sunnahReminders on=\(SunnahReminderStore.shared.configs.values.filter(\.enabled).count)",
            "extraReminders custom=\(ExtraRemindersStore.shared.custom.count) dua=\(ExtraRemindersStore.shared.config.duaEnabled)",
            "player listening=\(player.listeningHistory.count) reading=\(player.readingHistory.count) ayahListening=\(player.ayahListeningHistory.count)",
            "quran bookmarks=\(settings.bookmarkedAyahs.count) favoriteSurahs=\(settings.favoriteSurahs.count) khatm=\(settings.khatmCompletedAyahs.count)",
            "quran lastRead=\(settings.lastReadSurah):\(settings.lastReadAyah)",
            "tracker days=\(settings.trackerSnapshot().marks.count) exempt=\(settings.trackerSnapshot().exemptDays.count)",
            "preferences accent=\(settings.accentColor.rawValue) hanafi=\(settings.hanafiMadhab) method=\(settings.prayerCalculation) hijriOffset=\(settings.hijriOffset)",
            "preferences offsetFajr=\(settings.offsetFajr) colorScheme=\(settings.colorSchemeString) arabicSize=\(settings.fontArabicSize)",
            "appGroup offsetFajr=\(settings.appGroupUserDefaults?.integer(forKey: "offsetFajr") ?? -1) accent=\(settings.appGroupUserDefaults?.string(forKey: "accentColor") ?? "nil")",
        ]
        return lines.joined(separator: "\n") + "\n"
    }
}
#endif
