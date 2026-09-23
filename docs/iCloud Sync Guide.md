# Al-Islam iCloud Backup Guide

Working document for Claude Code sessions, written so Abu can read it too. Abu asked for this on 2026-09-21: an optional iCloud save, offered after the About You tutorial, that keeps all of a person's things, with named profiles so that several people on one iCloud account (or one person with several devices) never overwrite each other, six profiles at most. He left the rest open ("do whatever you think is best"), so every call made on his behalf is recorded in section 3 with its reason, and each one is reversible.

The standing rules from the Tilawa Guide apply unchanged: no commit or push unless Abu asks in that message, no em dash and no spaced hyphen standing in for one, never edit Quran or hadith text, always the iPhone 17 Pro simulator, target membership checked before a file is added, never two xcodebuilds at once, and the Equatable render-signature rule.

## 1. In plain words

**What the user sees.** After the About You welcome, one more screen: "Save your progress to iCloud?" It is optional, and "Not now" is never asked again (it lives in Settings from then on). Saying yes asks for a name for this backup ("Abu's iPhone"), and from then on the app quietly keeps a copy of their bookmarks, prayer tracker, khatm, tasbih, journal, favourites, achievements and settings in their own iCloud. Settings shows when it last saved, and has Back Up Now, Restore, Rename, Delete and Stop.

**Several people, one iCloud.** Each device keeps its own named profile. A mother's iPad and a son's iPhone on one family Apple ID each write to their own profile and never touch the other's. Six profiles fit; a seventh asks which old one to delete.

**A new phone.** The welcome screen lists the profiles already in iCloud ("Abu's iPhone, iPhone 15 Pro, saved yesterday"). Picking one restores it and the new phone carries that profile on.

**Restore always asks how.** Replace makes this device match the backup exactly, settings included (the new-phone choice). Merge adds the backup's things to what is already here and leaves this device's settings alone (the second-device choice). Nothing is ever restored without the user asking.

**What never leaves the device.** Location, in any form. The app promises "your location stays on your device" in its permission prompt, so the saved home city, favourite locations and cached prayer times are not backed up; a restored device finds its own location. Downloaded audio and Ask AI chats are not backed up either (the first is re-downloadable, the second is never saved at all).

**Privacy.** The backup lives in the user's private iCloud database. Abu cannot read it, no server of ours exists, and the App Store privacy label does not change.

## 2. What Abu has to do by hand

Code cannot do these, and the feature does not work for real users without them.

1. **Confirm the iCloud capability in Xcode.** Open the project, iPhone target, Signing & Capabilities. iCloud should be listed with CloudKit ticked and the existing container `iCloud.Elmallah.IslamicPillars` selected. This is the container authorized by the app's locally installed development and App Store provisioning profiles. Use this registered container; do not derive a new container name from the bundle identifier.
2. **Get the `Profile` record type into the container's development schema.** Two routes; either is enough.
   - From the terminal, no device needed: generate a CloudKit **management token** (CloudKit Console: click your name at the top right, not the three-line menu beside it, then Settings and its Tokens section; the token is shown once), copy it, and run `Scripts/cloudkit_schema.sh token` on its own: it reads the clipboard (a token typed after `token`, or at its hidden prompt, works too), checks it with CloudKit, and keeps it in the login keychain. A copy that picked up text after the token ("...asked", 2026-09-23) is cut back to the token only when CloudKit accepts the shorter form. Then run `Scripts/cloudkit_schema.sh import`. Import never sends the .ckdb alone: schema files are declarative, so a file holding only `Profile` could drop every other record type. It exports the environment's live schema, swaps `Profile`'s block in, and sends that. The schema is `Resources/CloudKit/Profile.ckdb`: the same ten fields `CloudBackupManager.Field` writes, in CloudKit schema language. `Scripts/cloudkit_schema.sh status` then reports what each environment holds.
   - Or run a Debug build from Xcode on a real iPhone signed in to iCloud, turn the feature on and make a profile. A build run from Xcode talks to the development environment, where the first save creates the type and its fields.
