#if os(iOS)
import SwiftUI

// The chains of transmission (isnad) of the ten readings: from the Prophet ﷺ down through the
// Companions, the Successors who taught each imam, the imam himself, the links between him and his
// two narrators, the narrators, and the students who carried each narration on (the turuq of
// al-Shatibiyyah and al-Durrah). Drawn as a diagram on the narrator and imam pages and on the
// Qiraat guide, and rendered to a shareable image.
//
// SOURCING. The links are the standard ones of the classical record (Ibn al-Jazari's al-Nashr and
// Ghayat al-Nihayah, al-Dani's al-Taysir, and the turuq of al-Shatibiyyah and al-Durrah), kept
// consistent with the death years the app already ships in `Settings.Riwayah` and `QiraatProfiles`.
// Where a narrator's students are not listed with confidence, the layer is simply left out.

// The model (IsnadNode, IsnadLayer, IsnadBranch, IsnadChain), the diagram and the share button
// live in Islam/Content/IsnadDiagram.swift, which the articles share (2026-10-27).

enum QiraatIsnad {
    // MARK: - The people

    static let prophet = IsnadNode(name: "Prophet Muhammad ﷺ", arabic: "رَسُولُ اللَّهِ ﷺ", detail: String(localized: "d. 11 AH"), role: .prophet)

    enum Companion: String, CaseIterable {
        case ubayy, zayd, uthman, ali, ibnMasud, ibnAbbas, abuHurayrah, ibnAyyash, ibnSaib, umar, abuMusa, abuDarda, husayn

        var node: IsnadNode {
            switch self {
            case .ubayy: return IsnadNode(name: "Ubayy ibn Ka'b", arabic: "أُبَيُّ بنُ كَعبٍ", detail: String(localized: "d. 30 AH"), role: .companion)
            case .zayd: return IsnadNode(name: "Zayd ibn Thabit", arabic: "زَيدُ بنُ ثَابِتٍ", detail: String(localized: "d. 45 AH"), role: .companion)
            case .uthman: return IsnadNode(name: "Uthman ibn Affan", arabic: "عُثمَانُ بنُ عَفَّانَ", detail: String(localized: "d. 35 AH"), role: .companion)
            case .ali: return IsnadNode(name: "Ali ibn Abi Talib", arabic: "عَلِيُّ بنُ أَبِي طَالِبٍ", detail: String(localized: "d. 40 AH"), role: .companion)
            case .ibnMasud: return IsnadNode(name: "Abdullah ibn Mas'ud", arabic: "عَبدُ اللَّهِ بنُ مَسعُودٍ", detail: String(localized: "d. 32 AH"), role: .companion)
            case .ibnAbbas: return IsnadNode(name: "Abdullah ibn Abbas", arabic: "عَبدُ اللَّهِ بنُ عَبَّاسٍ", detail: String(localized: "d. 68 AH"), role: .companion)
            case .abuHurayrah: return IsnadNode(name: "Abu Hurayrah", arabic: "أَبُو هُرَيرَةَ", detail: String(localized: "d. 59 AH"), role: .companion)
            case .ibnAyyash: return IsnadNode(name: "Abdullah ibn Ayyash", arabic: "عَبدُ اللَّهِ بنُ عَيَّاشٍ", detail: String(localized: "d. 64 AH"), role: .companion)
            case .ibnSaib: return IsnadNode(name: "Abdullah ibn as-Sa'ib", arabic: "عَبدُ اللَّهِ بنُ السَّائِبِ", detail: String(localized: "d. c. 70 AH"), role: .companion)
            case .umar: return IsnadNode(name: "Umar ibn al-Khattab", arabic: "عُمَرُ بنُ الخَطَّابِ", detail: String(localized: "d. 23 AH"), role: .companion)
            case .abuMusa: return IsnadNode(name: "Abu Musa al-Ash'ari", arabic: "أَبُو مُوسَى الأَشعَرِيُّ", detail: String(localized: "d. 44 AH"), role: .companion)
            case .abuDarda: return IsnadNode(name: "Abu ad-Darda", arabic: "أَبُو الدَّردَاءِ", detail: String(localized: "d. 32 AH"), role: .companion)
            case .husayn: return IsnadNode(name: "al-Husayn ibn Ali", arabic: "الحُسَينُ بنُ عَلِيٍّ", detail: String(localized: "d. 61 AH"), role: .companion)
            }
        }
    }

    /// An imam's side of the chain: the Successors he read on, and the Companions they read on.
    struct ImamChain {
        let teachers: [IsnadNode]
        let companions: [Companion]
    }

    /// A narrator's side: the links between him and the imam (empty when he read on the imam
    /// himself), and the students who carried his narration on.
    struct NarratorChain {
        let links: [IsnadNode]
        let students: [IsnadNode]
    }

    private static func successor(_ name: String, _ arabic: String, _ died: String) -> IsnadNode {
        IsnadNode(name: name, arabic: arabic, detail: died, role: .successor)
    }

    private static func link(_ name: String, _ arabic: String, _ died: String) -> IsnadNode {
        IsnadNode(name: name, arabic: arabic, detail: died, role: .link)
    }

    private static func student(_ name: String, _ arabic: String, _ died: String) -> IsnadNode {
        IsnadNode(name: name, arabic: arabic, detail: died, role: .student)
    }

    static let imamChains: [String: ImamChain] = [
        Settings.Riwayah.nafiTeacher: ImamChain(
            teachers: [
                successor("Abu Ja'far Yazid ibn al-Qa'qa'", "أَبُو جَعفَرٍ يَزِيدُ بنُ القَعقَاعِ", String(localized: "d. 130 AH")),
                successor("Abd ar-Rahman al-A'raj", "عَبدُ الرَّحمَنِ الأَعرَجُ", String(localized: "d. 117 AH")),
                successor("Shaybah ibn Nisah", "شَيبَةُ بنُ نِصَاحٍ", String(localized: "d. 130 AH")),
                successor("Muslim ibn Jundub", "مُسلِمُ بنُ جُندُبٍ", String(localized: "d. 106 AH")),
                successor("Yazid ibn Ruman", "يَزِيدُ بنُ رُومَانَ", String(localized: "d. 130 AH")),
            ],
            companions: [.ubayy, .zayd, .umar, .ibnAbbas, .abuHurayrah, .ibnAyyash]
        ),
        Settings.Riwayah.ibnKathirTeacher: ImamChain(
            teachers: [
                successor("Mujahid ibn Jabr", "مُجَاهِدُ بنُ جَبرٍ", String(localized: "d. 104 AH")),
                successor("Dirbas, mawla of Ibn Abbas", "دِربَاسٌ مَولَى ابنِ عَبَّاسٍ", String(localized: "d. c. 100 AH")),
            ],
            companions: [.ibnSaib, .ibnAbbas, .ubayy, .zayd, .umar]
        ),
        Settings.Riwayah.abiAmrTeacher: ImamChain(
            teachers: [
                successor("Mujahid ibn Jabr", "مُجَاهِدُ بنُ جَبرٍ", String(localized: "d. 104 AH")),
                successor("Sa'id ibn Jubayr", "سَعِيدُ بنُ جُبَيرٍ", String(localized: "d. 95 AH")),
                successor("Abu Ja'far al-Madani", "أَبُو جَعفَرٍ المَدَنِيُّ", String(localized: "d. 130 AH")),
                successor("al-Hasan al-Basri", "الحَسَنُ البَصرِيُّ", String(localized: "d. 110 AH")),
                successor("Yahya ibn Ya'mar", "يَحيَى بنُ يَعمَرَ", String(localized: "d. 129 AH")),
                successor("Nasr ibn Asim", "نَصرُ بنُ عَاصِمٍ", String(localized: "d. 89 AH")),
            ],
            companions: [.umar, .uthman, .ali, .ibnMasud, .abuMusa, .ibnAbbas, .ubayy, .zayd, .abuHurayrah]
        ),
        Settings.Riwayah.ibnAmirTeacher: ImamChain(
            teachers: [
                successor("al-Mughirah ibn Abi Shihab", "المُغِيرَةُ بنُ أَبِي شِهَابٍ", String(localized: "d. 91 AH")),
            ],
            companions: [.abuDarda, .uthman]
        ),
        Settings.Riwayah.asimTeacher: ImamChain(
            teachers: [
                successor("Abu Abd ar-Rahman as-Sulami", "أَبُو عَبدِ الرَّحمَنِ السُّلَمِيُّ", String(localized: "d. 74 AH")),
                successor("Zirr ibn Hubaysh", "زِرُّ بنُ حُبَيشٍ", String(localized: "d. 82 AH")),
                successor("Abu Amr ash-Shaybani", "أَبُو عَمرٍو الشَّيبَانِيُّ", String(localized: "d. 95 AH")),
            ],
            companions: [.uthman, .ali, .ibnMasud, .ubayy, .zayd]
        ),
        Settings.Riwayah.hamzahTeacher: ImamChain(
            teachers: [
                successor("Sulayman al-A'mash", "سُلَيمَانُ الأَعمَشُ", String(localized: "d. 148 AH")),
                successor("Humran ibn A'yan", "حُمرَانُ بنُ أَعيَنَ", String(localized: "d. 130 AH")),
                successor("Ibn Abi Layla", "مُحَمَّدُ بنُ أَبِي لَيلَى", String(localized: "d. 148 AH")),
                successor("Ja'far as-Sadiq", "جَعفَرٌ الصَّادِقُ", String(localized: "d. 148 AH")),
            ],
            companions: [.uthman, .ali, .ubayy, .zayd, .ibnMasud, .husayn]
        ),
        Settings.Riwayah.kisaiTeacher: ImamChain(
            teachers: [
                successor("Hamzah az-Zayyat", "حَمزَةُ الزَّيَّاتُ", String(localized: "d. 156 AH")),
                successor("Isa ibn Umar al-Hamadani", "عِيسَى بنُ عُمَرَ الهَمَدَانِيُّ", String(localized: "d. 156 AH")),
                successor("Ibn Abi Layla", "مُحَمَّدُ بنُ أَبِي لَيلَى", String(localized: "d. 148 AH")),
                successor("Abu Bakr ibn Ayyash (Shu'bah)", "أَبُو بَكرِ بنُ عَيَّاشٍ", String(localized: "d. 193 AH")),
            ],
            companions: [.umar, .uthman, .ali, .ubayy, .zayd, .ibnMasud, .ibnAbbas, .abuHurayrah, .husayn]
        ),
        Settings.Riwayah.abiJafarTeacher: ImamChain(
            teachers: [],
            companions: [.ibnAyyash, .ibnAbbas, .abuHurayrah, .ubayy, .zayd]
        ),
        Settings.Riwayah.yaqubTeacher: ImamChain(
            teachers: [
                successor("Sallam ibn Sulayman at-Tawil", "سَلَّامُ بنُ سُلَيمَانَ الطَّوِيلُ", String(localized: "d. 171 AH")),
                successor("Shihab ibn Shurnufah", "شِهَابُ بنُ شُرنُفَةَ", String(localized: "d. 162 AH")),
                successor("Mahdi ibn Maymun", "مَهدِيُّ بنُ مَيمُونٍ", String(localized: "d. 171 AH")),
            ],
            companions: [.umar, .uthman, .ali, .ubayy, .zayd, .ibnMasud, .abuMusa, .ibnAbbas, .abuHurayrah]
        ),
        Settings.Riwayah.khalafAshirTeacher: ImamChain(
            teachers: [
                successor("Sulaym ibn Isa", "سُلَيمُ بنُ عِيسَى", String(localized: "d. 188 AH")),
                successor("Abu Bakr ibn Ayyash (Shu'bah)", "أَبُو بَكرِ بنُ عَيَّاشٍ", String(localized: "d. 193 AH")),
                successor("Ya'qub ibn Khalifah al-A'sha", "يَعقُوبُ بنُ خَلِيفَةَ الأَعشَى", String(localized: "d. c. 200 AH")),
            ],
            companions: [.uthman, .ali, .ibnMasud, .zayd, .ubayy, .husayn]
        ),
    ]