3. **Deploy the schema to production, in the CloudKit Console.** cktool cannot write to production: its schema endpoints answer "endpoint not applicable in the environment 'production'" (tried 2026-09-23). CloudKit Database, the container in the picker at the top with the environment set to Development, then "Deploy Schema Changes..." at the very bottom of the left sidebar, then Deploy. `Scripts/cloudkit_schema.sh deploy` checks both environments first and prints these clicks; `status` confirms afterwards. TestFlight and App Store builds (Xcode Cloud's included) talk to the production environment, where CloudKit never creates a type or a field on the fly: until the deploy, every save there fails with code 12, "Cannot create new type Profile in production schema", which the app shows as "iCloud is not ready for this version of the app yet" and keeps retrying on its own. No new build is needed after the deploy; the installed one starts saving at its next attempt. A NEW field later needs the same two steps again before it ships (a deployed field can be added to, never removed or renamed). This is the step that cannot be caught on a simulator, and the one that bit on 2026-09-22 (progress log).
4. **Sibling apps** (Al-Adhan, Al-Quran) never get iCloud Backup: it is Al-Islam's alone (section 11). Nothing to do for them.

## 3. Decisions

### Made, with reasons

| # | Decision | Why |
|---|---|---|
| 1 | **CloudKit private database**, one record per profile, the data as a compressed file attached to the record. | `NSUbiquitousKeyValueStore` tops out at 1MB and 1024 keys, and the prayer tracker (up to 1850 days) plus khatm (about 6000 ayah keys) plus the journal pass that. iCloud Drive documents upload whenever the system chooses, so "last backed up" could never be truthful, and a fresh install often sees an empty folder for minutes, which reads as "my backup is gone". CloudKit saves either succeed or fail, right away, with a reason. |
| 2 | **One device writes a profile.** Not live two-way sync. | This is what Abu described ("it gets updated repeatedly and replaces it"). Live sync between two devices needs deletion tracking or deleted bookmarks come back, and the watch protocol's own header records how the naive version of that went wrong. A backup that is always whole and always one device's truth cannot half-apply. |
| 3 | **Taking over a profile is allowed and detected.** A new phone that picks an existing profile becomes its writer; the old phone notices at its next save, stops, and says so in Settings. | The new-phone case must work, and two devices silently overwriting each other must not. |
| 4 | **Replace restores content and settings. Merge restores content only.** | Two choices, each with one clear meaning, no third switch. A new phone wants everything back; a second device wants the bookmarks but keeps its own text size. |
| 5 | **Picking an existing profile always restores first, then claims it.** There is no "overwrite that profile with this device" button. | Nothing in iCloud is ever destroyed except by an explicit Delete. Someone who wants this device to win chooses Merge and loses nothing. |
| 6 | **Location is never backed up** (home city, favourite locations, current location, cached prayer times, city anchor). | The location prompt's own words are "your location stays on your device". |
| 7 | **The journal and saved reflections are backed up.** | They are the most personal writing in the app and the hardest to recreate. Journal attachments are text snapshots inside `journal.json`, not separate files, so the file is self-contained. The journal screen's "stays on this device" line changes when backup is on. |
| 8 | **Zakah and inheritance calculator entries are backed up as content, fill-if-empty on Merge.** | They are the user's own figures. Merge never overwrites numbers already typed on this device. |
| 9 | **Fix the keep-content reset while here.** Reset All Settings (keeping content) currently throws away the tasbih lifetime total and day streak, theme highlights, dua session progress, tajweed lessons done, custom reminders, listening history and favourite resources. | They are content by the file's own definition; the list simply predates them. The backup manifest and `resetAllSettings` now share one list, so they cannot drift again. |
| 10 | **An explicit manifest, checked by a script.** Every saved key is classified as content, preference or device-only, and `Scripts/check_cloud_manifest.py` fails when a key in the sources is in no list. | Restoring a device-only key (a migration flag, a notification signature) onto another phone can silently break adhan scheduling. A new key must be a decision, never an accident. |
| 11 | **Stores flush and reload through two notifications**, never by direct calls from the backup code. | `Settings.swift` compiles into the widget and complication, and the sibling apps do not have every store (Al-Adhan has no Quran). A notification reaches whoever exists. |
| 12 | **One table for the nine app-group preferences** (`Settings.appGroupPreferences`: key, whether it is backed up, which way it crosses to the watch, and how to read, report and assign it). The reset, a restore's rehydrate, the watch's send and apply, and the manifest all read it. Round two, 2026-09-21. | Five hand-kept copies of the same nine names (`init`, the reset, `rehydrateAppGroupPreferences`, `watchSyncSnapshot`, `applyWatchSyncSnapshot`) plus a sixth in the manifest. Abu asked for the three paths to share code; this is the list they were each keeping. |
| 13 | **The reset ends the way a restore ends.** `resetAllSettings` finishes in `storedContentWasReplaced(includingPreferences: false)`, the same tail every restore runs. | One tail to get right. The old reset had its own copy and it was missing the app-group re-mirror: after "Reset All Settings" the widget kept computing with the old prayer offsets until one was touched. |
| 14 | **A keep-content reset keeps this device's iCloud claim** (every `cloudBackup.` key), and a full erase makes the manager forget it and mint a new device id. | Both were bugs in round one. The reset wiped the claim keys with the rest of the domain, so it silently turned the backup off and the next launch minted a new device id: the device's own profile then looked like someone else's. The erase left the manager armed in memory, and its next background pass would have uploaded the erased, empty state over the profile. |
| 15 | **App-group preferences are backed up only when chosen** (`explicitlySetKeys`), exactly as the watch sends them. | Abu: an untouched default should not travel. Standard defaults already work that way (the persistent domain holds only what was written), but the app group does not: any extension that assigns a default creates the key, so presence alone lies there. The watch code found this years ago and keeps the chosen-keys ledger for it. |
| 16 | **Content categories: one table, five readers** (`ContentCategory`). | The same thirteen names appear in the Reset dialog (what it keeps), the Erase dialog (what it deletes), the iCloud page's What's Included (with live counts and the size), the restore preview (here against the backup, category by category) and a profile's one-line summary. The script fails when a content key is in no category, so nothing can be backed up without a name the user can read. |
| 17 | **A backup file, beside iCloud.** Export writes the same snapshot to a file for the share sheet; Restore from a File reads one back through the same restore sheet, preview and Replace/Merge question included. | A family member moving to an Apple ID of their own, or anyone who does not use iCloud. The file is the same bytes as the iCloud payload, so nothing new can go wrong inside it. No document type is declared, so a received file is saved to Files and picked from there; declaring one (tap to open) is an Info.plist change Abu can ask for. |
| 18 | **A history the user can read.** Every save, skipped save, restore, export, failure, takeover, rename, delete and stop: a date and one line, the last 30, kept on the device. | "Did it actually back up?" should never need a guess. |

### Still Abu's call

- **A. Wording and placement of the offer.** Built as a second welcome stage right after About You, in the same visual language. Easy to restyle.
- **B. Should Merge also bring settings when this device is a fresh install?** Today Merge never touches settings. On a brand-new install "Replace" is the obvious pick, so this may never matter.
- **C. Auto-backup cadence.** Built as: when the app goes to the background if something changed and the last save is over 5 minutes old, and on opening if the last save is over 6 hours old. Both are constants.
- **D. A document type for the backup file.** Today a received `.islambackup` is saved to Files and picked from there. Declaring the type (Info.plist: `CFBundleDocumentTypes` + `UTExportedTypeDeclarations`, and `onOpenURL` in the root) would let a tapped file open the restore sheet directly. Small, and it touches the project's Info.plist settings, so it waits for Abu's word.
- **E. The watch and a wiped key** (section 6d). A key a reset or a Replace removes on the phone keeps its old value on the watch until touched. Closing it needs a wire tombstone that older watch builds would misread, so it is documented, not built.

## 4. Storage design

- **Container:** `CKContainer(identifier: "iCloud.Elmallah.IslamicPillars")`, the constant `CloudBackupManager.containerIdentifier`. It must be named: `CKContainer.default()` derives its identifier from the bundle id (`iCloud.com.Quran.Elmallah.Islamic-Pillars`), a container this app does not own, and on a real phone every call failed with "bad container" (found 2026-09-22; the simulator never showed it). The entitlement and the App ID's provisioning profiles both carry `iCloud.Elmallah.IslamicPillars`, so the constant, the entitlement and the portal must all agree. Each sibling app needs its own registered container in its entitlements and its own constant.
- **Database:** private. **Zone:** custom zone `Profiles` (a custom zone lists its records without a query index, so nothing has to be configured in the CloudKit Console beyond the schema deploy). **Record type:** `Profile`. **Record name:** a UUID string.
- **Listing profiles** uses `recordZoneChanges(inZoneWith:since:nil, desiredKeys:)` with every field except `payload`, so the picker never downloads a backup it is only naming. No `CKQuery`, so no "field recordName is not marked queryable" failure.

| Field | Type | Meaning |
|---|---|---|
| `nickname` | String | The user's name for the profile. |
| `deviceModel` | String | Marketing name of the last device to write ("iPhone 17 Pro"). |
| `deviceName` | String | The system device name at write time, when the system gives one. |
| `ownerDeviceID` | String | Per-install UUID of the writing device. How a takeover is detected. |
| `updatedAt` | Date | Last successful save. |
| `schemaVersion` | Int64 | A device refuses to restore a payload newer than it understands, and says so. |
| `appVersion` | String | For support. |
| `payload` | CKAsset | The compressed snapshot. |
| `payloadBytes` | Int64 | Compressed size, for the picker. |
| `payloadDigest` | String | SHA-256 of the uncompressed snapshot. A device skips an upload whose digest is unchanged. |
| `summary` | String | One line for the picker ("212 bookmarks, 431 prayer days, 14 journal entries"). |

**Conflict rule.** Saves use `.ifServerRecordUnchanged`. A `serverRecordChanged` error means another device wrote the profile: if its `ownerDeviceID` is ours the save is retried on the server record; if it is not, this device has been taken over and stops (decision 3).

## 5. The snapshot

A binary property list, zlib-compressed. Property lists hold exactly what `UserDefaults` holds (`Data`, `Bool` distinct from `Int`, dates), so nothing is re-encoded or base64'd, and every blob round-trips byte for byte.

```
schemaVersion : 1
createdAt     : Date
device        : { model, name, id }
appVersion    : String
defaults      : { key: plist value }     standard UserDefaults, manifest keys only
appGroup      : { key: plist value }     app-group preference keys only
files         : { name: Data }           Documents files, opaque bytes
```

**Only keys that exist are written.** Standard defaults are read from the app's persistent domain (never through `object(forKey:)`, which would also answer with registered defaults), so a key the source device never set is absent, and Replace removes it on the target so the default applies there too. The app-group preferences are read only when `Settings.explicitlySetKeys` says the user chose them (decision 15): in the app group, presence proves nothing. Abu's mid-session question, "if the setting wasn't changed and it's just a default, maybe don't include it": that is what both rules do, and the bigger win than the bytes is that a later change to a default reaches every device instead of being frozen inside a backup.

**Files are opaque.** `journal.json` is encoded with a plain `JSONEncoder` and the rest of the app uses `Settings.encoder` (milliseconds); the snapshot never decodes either, so neither date strategy can be corrupted. Merge does parse them, generically, as JSON.

### 5a. The manifest (`CloudManifest`)

Three lists, one source of truth shared with `resetAllSettings`:

- **content**: bookmarks, favourites, khatm, plan, positions, histories, prayer tracker and exempt days, menses pause, hadith marks and positions, tasbih counts (all five keys), reading test, tajweed lessons, achievements, theme highlights, dua session progress, custom and Sunnah reminders, calculator entries, letter quiz streak. Each has a merge rule (section 7).
- **preferences**: every appearance, reading, prayer, notification and share option, the About You answers, search filter preferences.
- **deviceOnly**, never backed up: everything location-derived, permission-prompt state, migration and seed flags (`appGroupMirrorsSeeded.v1`, `settings.didSeedExplicitKeys`, `didAdoptMinshawiAdhanDefault`, `ReciterDownloadManagerDedupeVersion`), notification bookkeeping (`lastScheduledHijriYear`, `extraRemindersArmedSignature`, `lastCalculationNotificationAt`), caches (`hijriDate`, `mushaf.lastPageGeometry`, `adhanClipStamps`, widget snapshots), daily transients (`ayahOfTheDayOverride`, `hadithOfTheDayResolved`), `THEfirstLaunch`, `aboutYouVersionSeen`, `watchSync.*`, and the backup's own `cloudBackup.*` state.

`Scripts/check_cloud_manifest.py` extracts every `@AppStorage("…")`, every `forKey: "…"` literal and every `let …Key… = "…"` constant from the sources and fails on a key that is in no list. `-cloudKeyAudit` does the same against the live defaults domain at runtime, which catches keys built from strings.

## 6. Flush and reload: the part that can lose data

A restore writes raw bytes underneath in-memory state that does not notice, and that then writes its stale copy back. The 2026-09-21 stale-state audit found that **seventeen stores have no way to reload**, and that `Settings.contentErasedNotification` has exactly one observer in the whole app (`AchievementsStore`). The full erase has the same hole today: erase everything, tap a tasbih counter, and the erased count comes back.

**Two notifications, declared in `Settings.swift` beside `contentErasedNotification`:**

- `Settings.flushPendingWritesNotification`: "write anything you are holding, now, synchronously". Posted before a backup is built and before a restore writes. Observers register with `queue: nil` so they run inside the `post` call.
- `Settings.storedContentReplacedNotification`: "what is on disk changed underneath you; reload it". Posted after a restore and after a full erase.

A store that has not been created yet observes nothing and needs nothing: it will load the new bytes when first used.

### 6a. Debounced writers (flush)

| Store | Debounce | Flush |
|---|---|---|
| `TasbihCounters` | 500 ms, four keys; **also persists on `willResignActive`**, so backgrounding after a restore rewrote the old counts | `persist()` |
| `ActivityLog` | 1.5 s, whole dictionary | `flush()` |
| Khatm progress (`Settings`) | 250 ms (1 s reduced tier) | `flushPendingKhatmProgress()` |
| Pending last read (`Settings`) | 0.8 s | `flushPendingLastRead()` |
| `HadithStore.ViewedLog` | 1 s, utility queue | `flush()` |
| `QuranPlayer` last listened | 0.8 s, private | a new observer inside `QuranPlayer` commits it; playback is not interrupted |
| `WatchConnectivityManager` | debounced sender | `flushPendingSync()` |

`MushafReader`'s fit-metrics debounce is ignored on purpose: it lives in `Caches/`, is salted by build and OS, and is derived geometry.

### 6b. Load-once stores (reload)

Each gets a `reloadFromStorage()` that also rebuilds its derived indexes:

`TasbihCounters`, `ActivityLog`, `ReadingTestProgress`, `AchievementsStore`, `HadithUserData` (+ `bookmarksByKey`), `HadithStore.lastReadByBook`, `HadithStore.dailyHistoryCache`, `HadithStore.ViewedLog`, `JournalStore` (+ `tagsCache`), `SavedReflectionsStore` (+ `keys`), `ThemeHighlights` (+ `lookup`, `sectionLookup`), `DuaSessionProgress`, `TajweedLessonProgress`, `SunnahReminderStore`, `ExtraRemindersStore`, `QuranPlayer` histories.

Three guards defeat a naive reload and are handled explicitly:
- `HadithStore.loadLastRead()` opens with `guard lastReadByBook.isEmpty`, so it must be cleared first.
- `HadithStore.ViewedLog.loadIfNeeded()` is gated by a `didLoad` flag that is never reset.
- `ReadingTestProgress`'s defaults observer only detects erasure (both keys going to nil, and only after a save). A restore writes values, so it never fired.

### 6c. What a raw write skips

`@AppStorage` reads through to `UserDefaults`, so plain preferences do pick up a raw write. What is skipped is every `didSet` side effect:

- **App-group mirrors.** Thirteen `@AppStorage` keys also mirror into the app group for the widgets: the six `offset*` keys, `switchHijriDateAtMaghrib`, `skyGradients`, `showSkyScene`, `customFajrAngle`, `customIshaAngle`, `lastListenedAyahData`, `lastListenedSurahData`. The watch applier re-mirrors only the first eight. `Settings.remirrorAppGroupPreferences()` covers all thirteen.
- **App-group-only preferences** (`accentColor`, `customAccentColorHex`, `customBackgroundColorHex`, `travelingMode`, `hanafiMadhab`, `prayerCalculation`, `hijriOffset`, `highLatitudeRule`, `customPrayerNames`) are written to the group store and then re-read and **assigned through their Swift setters**, so `markExplicitlySet`, the widget reloads and the prayer refetch all fire. Since round two the nine are one table, `Settings.appGroupPreferences` (section 12), and the reset assigns each one's default through the same `assign`.
- **Presence-checked caches:** `loadKhatmProgressCacheFromStorage()`, `invalidateTrackerCaches()`, `invalidatePrayerComputationCache()`, `invalidateAdhanSoundResourceCache()` (the last was missing from `resetAllSettings` too).

### 6d. The restore sequence

```
post flushPendingWritesNotification            (synchronous)
write defaults (Replace: also remove manifest keys the snapshot lacks)
write app-group preference keys                (Replace only)
write Documents files atomically
Settings.shared.storedContentWasReplaced(includingPreferences:)
    rehydrate the app-group table through its setters   (Replace only)
    remirrorAppGroupPreferences()
    reload khatm cache, invalidate tracker / prayer / adhan-sound caches
    post storedContentReplacedNotification      (every store reloads)
    ReadingState + objectWillChange.send()      (clears both signature caches)
    updateDates(); fetchPrayerTimes(force: true)   (reschedules notifications, reloads widgets)
```

The reset runs the same tail (decision 13): wipe, write back what it spares, assign the table's defaults, then `storedContentWasReplaced(includingPreferences: false)`.

**What the watch does afterwards.** The per-key sync notices every key whose value changed (the next `objectWillChange` diff stamps and pushes them). A key the wipe or the Replace REMOVED is different: the protocol treats an absent key as "no opinion", never as a delete, so the watch keeps that key's old value until it is touched on either device. Closing that needs a tombstone on the wire, and an older watch build handed a tombstone would write it into `UserDefaults` as a value, so it is left as a documented limitation rather than risked.

## 7. Merge rules

Merge works on the JSON inside each blob, generically, so the backup code needs none of the app's model types (which the sibling apps do not all have). Every content key names one rule:

| Rule | Used for | Behaviour |
|---|---|---|
| `unionScalars` | favourite surahs, reciters, saved ayahs, favourite books, tajweed lessons, lit sections | Set union, local order first. |
| `unionObjects(id:newer:)` | bookmarks (`surah`,`ayah`), hadith bookmarks, journal entries (`id`), reflections, lit themes, custom reminders, histories | Union by identity. On a collision the newer timestamp wins; with no timestamp the local one stays, unless only the incoming one carries a note. |
| `maxNumber` | tasbih lifetime and free count, letter quiz streak | The larger. |
| `maxPerKey` | tasbih by day, preset counts, surah open and play counts, activity log days, hadith book counts | Per key, the larger; nested dictionaries merge per inner key. |
| `prayerMarks` | prayer tracker | Per day and prayer; the more definite mark wins (a recorded mark beats none; on a disagreement the local mark stays). |
| `earliestPerKey` | achievement unlock dates | The earlier date: a badge was earned when it was first earned. |
| `newerPosition(stamp:)` | last read, last listened, hadith last read, dua session | The later timestamp; local when there is none. |
| `fillIfMissing` | calculator entries, plan, reading test placement, menses pause | Incoming only when this device has nothing. |
| `keepLocal` | anything unlisted | Untouched. |

## 8. Flow and screens

- **Root stage.** `AlIslamApp.RootStage` gains `.cloudOffer`, after `.aboutYou`, gated on `cloudOfferVersionSeen` against `Settings.cloudOfferCurrentVersion` (the About You pattern: bump to re-ask everyone). Shown to every user once, existing installs included. A launch carrying `-skipNotificationPrompt` never sees it; `-showCloudOffer` forces it.
- **No iCloud account:** the stage still shows, explains that the device is not signed in to iCloud, and offers "Not now". It never blocks the app.
- **Settings.** A "iCloud Backup" page: status line, the profile card, Back Up Now, Restore from a Profile, Rename, Manage Profiles (delete, with confirmation naming what the profile holds), Stop Backing Up on This Device. Sheets use `.sheetDismissToolbar`; destructive actions confirm; pickers are never animated.
- **Failures are quiet.** No account, no network, quota full and taken-over all appear as the status line, never as a modal in the middle of reading.

## 9. Phases

Ordered so the risky part that stands alone lands first and is verified before any network code exists.

| Phase | Work | Status |
|---|---|---|
| 1 | Entitlements: split the watch off `Entitlements-Main`, add iCloud + CloudKit to the main file, verify the built product's entitlements | done 2026-09-21, verified in the build log (watch: siri, time-sensitive, app group; iPhone: those plus the two iCloud keys, container resolved to `iCloud.com.Quran.Elmallah.Islamic-Pillars`) |
| 2 | The two notifications, flush observers, the seventeen `reloadFromStorage()` methods, `remirrorAppGroupPreferences()`. Wire the full erase to post the reload. **No cloud code.** | done 2026-09-21, verified by the round-trip tests in section 10 |
| 3 | `CloudManifest` (shared with `resetAllSettings`), `Scripts/check_cloud_manifest.py`, `CloudSnapshot` build and apply (Replace) | done 2026-09-21; 370 source keys classified, `-cloudKeyAudit` found 14 more in the live domain (all device-only) |
| 4 | Merge rules | done 2026-09-21 (`CloudMergeRules`); the counter and settings cases verified, the set-union and per-day cases exercised only by reading |
| 5 | `CloudBackupManager`: account status, zone, profile list, create, save with takeover detection, rename, delete, the six-profile cap, auto-backup triggers | done 2026-09-21 (`CloudBackupManager`); the network hop itself waits on a signed-in device (section 2, step 2) |
| 6 | The offer stage, the Settings page, Settings search and Tips entries | done 2026-09-21 (`CloudBackupViews`: the offer stage, the restore sheet, the Settings page, search entries, a Tips entry, the journal footer); screenshots light and dark, every state via `-cloudFakeAccount` |
| 7 | Launch args, harness, verification, Release build | done 2026-09-21 except the on-device CloudKit pass; Release build in section 10 |
| 8 | **One core for reset, watch and iCloud** (section 12): the app-group preference table, the reset on the shared tail, the claim spared by a reset and forgotten by an erase, chosen-only app-group capture, the watch list folded into the manifest's preference class, the script's new checks | round two, 2026-09-21 |
| 9 | **Transparency** (section 13): content categories, the two dialogs rewritten from them, What's Included, the restore preview, the history, export and restore from a file, the search and Tips entries | round two, 2026-09-21 |

## 10. Verification

Everything except the network hop is verifiable headlessly (`CloudBackupDebug`, DEBUG only, all results as files in Documents; read them with `simctl get_app_container <udid> <bid> data`):

- `-cloudDumpSnapshot <name>`: capture now, write `<name>.aib` and a readable `<name>.txt`.
- `-cloudRestoreFile <name> replace|merge`: restore from a snapshot file in Documents, no iCloud needed.
- `-cloudStoreProbe <tag>`: one line per store, what it holds IN MEMORY. With a restore in the same launch it also runs before the restore (`cloud-probe-<tag>-before.txt`), which creates every store first; the before/after pair is the proof of reloading.
- `-cloudKeyAudit`: every key in the live defaults domain that the manifest does not classify.
- `-cloudDiffSnapshots <a> <b>`: the keys and files that differ.
- `-cloudProbe`: the manager's state (device id, claim, last save, status) and the profiles it can list; the one check that talks to CloudKit, so on the simulator it reports the missing account.
- `-showCloudOffer`: the offer stage on this launch, even in a scripted run and even if answered (resets `cloudOfferVersionSeen`, as `-showAboutYou` does).
- `-settingsOpen cloudBackup`: the Settings page.
- `-cloudFakeAccount <n>` (+ `-cloudFakeEnabled`): the simulator has no iCloud account, so this pretends there is one and lists n synthetic profiles (the fourth is stamped a newer schema, to see the warning triangle); with `-cloudFakeEnabled` this device already backs up to the first, and a fake profile's "download" is this device's own snapshot with 212 bookmarks, 14 journal entries and 9,120 dhikr planted in it, so the restore preview has two columns. In memory only. A real save still goes to CloudKit and fails with the not-signed-in line. This is how every screen state was screenshotted: `-showCloudOffer -cloudFakeAccount 0` (name this backup), `-showCloudOffer -cloudFakeAccount 3` (the picker), `-launchTabSettings -settingsOpen cloudBackup -cloudFakeAccount 4 -cloudFakeEnabled` (the page, on), and the same without the fake (the page, off; the offer, not signed in). The subpages, the profile menu, the restore sheet and the two Reset dialogs need taps: `idb ui tap` (see the build-workflow memory), one tap each.
- Round two: `-cloudInventory` (What's Included as text, plus the watch snapshot's app-group rows, the chosen keys and the manifest's app-group list), `-cloudExportFile <name>` (Export a Backup File, copied to `Documents/<name>.islambackup`), `-cloudImportFile <name> replace|merge` (Restore from a File on that file), `-cloudResetProbe keep|erase` (Reset All Settings or Erase Everything, then the manager's memory, every `cloudBackup.` key left on disk, the surviving content keys and the four files' sizes), `-cloudResetWriters k1,k2` (a KVO trace of who writes those keys during the reset, to `cloud-reset-writers.txt`).

Recipe (the 17 Pro, every launch with `-skipNotificationPrompt -travelingMode 0`): seed with `-journalSeed -sunnahSeed -extraSeed -seedInt tasbihFreeCount=70,tasbihLifetimeCount=777,offsetFajr=3` plus `-cloudDumpSnapshot snapA`; relaunch with different seeds and `-cloudDumpSnapshot snapB`; then the tests below. Always `-cloudDumpSnapshot orig` FIRST and `-cloudRestoreFile orig replace` LAST, so the simulator comes back as it was.

**Run on 2026-09-21, all passed:**

1. **Replace with live stores.** Device at state A (tasbih 777/70, no journal, Fajr offset 3), every store created by the before-probe, then `-cloudRestoreFile snapB replace`. Same-launch memory: tasbih 9/5, 2 journal entries, offset 0, and the app-group `offsetFajr` mirror 0. Before phase 2 the tasbih line would have stayed 777/70.
2. **Merge.** snapA merged onto state B: counters took the larger side (777/70), the two journal entries stayed, the Fajr offset stayed at this device's 0 (a Merge never touches settings).
3. **The debounced-writer test.** `-cloudRestoreFile snapB replace`, then the Settings app brought to the front (resign-active fires the tasbih flush), then terminate and read the plist directly (`PlistBuddy` on `Library/Preferences/<bid>.plist`; `simctl spawn defaults read` does not reach the container): `tasbihLifetimeCount` 9, `tasbihFreeCount` 5. The restored values survived the flush.
4. **Restore to original.** `-cloudRestoreFile orig replace`: the store probe matched the pre-session probe line for line.

**Round two, 2026-09-21, all passed** (the harness is `scratchpad/round2/run.sh`: launch with args, wait for a Documents file, terminate):

5. **A keep-content reset keeps the claim.** Seeded `cloudBackup.enabled/profileID/nickname/deviceID` (`-seedBool`/`-seedString`) and a Fajr offset of 3 mirrored into the app group, then `-cloudResetProbe keep`: after it, enabled true, profile P1, device D1, the history and every `cloudBackup.` key still on disk, 38 content keys kept, the preferences gone, and the app-group `offsetFajr` mirror 0 (the old reset left it at 3).
6. **An erase forgets the claim.** `-cloudResetProbe erase`: enabled false, profile none, a NEW device id on disk, the history holding one line (the erase itself), the four content files gone, and 2.5 s later every store empty (the previous run had left the activity log's file, so the streak survived an erase).
7. **The file round trip.** Seeded tasbih 777/70, a Fajr offset of 3 and two journal entries; `-cloudExportFile fileA` (6,462 bytes, history "Exported a backup file, 6 KB"); `-cloudRestoreFile orig2 replace` back to the baseline; `-cloudImportFile fileA replace` with a store probe: 777/70, two entries, offset 3 and its mirror 3, history "Restored the file fileA.islambackup with Replace". A PNG picked in the Files picker is refused with the message beside the button and a history line.
8. **Restore to the baseline.** The final probe matched the pre-round probe line for line.

**TRAP found on the way (a simulator artifact, not the app).** After an erase, `bookmarkedAyahsData` and `prayerTrackerData` kept coming back: in no preferences domain (`persistentDomain`, current host, any host, global and the volatile domains all nil) yet answered by `object(forKey:)`. They were in the SIMULATOR-GLOBAL preferences file for the app's domain (`<udid>/data/Library/Preferences/<bid>.plist`, written by `simctl spawn defaults write` seeding in earlier sessions), which the app's search list falls back to and which no in-app erase can touch. A device has no such second domain. Cleared with `simctl spawn <udid> defaults delete <bid> <key>`. While chasing it the reset gained per-key `removeObject` before the domain removal, because a KVO trace showed the domain removal alone posts nothing to the `@AppStorage` observers.

CloudKit itself needs a signed-in iCloud account; the 17 Pro simulator is not signed in, so the network layer is exercised on Abu's device (section 2, step 2). Which environment a build talks to is decided by Xcode, not the code: run from Xcode is development, an archive (TestFlight, App Store, Xcode Cloud) is production. `Scripts/cloudkit_schema.sh status` is the check that the schema is in both.

## 11. Sibling apps: iCloud Backup is Al-Islam's alone

Abu, 2026-09-23: "I don't want iCloud to be transferred. I want iCloud to only support Al-Islam." Al-Adhan and Al-Quran never get the feature, and the sync is built so that it cannot leak into them.

- **The flag.** `HAS_ICLOUD_BACKUP` is defined in Al-Islam's project-level Active Compilation Conditions (Debug and Release, next to `HAS_QURAN`), so every Al-Islam target has it. The companion projects never define it (`FLAG_SKIP=HAS_ICLOUD_BACKUP` in both manifests; `sync_build_flags.py` refuses a sync where it is undecided or set).
- **The feature's own files compile to nothing without it:** the seven `Cloud*.swift` files and `ContentCategories.swift` (the category table measures a `CloudSnapshot`, so it is Al-Islam's too). They are also excluded from the sync (`EXCLUDE=iPhone/Settings/Cloud`, `EXCLUDE=iPhone/Settings/ContentCategories.swift`, `EXCLUDE=Resources/CloudKit`).
- **Every touchpoint in shared code is inside `#if HAS_ICLOUD_BACKUP`:** `SettingsView` (the `Destination.cloudBackup` case and its icon, the `-settingsOpen cloudBackup` mapping, the third profile tile and its door, both Reset dialog texts, whose `#else` sentences are written out), `SettingsSearch` (scope, `backupEntries`, destination), `TipsAndTricks` (`backupTips` between About You and Reset, `resetTipDetail`), `JournalView` (`journalKeepingLine`), `AppLifecycle` (the automatic save), `ViewExtensions` (`needsCloudOffer` is false without it), `Settings` (`cloudOffer*` and `-showCloudOffer`), `SplashScreen` (the iCloud Backup row, "Only in Al-Islam"; the companions' family row names it instead). The Al-Islam root (never synced) gates `CloudOfferView` and the debug task too, only so that a build without the flag is a faithful companion test.
- **Entitlements are per app** (`PER_APP=Resources/Entitlements`): never merged, only reported when Al-Islam changes them. Without this the merge would have added Al-Islam's iCloud container to the companions' entitlements and copied in Al-Islam's watch file with Al-Islam's app group. The watch entitlements split (section on the trap) is therefore not needed in a companion: their watch keeps sharing their main file.
- **The guard for the future.** `check_feature_isolation.py` (run by every `sync_from_islam.sh`) reports a LEAK for any line new since the companion's `.sync-base` that the companion compiles and that names something it will not have, such as a `Cloud*` type or a case declared only inside `#if HAS_ICLOUD_BACKUP`. A new iCloud touchpoint in shared code goes inside the flag, or the next sync stops on it. 2026-09-23: 0 iCloud leaks for either app.
- **The companion test build:** `xcodebuild -project Al-Islam.xcodeproj -scheme iPhone -configuration Debug -destination id=<17 Pro> -derivedDataPath <scratch> SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG HAS_QURAN' build`. Green on 2026-09-23, and its binary holds no `CloudBackupManager`, `CloudOfferView` or `ContentCategory` symbol. A separate derived data path keeps the normal build's cache warm.

## 12. One core for reset, watch and iCloud

Abu, round two: "try to share code between erase settings, Apple Watch sync, and iCloud sync". The three are the same operation seen from three sides, a bulk write underneath a running app, and after this pass they share every list and the tail. Who owns what:

| Piece | Lives in | Reset / Erase | Watch sync | iCloud (and the file) |
|---|---|---|---|---|
| `Settings.contentStorageKeys` | Settings | spared by the wipe (reset), deleted (erase) | never crosses: content is not a setting | the content class; each key has a merge rule and a category |
| `Settings.appGroupPreferences` (the nine, with `read`, `current`, `assign`, `backedUp`, `watch`) | Settings | each assigned its default through `assign` | `watchSyncSnapshot` sends the chosen ones `current`; `applyWatchSyncSnapshot` runs `assign` (the `.phoneToWatch` ones one way, `.never` for the reading-theme hex) | the manifest's app-group keys are the `backedUp` ones; captured only when chosen; Replace rewrites the group store and `rehydrate` runs `assign` |
| `Settings.phoneAuthoritativeSyncKeys` | derived: the table's `.phoneToWatch` keys plus `calculationAutomatic` | | the merge layer drops them from a watch payload | |
| `Settings.watchSyncedAppStorageKeys` | WatchConnectivity | | the `@AppStorage` keys sent and applied | `CloudManifest.preferenceKeys` is the hand-kept list UNIONED with this one, so a key added to the watch sync is a backed-up preference by construction; the script fails if the watch list ever names a content or device-only key |
| `Settings.appGroupMirroredStorageKeys` + `remirrorAppGroupPreferences()` | Settings | in the shared tail (new for the reset) | after every apply | in the shared tail |
| `Settings.flushAllPendingWrites()` | Settings | before the wipe | | before a capture and before an apply |
| `storedContentWasReplaced(includingPreferences:)` | Settings | the tail, `false` (the defaults were just assigned) | not used: a watch apply changes settings only and keeps its lighter tail (no store reload, `runAutoChecks: false` so a peer's value cannot re-arm this device's detection) | the tail, `true` for Replace and `false` for Merge |
| `Settings.resetSparedPrefixes` (`cloudBackup.`) | Settings | spared by a keep-content reset | | the claim, the history and the offer's seen flag (`cloudBackup.offerVersionSeen`) |
| `Settings.contentErasedNotification` | Settings | posted by the erase | | `CloudBackupManager` forgets its claim and mints a new device id |
| `ContentCategory` (thirteen categories over the content keys and files) | iPhone target | the two dialogs' text | | What's Included, the restore preview, the profile summary |

`Scripts/check_cloud_manifest.py` now also checks: every watch-synced key is a preference; every content key and file is in exactly one category; no category names a key outside the content list.

## 13. Transparency: what the user can see

The rule for this pass: the user should never have to guess what is in a backup, what a restore will do, what a reset keeps, or whether anything happened.

- **Reset All Settings.** The message names every category it keeps (from the table) and says the iCloud Backup on this device stays on. **Erase Everything** names every category it deletes, says the claim on this device is forgotten, and says the profile already in iCloud is NOT deleted (that is the iCloud page's Delete). Both are generated, so a new category appears in both automatically.
- **What's Included** (iCloud page, a row with the current size). One row per category with what this device holds right now ("212 bookmarks", "None yet"), a Settings row ("23 changed from their defaults"), the compressed size, then **Never included**: location and saved places (the permission prompt's promise), downloaded recitations, notifications scheduled here, which prompts have been answered, Ask AI conversations, and the Apple Watch's own copy (it follows this iPhone).
- **The restore preview.** The restore sheet downloads the backup first and shows, per category, here against the backup, and the settings count with a note that Merge keeps this device's settings. Replace and Merge are chosen with the numbers in view. The file restore shows the same sheet.
- **History.** A row on the page with the latest line, and a page of the last 30 events: backed up (size, automatic or Back Up Now), checked with nothing new, restored (which profile or file, Replace or Merge), exported, started, switched, renamed, stopped, deleted, failed (why), taken over.
- **The status line** carries the last backup's size and whether it was automatic.
- **Backup file.** Export a Backup File (share sheet; `Al-Islam Backup 2026-09-21.islambackup`) and Restore from a File (the Files picker; any file, the magic bytes decide). The footer says what it is for.

## Progress log

- **2026-09-23 (iCloud stays in Al-Islam).** Abu: "write and update all the scripts to transfer from Al-Islam to the other two apps; don't transfer yet. I don't want iCloud to be transferred; mention it on the splash screen as one of the unique features and make the splash screen look better." `HAS_ICLOUD_BACKUP` added to the project and every shared touchpoint gated (section 11). The sync toolchain in `~/Downloads/Islam` gained `PER_APP`, `FLAG`/`FLAG_SKIP` (`sync_build_flags.py`) and `check_feature_isolation.py`, and the manifests exclude the feature. The splash screen became one feature card with an iCloud Backup row tagged "Only in Al-Islam". Verified: Al-Islam builds with the flag, a build without it is green and has no iCloud symbols, both dry runs are clean of iCloud, and neither companion was touched. Nothing transferred, nothing committed.

- **2026-09-22, evening (production schema).** Abu's phone, a TestFlight build: "Error saving record <CKRecordID ...> to server: Cannot create new type Profile in production schema", in red under the name field of the offer. Not a code fault: TestFlight talks to the production environment, which never creates a type on the fly, and no development save had happened yet, so there was nothing to deploy either. Built `Resources/CloudKit/Profile.ckdb` (the ten fields in CloudKit schema language, checked against `Field`) and `Scripts/cloudkit_schema.sh` (`token`, `validate`, `import`, `deploy`, `status`, `export`, over `xcrun cktool`), so the schema goes up from the terminal without a device. 09-23 hardening, after the token was passed as the first argument (so it landed in the shell history and nothing was saved): the script prints its whole header as help, and import/deploy merge `Profile` into the environment's exported live schema instead of sending the file alone. The token itself had picked up "asked" after it in the copy (an HS512 signature is 86 characters; this one was 91), so CloudKit refused it; `token` now reads the clipboard, an argument or a hidden prompt, verifies with `get-teams`, and trims a stray tail only when CloudKit accepts the trimmed form (seven input paths tested against the fake). **Real run, 2026-09-23:** token saved (team 8HQMC4MQ59, expires 2027-09-23); both environments held only the system `Users` type; `import` put `Profile` in development with all ten fields (verified by `status`). The production deploy is Abu's step: the auto-mode classifier blocked Claude from running `deploy`, and when Abu ran it, cktool's production import answered "endpoint not applicable in the environment 'production'". `deploy` no longer tries; it checks both environments and prints the Console clicks. **Abu deployed from the Console the same evening** (the sheet: create `Profile` type, one index, the three default role grants; the diff only added lines). `status`: development and production both hold `Profile` with all ten fields. iCloud Backup on TestFlight builds needs no new build. Every subcommand was run against a fake cktool: other types kept, an old partial `Profile` block replaced by one complete block, a refused production import leaves production untouched and prints the Console steps, reruns report "already has". `CloudBackupManager`: `Failure.schemaNotDeployed(serverLine)`, matched on any CloudKit error whose server line says "in production schema" (partial failures included), shown as "iCloud is not ready for this version of the app yet: its backup format has not been published. Nothing is lost..." with the server's own sentence kept in the History line; automatic saves keep retrying, so the phone heals itself once the schema is deployed. Section 2 rewritten. Needs Abu: the management token, then `import` and `deploy` (or the Console's Deploy Schema Changes). Nothing committed.

- **2026-09-21, night (round two).** Abu: "keep going, anything else we can do? be as transparent to them as possible and try to share code between erase settings, Apple Watch sync, and iCloud sync." Sections 12 and 13, decisions 12 to 18, phases 8 and 9. `Settings.swift`: `AppGroupPreference` + `appGroupPreferences` (the nine, with `read`/`current`/`assign`, `backedUp`, `watch`), `rehydrateAppGroupPreferences` over the table, `resetAllSettings` rebuilt (spares `resetSparedPrefixes`, per-key removal then the domain, the table's defaults, the shared `storedContentWasReplaced` tail; an erase deletes `contentDocumentFiles` and posts to the manager), `cloudBackup.offerVersionSeen`. `WatchConnectivity.swift`: snapshot and apply over the table, `phoneAuthoritativeSyncKeys` derived, retired `quranSummaryMode` dropped. `CloudManifest.swift`: `appGroupPreferenceKeys` and `files` derived, `preferenceKeys` = listed + watch list. `CloudSnapshot.swift`: chosen-only app-group capture, `fileName`, summary from the categories. New `ContentCategories.swift` (thirteen categories, `ContentInventory`, `CloudJSON.count`). `CloudBackupManager.swift`: `Event` history (30, `cloudBackup.history`), `lastSavedBytes`/`lastSavedAutomatically`, `forgetEverything` on `contentErasedNotification` (new device id), `download` + `restore(_:from:mode:claim:)` + `restore(file:)`, `exportFile`/`importFile`, `noteRefusedFile`, the fake download. `CloudBackupViews.swift`: the restore sheet with the preview (`CloudComparisonRow`, `Source.profile|file`), `CloudContentsView`, `CloudHistoryView`, the What's Included and History rows, the Backup File section (share sheet + `fileImporter`), four more search entries. `SettingsView.swift`: both dialog messages generated from `ContentCategory.listSentence`. Two Tips. `check_cloud_manifest.py`: the watch, app-group and category checks. Tests 5 to 8 in section 10 passed; screenshots light and dark of the page, What's Included, History, the profile menu, the preview in both modes, the share sheet, the picker's refusal, and both Reset dialogs. Release build green (the four pre-existing warnings). Nothing committed.

- **2026-09-21, evening.** Phases 5 to 7 built. `CloudBackupManager.swift` (CloudKit: zone, list via `recordZoneChanges` with no payload, create, save with `.ifServerRecordUnchanged` and the owner check, adopt = restore then claim, restore-only, rename, delete, the six cap, the digest skip, the two automatic triggers wired into `AppLifecycle.sharedScenePhaseChanged`). `CloudBackupViews.swift` (`CloudOfferView` as `RootStage.cloudOffer` after About You, gated by `cloudOfferVersionSeen` in `RootAppearance.needsCloudOffer`; `CloudRestoreSheet`; `CloudBackupSettingsRow` + `CloudBackupSettingsView` under Your Progress; `SettingsSearchEntry.Destination.cloudBackup`; `cloudBackupEntries`). The About You stage now also fades out onto the offer (its opacity checks `.cloudOffer` too). A Tips entry (`app.icloud`), the journal footer (`journalKeepingLine`), `-cloudProbe`, `-showCloudOffer`, `-settingsOpen cloudBackup`, `-cloudFakeAccount`. Two Swift type-checker stalls ("failed to produce diagnostic") on long SwiftUI/ternary expressions, both fixed by splitting into small typed pieces. Screenshots of every state, light and dark, on the 17 Pro. Release build of all four targets green (the four warnings are the pre-existing WordByWord and SettingsQuranView ones). Nothing committed.

- **2026-09-21, later.** Phases 1 to 4 built and verified. Files: `Resources/Entitlements-Watch.entitlements` (new; the watch's two configurations repointed), `Entitlements-Main` gained the iCloud keys; `Settings.swift` gained `flushPendingWritesNotification`, `storedContentReplacedNotification`, `StoredContentObserver`, `flushAllPendingWrites()`, `storedContentWasReplaced(includingPreferences:)`, `rehydrateAppGroupPreferences()`, `appGroupMirroredStorageKeys` + `remirrorAppGroupPreferences()`, and `contentStorageKeys` (the reset's list, now shared and completed); reload/flush in `TasbihCounters`, `ActivityLog`, `HadithUserData`, `HadithStore` (+ `ViewedLog`), `ReadingTestProgress`, `AchievementsStore` (banks silently after a restore), `JournalStore`, `SavedReflectionsStore`, `ThemeHighlights`, `DuaSessionProgress`, `TajweedLessonProgress`, `SunnahReminderStore`, `ExtraRemindersStore`, `QuranPlayer` (pending last-listened flush + history reload); the four file-writing stores moved to serial `ioQueue`s so a restore can wait for a write in flight; `WatchConnectivity.applyWatchSyncSnapshot` now calls the complete re-mirror. New: `CloudManifest.swift`, `CloudSnapshot.swift`, `CloudMergeRules.swift`, `CloudBackupDebug.swift`, `CloudBackupStoreProbe.swift` (iPhone target only), `Scripts/check_cloud_manifest.py`. Debug builds green, zero new warnings. Nothing committed.

- **2026-09-21.** Design. Two read-only audits of the tree (the persistence inventory, then every in-memory store and cache that a raw write would leave stale), a full inventory of saved keys (about 340), and the sibling sync manifests. The second audit changed the plan: seventeen stores cannot reload, six hold debounced writes (one fires on mere backgrounding), and the app-group re-mirror set is thirteen keys, not the eight the watch applier covers. The sibling manifests changed it again: the container identifier is bundle-relative and the backup core is type-free. Abu said "put this all in a doc and make it all clear then start"; section 3's eleven decisions were taken under "do whatever you think is best". Nothing committed.

- **2026-09-21, signing correction.** The new bundle-derived container did not match the locally installed iPhone development and App Store profiles, which authorize `iCloud.Elmallah.IslamicPillars`. Updated the main entitlement to that existing container. Xcode Cloud export still needs verification with a new build.