    static let narratorChains: [String: NarratorChain] = [
        // Asim
        Settings.Riwayah.hafsTag: NarratorChain(links: [], students: [
            student("Ubayd ibn as-Sabbah", "عُبَيدُ بنُ الصَّبَّاحِ", String(localized: "d. 235 AH")),
            student("Amr ibn as-Sabbah", "عَمرُو بنُ الصَّبَّاحِ", String(localized: "d. 221 AH")),
        ]),
        Settings.Riwayah.shubah: NarratorChain(links: [], students: [
            student("Yahya ibn Adam", "يَحيَى بنُ آدَمَ", String(localized: "d. 203 AH")),
            student("Yahya al-Ulaymi", "يَحيَى العُلَيمِيُّ", String(localized: "d. 243 AH")),
        ]),
        // Nafi
        Settings.Riwayah.warsh: NarratorChain(links: [], students: [
            student("Abu Ya'qub al-Azraq", "أَبُو يَعقُوبَ الأَزرَقُ", String(localized: "d. 240 AH")),
            student("Abu Bakr al-Asbahani", "أَبُو بَكرٍ الأَصبَهَانِيُّ", String(localized: "d. 296 AH")),
        ]),
        Settings.Riwayah.qaloon: NarratorChain(links: [], students: [
            student("Abu Nashit Muhammad ibn Harun", "أَبُو نَشِيطٍ مُحَمَّدُ بنُ هَارُونَ", String(localized: "d. 258 AH")),
            student("Ahmad al-Hulwani", "أَحمَدُ الحُلوَانِيُّ", String(localized: "d. 250 AH")),
        ]),
        // Ibn Kathir
        Settings.Riwayah.buzzi: NarratorChain(links: [
            link("Ikrimah ibn Sulayman", "عِكرِمَةُ بنُ سُلَيمَانَ", String(localized: "d. c. 200 AH")),
            link("Isma'il al-Qust and Shibl ibn Abbad", "إِسمَاعِيلُ القُسطُ وَشِبلُ بنُ عَبَّادٍ", String(localized: "d. 170 / 148 AH")),
        ], students: [
            student("Abu Rabi'ah Muhammad ibn Ishaq", "أَبُو رَبِيعَةَ مُحَمَّدُ بنُ إِسحَاقَ", String(localized: "d. 294 AH")),
            student("Ibn al-Habbab", "ابنُ الحُبَابِ", String(localized: "d. 301 AH")),
        ]),
        Settings.Riwayah.qunbul: NarratorChain(links: [
            link("Ahmad al-Qawwas", "أَحمَدُ القَوَّاسُ", String(localized: "d. 240 AH")),
            link("Abu al-Ikhrit Wahb ibn Wadih", "أَبُو الإِخرِيطِ وَهبُ بنُ وَاضِحٍ", String(localized: "d. 190 AH")),
            link("Isma'il al-Qust", "إِسمَاعِيلُ القُسطُ", String(localized: "d. 170 AH")),
        ], students: [
            student("Ibn Mujahid", "ابنُ مُجَاهِدٍ", String(localized: "d. 324 AH")),
            student("Ibn Shanabudh", "ابنُ شَنَبُوذَ", String(localized: "d. 328 AH")),
        ]),
        // Abu Amr
        Settings.Riwayah.duri: NarratorChain(links: [
            link("Yahya al-Yazidi", "يَحيَى اليَزِيدِيُّ", String(localized: "d. 202 AH")),
        ], students: [
            student("Abu az-Za'ra ibn Abdus", "أَبُو الزَّعرَاءِ ابنُ عَبدُوسٍ", String(localized: "d. c. 280 AH")),
            student("Abu Ja'far ibn Farah", "أَبُو جَعفَرٍ ابنُ فَرَحٍ", String(localized: "d. 303 AH")),
        ]),
        Settings.Riwayah.susi: NarratorChain(links: [
            link("Yahya al-Yazidi", "يَحيَى اليَزِيدِيُّ", String(localized: "d. 202 AH")),
        ], students: [
            student("Abu Imran Musa ibn Jarir", "أَبُو عِمرَانَ مُوسَى بنُ جَرِيرٍ", String(localized: "d. 316 AH")),
            student("Ibn Jumhur", "ابنُ جُمهُورٍ", String(localized: "d. c. 300 AH")),
        ]),
        // Ibn Amir
        Settings.Riwayah.hisham: NarratorChain(links: [
            link("Ayyub ibn Tamim", "أَيُّوبُ بنُ تَمِيمٍ", String(localized: "d. 198 AH")),
            link("Yahya adh-Dhimari", "يَحيَى الذِّمَارِيُّ", String(localized: "d. 145 AH")),
        ], students: [
            student("Ahmad al-Hulwani", "أَحمَدُ الحُلوَانِيُّ", String(localized: "d. 250 AH")),
            student("ad-Dajuni", "الدَّاجُونِيُّ", String(localized: "d. 324 AH")),
        ]),
        Settings.Riwayah.ibnDhakwan: NarratorChain(links: [
            link("Ayyub ibn Tamim", "أَيُّوبُ بنُ تَمِيمٍ", String(localized: "d. 198 AH")),
            link("Yahya adh-Dhimari", "يَحيَى الذِّمَارِيُّ", String(localized: "d. 145 AH")),
        ], students: [
            student("Harun al-Akhfash", "هَارُونُ الأَخفَشُ", String(localized: "d. 292 AH")),
            student("as-Suri", "الصُّورِيُّ", String(localized: "d. 307 AH")),
        ]),
        // Hamzah
        Settings.Riwayah.khalaf: NarratorChain(links: [
            link("Sulaym ibn Isa", "سُلَيمُ بنُ عِيسَى", String(localized: "d. 188 AH")),
        ], students: [
            student("Idris al-Haddad", "إِدرِيسُ الحَدَّادُ", String(localized: "d. 292 AH")),
        ]),
        Settings.Riwayah.khallad: NarratorChain(links: [
            link("Sulaym ibn Isa", "سُلَيمُ بنُ عِيسَى", String(localized: "d. 188 AH")),
        ], students: [
            student("Ibn Shadhan al-Jawhari", "ابنُ شَاذَانَ الجَوهَرِيُّ", String(localized: "d. 286 AH")),
            student("al-Qasim al-Wazzan", "القَاسِمُ الوَزَّانُ", String(localized: "d. c. 290 AH")),
        ]),
        // al-Kisai
        Settings.Riwayah.abuHarith: NarratorChain(links: [], students: [
            student("Muhammad ibn Yahya al-Kisa'i", "مُحَمَّدُ بنُ يَحيَى الكِسَائِيُّ", String(localized: "d. 288 AH")),
            student("Salamah ibn Asim", "سَلَمَةُ بنُ عَاصِمٍ", String(localized: "d. c. 270 AH")),
        ]),
        Settings.Riwayah.duriKisai: NarratorChain(links: [], students: [
            student("Ja'far an-Nasibi", "جَعفَرٌ النَّصِيبِيُّ", String(localized: "d. 307 AH")),
            student("Abu Uthman ad-Darir", "أَبُو عُثمَانَ الضَّرِيرُ", String(localized: "d. c. 290 AH")),
        ]),
        // Abu Ja'far
        Settings.Riwayah.ibnWardan: NarratorChain(links: [], students: [
            student("al-Fadl ibn Shadhan", "الفَضلُ بنُ شَاذَانَ", String(localized: "d. c. 290 AH")),
            student("Hibat Allah ibn Ja'far", "هِبَةُ اللَّهِ بنُ جَعفَرٍ", String(localized: "d. 350 AH")),
        ]),
        Settings.Riwayah.ibnJammaz: NarratorChain(links: [], students: [
            student("al-Hashimi", "الهَاشِمِيُّ", String(localized: "d. c. 250 AH")),
            student("Hafs ad-Duri", "حَفصٌ الدُّورِيُّ", String(localized: "d. 246 AH")),
        ]),
        // Ya'qub
        Settings.Riwayah.ruways: NarratorChain(links: [], students: [
            student("at-Tammar", "التَّمَّارُ", String(localized: "d. c. 310 AH")),
        ]),
        Settings.Riwayah.rawh: NarratorChain(links: [], students: [
            student("Ibn Wahb", "ابنُ وَهبٍ", String(localized: "d. c. 300 AH")),
            student("az-Zubayri", "الزُّبَيرِيُّ", String(localized: "d. c. 300 AH")),
        ]),
        // Khalaf al-Ashir
        Settings.Riwayah.ishaq: NarratorChain(links: [], students: []),
        Settings.Riwayah.idris: NarratorChain(links: [], students: [
            student("ash-Shatti", "الشَّطِّيُّ", String(localized: "d. 370 AH")),
            student("al-Mutawwi'i", "المُطَّوِّعِيُّ", String(localized: "d. 371 AH")),
            student("al-Qati'i", "القَطِيعِيُّ", String(localized: "d. 368 AH")),
        ]),
    ]

    // MARK: - The chains as layers

    private static func imamNode(_ master: QiraahMasterProfile) -> IsnadNode {
        IsnadNode(name: master.id, arabic: master.arabic, detail: String(localized: "\(master.city.localizedDisplay) · d. \(String(master.diedAH).localizedDigits) AH"), role: .imam)
    }

    private static func narratorNode(_ narrator: RiwayahNarratorProfile, highlighted: Bool) -> IsnadNode {
        IsnadNode(name: narrator.name, arabic: narrator.arabic, detail: String(localized: "\(narrator.city.localizedDisplay) · d. \(String(narrator.diedAH).localizedDigits) AH"),
                  role: highlighted ? .narrator : .student)
    }

    /// The Prophet ﷺ, the Companions and the imam's teachers: shared by every chain of one reading.
    private static func topLayers(master: QiraahMasterProfile) -> [IsnadLayer] {
        guard let chain = imamChains[master.id] else { return [] }
        var layers = [
            IsnadLayer(title: String(localized: "THE PROPHET ﷺ"), nodes: [prophet]),
            IsnadLayer(title: String(localized: "THE COMPANIONS"), nodes: chain.companions.map(\.node)),
        ]
        if !chain.teachers.isEmpty {
            layers.append(IsnadLayer(title: String(localized: "THE IMAM'S TEACHERS"), nodes: chain.teachers))
        }
        layers.append(IsnadLayer(title: String(localized: "THE IMAM"), nodes: [imamNode(master)]))
        return layers
    }

    /// The chain as a narrator's page shows it: the whole reading, with his branch highlighted and
    /// his fellow narrator's beside it.
    static func chain(narrator tag: String) -> IsnadChain {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        guard let narrator = QiraatProfiles.narrator(tag: canonical) else { return IsnadChain(top: [], branches: []) }
        return chain(master: narrator.masterID, highlighting: canonical)
    }

    /// The chain of a reading: the Prophet ﷺ down to the imam, then his two narrators, each with the
    /// road the reading took to him. `highlighting` fills one narrator's branch; nil fills both.
    static func chain(master id: String, highlighting tag: String? = nil) -> IsnadChain {
        guard let master = QiraatProfiles.master(id: id) else { return IsnadChain(top: [], branches: []) }
        let branches = QiraatProfiles.narrators(ofMaster: id).map { narrator -> IsnadBranch in
            let canonical = Settings.Riwayah.canonicalTag(narrator.id)
            let highlighted = tag == nil || tag == canonical
            let road = narratorChains[canonical] ?? NarratorChain(links: [], students: [])
            var layers: [IsnadLayer] = []
            if !road.links.isEmpty {
                // Stored narrator-side first ("through A and then B"); a column reads top-down, from
                // the imam, so it runs the other way.
                layers.append(IsnadLayer(title: road.links.count == 1 ? String(localized: "THE LINK") : String(localized: "THE LINKS"),
                                         nodes: road.links.reversed()))
            }
            layers.append(IsnadLayer(title: String(localized: "THE NARRATOR"), nodes: [narratorNode(narrator, highlighted: highlighted)]))
            if !road.students.isEmpty {
                layers.append(IsnadLayer(title: String(localized: "HIS STUDENTS"), nodes: road.students))
            }
            return IsnadBranch(id: canonical, highlighted: highlighted, layers: layers)
        }
        return IsnadChain(top: topLayers(master: master), branches: branches)
    }

    /// How the reading reached both narrators, in one paragraph: the page's own narrator first.
    static func sentence(master id: String, highlighting tag: String? = nil) -> String {
        guard let master = QiraatProfiles.master(id: id) else { return "" }
        var narrators = QiraatProfiles.narrators(ofMaster: id)
        if let tag, let index = narrators.firstIndex(where: { Settings.Riwayah.canonicalTag($0.id) == Settings.Riwayah.canonicalTag(tag) }) {
            narrators.insert(narrators.remove(at: index), at: 0)
        }
        let links = narrators.map { (narratorChains[Settings.Riwayah.canonicalTag($0.id)]?.links ?? []).map(\.name) }
        func path(_ names: [String]) -> String {
            let shown = names.map(\.localizedDisplay)
            // Arabic lists take its own comma ("، "), never the Latin one.
            let comma = AppLanguage.isArabicScript ? "\u{060C} " : ", "
            return shown.count == 1 ? shown[0] : String(localized: "\(shown.dropLast().joined(separator: comma)) and then \(shown.last!)")
        }
        let above = " " + String(localized: "Above \(master.id.localizedDisplay) the chain is one, running through his teachers to the Companions and to the Prophet ﷺ.")
        let names = narrators.count == 2
            ? String(localized: "\(narrators[0].name.localizedDisplay) and \(narrators[1].name.localizedDisplay)")
            : narrators.map { $0.name.localizedDisplay }.sentenceList { $0.joined(separator: " and ") }
        // The same road twice reads as a stutter: Ibn Amir's two narrators both received it through
        // Ayyub ibn Tamim and Yahya adh-Dhimari, so say it once.
        if narrators.count == 2, links[0] == links[1] {
            if links[0].isEmpty { return String(localized: "Both of its narrators, \(names), read on \(master.id.localizedDisplay) himself.") + above }
            return String(localized: "Neither of its narrators met \(master.id.localizedDisplay): \(names) both received the reading through \(path(links[0])).") + above
        }
        let roads = zip(narrators, links).map { narrator, names -> String in
            names.isEmpty ? String(localized: "\(narrator.name.localizedDisplay) read on \(master.id.localizedDisplay) himself")
                : String(localized: "\(narrator.name.localizedDisplay) did not meet him, and received it through \(path(names))")
        }
        let roadList = roads.joined(separator: AppLanguage.isArabicScript ? "\u{061B} " : "; ")
        return String(localized: "The reading of \(master.id.localizedDisplay) reached its two narrators by two roads: \(roadList).") + above
    }

    /// Whether a narrator read on the imam himself (no link between them).
    static func readsDirectly(narrator tag: String) -> Bool {
        (narratorChains[Settings.Riwayah.canonicalTag(tag)]?.links ?? []).isEmpty
    }

}

/// The chain section on a narrator's or an imam's page: the sentence, the diagram, and the way to
/// share it as an image (iOS 16+, one tap: `IsnadShareButton`).
struct QiraatIsnadSection: View {
    let title: String
    let subtitle: String
    let sentence: String?
    let chain: IsnadChain

    var body: some View {
        Section {
            if let sentence, !sentence.isEmpty {
                Text(sentence)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            IsnadDiagram(chain: chain)
                .padding(.vertical, 4)

            if #available(iOS 16.0, *) {
                IsnadShareButton(label: String(localized: "Share the Chain as an Image"), title: title, subtitle: subtitle,
                                 footer: String(localized: "\(AppIdentifiers.displayName) · The Ten Qiraat"), chain: chain)
                    // The chain's last row: `-scrollToChainEnd` lands here, where the chain forks.
                    .id("isnad-chain-end")
            }
        } header: {
            Text("THE CHAIN TO THE PROPHET ﷺ")
        } footer: {
            Text("From the Prophet ﷺ down through the Companions and the imam's own teachers (for the later imams, the generations between those teachers and the Companions are not drawn) to the imam himself, where the chain divides: his two narrators side by side, each with the link between them where there is one, and the students who carried each narration on. The isnad as the classical record gives it (al-Nashr, Ghayat al-Nihayah, and the turuq of al-Shatibiyyah and al-Durrah).")
        }
    }
}

/// Every chain at once: the ten readings, each opening its diagram, from the Qiraat guide.
struct QiraatIsnadIndexView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section {
                    Text("Every one of the ten readings reaches the Prophet ﷺ through an unbroken chain: the narrator read on the imam (or on his students), the imam read on his teachers, they on theirs back to the Successors, the Successors on the Companions, and the Companions on the Prophet ﷺ himself. For the later imams the diagram shows the imam's own teachers and then the Companions, without the generation or two between them. Tap a reading for its chain, or a narrator for his.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(QiraatProfiles.masters(in: QiraatProfiles.sevenIDs + QiraatProfiles.threeIDs)) { master in
                    Section(header: Text("\(master.id.localizedDisplay.uppercased()) · \(master.arabic)")) {
                        NavigationLink(destination: LazyDestination { QiraatIsnadPage(masterID: master.id) }) {
                            QiraatProfileRow(title: String(localized: "The reading of \(master.id.localizedDisplay)"), arabic: master.arabic,
                                             detail: String(localized: "\(master.city.localizedDisplay) · d. \(String(master.diedAH).localizedDigits) AH"), ordinal: nil, systemImage: "point.3.connected.trianglepath.dotted")
                        }
                        ForEach(QiraatProfiles.narrators(ofMaster: master.id)) { narrator in
                            NavigationLink(destination: LazyDestination { QiraatIsnadPage(narratorTag: narrator.id) }) {
                                QiraatProfileRow(title: String(localized: "\(narrator.name.localizedDisplay) an \(master.id.localizedDisplay)"), arabic: narrator.arabic,
                                                 detail: QiraatIsnad.readsDirectly(narrator: narrator.id)
                                                     ? String(localized: "Read on \(master.id.localizedDisplay) himself · d. \(String(narrator.diedAH).localizedDigits) AH")
                                                     : String(localized: "Through the students of \(master.id.localizedDisplay) · d. \(String(narrator.diedAH).localizedDigits) AH"),
                                                 ordinal: nil, systemImage: "link")
                            }
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle("Chains to the Prophet ﷺ")
        .openScreen(.qiraatIsnadIndex)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// One chain on its own page (from the index).
struct QiraatIsnadPage: View {
    var masterID: String? = nil
    var narratorTag: String? = nil

    private var title: String {
        if let narratorTag, let narrator = QiraatProfiles.narrator(tag: narratorTag),
           let master = QiraatProfiles.master(id: narrator.masterID) {
            return String(localized: "\(narrator.name.localizedDisplay) an \(master.id.localizedDisplay)")
        }
        if let masterID { return String(localized: "The reading of \(masterID.localizedDisplay)") }
        return String(localized: "Chain")
    }

    private var subtitle: String {
        if let narratorTag, let narrator = QiraatProfiles.narrator(tag: narratorTag) {
            return String(localized: "\(narrator.arabic) · the chain of the narration to the Prophet ﷺ")
        }
        if let masterID, let master = QiraatProfiles.master(id: masterID) {
            return String(localized: "\(master.arabic) · the chain of the reading to the Prophet ﷺ")
        }
        return ""
    }

    private var chain: IsnadChain {
        if let narratorTag { return QiraatIsnad.chain(narrator: narratorTag) }
        if let masterID { return QiraatIsnad.chain(master: masterID) }
        return IsnadChain(top: [], branches: [])
    }

    /// How the reading reached both narrators, the page's own first.
    private var sentence: String? {
        if let narratorTag, let narrator = QiraatProfiles.narrator(tag: narratorTag) {
            return QiraatIsnad.sentence(master: narrator.masterID, highlighting: narratorTag)
        }
        if let masterID { return QiraatIsnad.sentence(master: masterID) }
        return nil
    }

    var body: some View {
        List {
            QiraatIsnadSection(title: title, subtitle: subtitle, sentence: sentence, chain: chain)
                .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
