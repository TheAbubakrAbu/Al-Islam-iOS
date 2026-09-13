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

struct IsnadNode: Identifiable, Hashable {
    enum Role: Hashable {
        case prophet, companion, successor, imam, link, narrator, student
    }

    let name: String
    let arabic: String
    var detail: String? = nil
    var role: Role = .link

    var id: String { name + "|" + arabic }
}

struct IsnadLayer: Identifiable {
    let title: String
    let nodes: [IsnadNode]
    var id: String { title }
}

enum QiraatIsnad {
    // MARK: - The people

    static let prophet = IsnadNode(name: "Prophet Muhammad ﷺ", arabic: "رَسُولُ اللَّهِ ﷺ", detail: "d. 11 AH", role: .prophet)

    enum Companion: String, CaseIterable {
        case ubayy, zayd, uthman, ali, ibnMasud, ibnAbbas, abuHurayrah, ibnAyyash, ibnSaib, umar, abuMusa, abuDarda, husayn

        var node: IsnadNode {
            switch self {
            case .ubayy: return IsnadNode(name: "Ubayy ibn Ka'b", arabic: "أُبَيُّ بنُ كَعبٍ", detail: "d. 30 AH", role: .companion)
            case .zayd: return IsnadNode(name: "Zayd ibn Thabit", arabic: "زَيدُ بنُ ثَابِتٍ", detail: "d. 45 AH", role: .companion)
            case .uthman: return IsnadNode(name: "Uthman ibn Affan", arabic: "عُثمَانُ بنُ عَفَّانَ", detail: "d. 35 AH", role: .companion)
            case .ali: return IsnadNode(name: "Ali ibn Abi Talib", arabic: "عَلِيُّ بنُ أَبِي طَالِبٍ", detail: "d. 40 AH", role: .companion)
            case .ibnMasud: return IsnadNode(name: "Abdullah ibn Mas'ud", arabic: "عَبدُ اللَّهِ بنُ مَسعُودٍ", detail: "d. 32 AH", role: .companion)
            case .ibnAbbas: return IsnadNode(name: "Abdullah ibn Abbas", arabic: "عَبدُ اللَّهِ بنُ عَبَّاسٍ", detail: "d. 68 AH", role: .companion)
            case .abuHurayrah: return IsnadNode(name: "Abu Hurayrah", arabic: "أَبُو هُرَيرَةَ", detail: "d. 59 AH", role: .companion)
            case .ibnAyyash: return IsnadNode(name: "Abdullah ibn Ayyash", arabic: "عَبدُ اللَّهِ بنُ عَيَّاشٍ", detail: "d. 64 AH", role: .companion)
            case .ibnSaib: return IsnadNode(name: "Abdullah ibn as-Sa'ib", arabic: "عَبدُ اللَّهِ بنُ السَّائِبِ", detail: "d. c. 70 AH", role: .companion)
            case .umar: return IsnadNode(name: "Umar ibn al-Khattab", arabic: "عُمَرُ بنُ الخَطَّابِ", detail: "d. 23 AH", role: .companion)
            case .abuMusa: return IsnadNode(name: "Abu Musa al-Ash'ari", arabic: "أَبُو مُوسَى الأَشعَرِيُّ", detail: "d. 44 AH", role: .companion)
            case .abuDarda: return IsnadNode(name: "Abu ad-Darda", arabic: "أَبُو الدَّردَاءِ", detail: "d. 32 AH", role: .companion)
            case .husayn: return IsnadNode(name: "al-Husayn ibn Ali", arabic: "الحُسَينُ بنُ عَلِيٍّ", detail: "d. 61 AH", role: .companion)
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
                successor("Abu Ja'far Yazid ibn al-Qa'qa'", "أَبُو جَعفَرٍ يَزِيدُ بنُ القَعقَاعِ", "d. 130 AH"),
                successor("Abd ar-Rahman al-A'raj", "عَبدُ الرَّحمَنِ الأَعرَجُ", "d. 117 AH"),
                successor("Shaybah ibn Nisah", "شَيبَةُ بنُ نِصَاحٍ", "d. 130 AH"),
                successor("Muslim ibn Jundub", "مُسلِمُ بنُ جُندُبٍ", "d. 106 AH"),
                successor("Yazid ibn Ruman", "يَزِيدُ بنُ رُومَانَ", "d. 130 AH"),
            ],
            companions: [.ubayy, .zayd, .umar, .ibnAbbas, .abuHurayrah, .ibnAyyash]
        ),
        Settings.Riwayah.ibnKathirTeacher: ImamChain(
            teachers: [
                successor("Mujahid ibn Jabr", "مُجَاهِدُ بنُ جَبرٍ", "d. 104 AH"),
                successor("Dirbas, mawla of Ibn Abbas", "دِربَاسٌ مَولَى ابنِ عَبَّاسٍ", "d. c. 100 AH"),
            ],
            companions: [.ibnSaib, .ibnAbbas, .ubayy, .zayd, .umar]
        ),
        Settings.Riwayah.abiAmrTeacher: ImamChain(
            teachers: [
                successor("Mujahid ibn Jabr", "مُجَاهِدُ بنُ جَبرٍ", "d. 104 AH"),
                successor("Sa'id ibn Jubayr", "سَعِيدُ بنُ جُبَيرٍ", "d. 95 AH"),
                successor("Abu Ja'far al-Madani", "أَبُو جَعفَرٍ المَدَنِيُّ", "d. 130 AH"),
                successor("al-Hasan al-Basri", "الحَسَنُ البَصرِيُّ", "d. 110 AH"),
                successor("Yahya ibn Ya'mar", "يَحيَى بنُ يَعمَرَ", "d. 129 AH"),
                successor("Nasr ibn Asim", "نَصرُ بنُ عَاصِمٍ", "d. 89 AH"),
            ],
            companions: [.umar, .uthman, .ali, .ibnMasud, .abuMusa, .ibnAbbas, .ubayy, .zayd, .abuHurayrah]
        ),
        Settings.Riwayah.ibnAmirTeacher: ImamChain(
            teachers: [
                successor("al-Mughirah ibn Abi Shihab", "المُغِيرَةُ بنُ أَبِي شِهَابٍ", "d. 91 AH"),
            ],
            companions: [.abuDarda, .uthman]
        ),
        Settings.Riwayah.asimTeacher: ImamChain(
            teachers: [
                successor("Abu Abd ar-Rahman as-Sulami", "أَبُو عَبدِ الرَّحمَنِ السُّلَمِيُّ", "d. 74 AH"),
                successor("Zirr ibn Hubaysh", "زِرُّ بنُ حُبَيشٍ", "d. 82 AH"),
                successor("Abu Amr ash-Shaybani", "أَبُو عَمرٍو الشَّيبَانِيُّ", "d. 95 AH"),
            ],
            companions: [.uthman, .ali, .ibnMasud, .ubayy, .zayd]
        ),
        Settings.Riwayah.hamzahTeacher: ImamChain(
            teachers: [
                successor("Sulayman al-A'mash", "سُلَيمَانُ الأَعمَشُ", "d. 148 AH"),
                successor("Humran ibn A'yan", "حُمرَانُ بنُ أَعيَنَ", "d. 130 AH"),
                successor("Ibn Abi Layla", "مُحَمَّدُ بنُ أَبِي لَيلَى", "d. 148 AH"),
                successor("Ja'far as-Sadiq", "جَعفَرٌ الصَّادِقُ", "d. 148 AH"),
            ],
            companions: [.uthman, .ali, .ubayy, .zayd, .ibnMasud, .husayn]
        ),
        Settings.Riwayah.kisaiTeacher: ImamChain(
            teachers: [
                successor("Hamzah az-Zayyat", "حَمزَةُ الزَّيَّاتُ", "d. 156 AH"),
                successor("Isa ibn Umar al-Hamadani", "عِيسَى بنُ عُمَرَ الهَمَدَانِيُّ", "d. 156 AH"),
                successor("Ibn Abi Layla", "مُحَمَّدُ بنُ أَبِي لَيلَى", "d. 148 AH"),
                successor("Abu Bakr ibn Ayyash (Shu'bah)", "أَبُو بَكرِ بنُ عَيَّاشٍ", "d. 193 AH"),
            ],
            companions: [.umar, .uthman, .ali, .ubayy, .zayd, .ibnMasud, .ibnAbbas, .abuHurayrah, .husayn]
        ),
        Settings.Riwayah.abiJafarTeacher: ImamChain(
            teachers: [],
            companions: [.ibnAyyash, .ibnAbbas, .abuHurayrah, .ubayy, .zayd]
        ),
        Settings.Riwayah.yaqubTeacher: ImamChain(
            teachers: [
                successor("Sallam ibn Sulayman at-Tawil", "سَلَّامُ بنُ سُلَيمَانَ الطَّوِيلُ", "d. 171 AH"),
                successor("Shihab ibn Shurnufah", "شِهَابُ بنُ شُرنُفَةَ", "d. 162 AH"),
                successor("Mahdi ibn Maymun", "مَهدِيُّ بنُ مَيمُونٍ", "d. 171 AH"),
            ],
            companions: [.umar, .uthman, .ali, .ubayy, .zayd, .ibnMasud, .abuMusa, .ibnAbbas, .abuHurayrah]
        ),
        Settings.Riwayah.khalafAshirTeacher: ImamChain(
            teachers: [
                successor("Sulaym ibn Isa", "سُلَيمُ بنُ عِيسَى", "d. 188 AH"),
                successor("Abu Bakr ibn Ayyash (Shu'bah)", "أَبُو بَكرِ بنُ عَيَّاشٍ", "d. 193 AH"),
                successor("Ya'qub ibn Khalifah al-A'sha", "يَعقُوبُ بنُ خَلِيفَةَ الأَعشَى", "d. c. 200 AH"),
            ],
            companions: [.uthman, .ali, .ibnMasud, .zayd, .ubayy, .husayn]
        ),
    ]

    static let narratorChains: [String: NarratorChain] = [
        // Asim
        Settings.Riwayah.hafsTag: NarratorChain(links: [], students: [
            student("Ubayd ibn as-Sabbah", "عُبَيدُ بنُ الصَّبَّاحِ", "d. 235 AH"),
            student("Amr ibn as-Sabbah", "عَمرُو بنُ الصَّبَّاحِ", "d. 221 AH"),
        ]),
        Settings.Riwayah.shubah: NarratorChain(links: [], students: [
            student("Yahya ibn Adam", "يَحيَى بنُ آدَمَ", "d. 203 AH"),
            student("Yahya al-Ulaymi", "يَحيَى العُلَيمِيُّ", "d. 243 AH"),
        ]),
        // Nafi
        Settings.Riwayah.warsh: NarratorChain(links: [], students: [
            student("Abu Ya'qub al-Azraq", "أَبُو يَعقُوبَ الأَزرَقُ", "d. 240 AH"),
            student("Abu Bakr al-Asbahani", "أَبُو بَكرٍ الأَصبَهَانِيُّ", "d. 296 AH"),
        ]),
        Settings.Riwayah.qaloon: NarratorChain(links: [], students: [
            student("Abu Nashit Muhammad ibn Harun", "أَبُو نَشِيطٍ مُحَمَّدُ بنُ هَارُونَ", "d. 258 AH"),
            student("Ahmad al-Hulwani", "أَحمَدُ الحُلوَانِيُّ", "d. 250 AH"),
        ]),
        // Ibn Kathir
        Settings.Riwayah.buzzi: NarratorChain(links: [
            link("Ikrimah ibn Sulayman", "عِكرِمَةُ بنُ سُلَيمَانَ", "d. c. 200 AH"),
            link("Isma'il al-Qust and Shibl ibn Abbad", "إِسمَاعِيلُ القُسطُ وَشِبلُ بنُ عَبَّادٍ", "d. 170 / 148 AH"),
        ], students: [
            student("Abu Rabi'ah Muhammad ibn Ishaq", "أَبُو رَبِيعَةَ مُحَمَّدُ بنُ إِسحَاقَ", "d. 294 AH"),
            student("Ibn al-Habbab", "ابنُ الحُبَابِ", "d. 301 AH"),
        ]),
        Settings.Riwayah.qunbul: NarratorChain(links: [
            link("Ahmad al-Qawwas", "أَحمَدُ القَوَّاسُ", "d. 240 AH"),
            link("Abu al-Ikhrit Wahb ibn Wadih", "أَبُو الإِخرِيطِ وَهبُ بنُ وَاضِحٍ", "d. 190 AH"),
            link("Isma'il al-Qust", "إِسمَاعِيلُ القُسطُ", "d. 170 AH"),
        ], students: [
            student("Ibn Mujahid", "ابنُ مُجَاهِدٍ", "d. 324 AH"),
            student("Ibn Shanabudh", "ابنُ شَنَبُوذَ", "d. 328 AH"),
        ]),
        // Abu Amr
        Settings.Riwayah.duri: NarratorChain(links: [
            link("Yahya al-Yazidi", "يَحيَى اليَزِيدِيُّ", "d. 202 AH"),
        ], students: [
            student("Abu az-Za'ra ibn Abdus", "أَبُو الزَّعرَاءِ ابنُ عَبدُوسٍ", "d. c. 280 AH"),
            student("Abu Ja'far ibn Farah", "أَبُو جَعفَرٍ ابنُ فَرَحٍ", "d. 303 AH"),
        ]),
        Settings.Riwayah.susi: NarratorChain(links: [
            link("Yahya al-Yazidi", "يَحيَى اليَزِيدِيُّ", "d. 202 AH"),
        ], students: [
            student("Abu Imran Musa ibn Jarir", "أَبُو عِمرَانَ مُوسَى بنُ جَرِيرٍ", "d. 316 AH"),
            student("Ibn Jumhur", "ابنُ جُمهُورٍ", "d. c. 300 AH"),
        ]),
        // Ibn Amir
        Settings.Riwayah.hisham: NarratorChain(links: [
            link("Ayyub ibn Tamim", "أَيُّوبُ بنُ تَمِيمٍ", "d. 198 AH"),
            link("Yahya adh-Dhimari", "يَحيَى الذِّمَارِيُّ", "d. 145 AH"),
        ], students: [
            student("Ahmad al-Hulwani", "أَحمَدُ الحُلوَانِيُّ", "d. 250 AH"),
            student("ad-Dajuni", "الدَّاجُونِيُّ", "d. 324 AH"),
        ]),
        Settings.Riwayah.ibnDhakwan: NarratorChain(links: [
            link("Ayyub ibn Tamim", "أَيُّوبُ بنُ تَمِيمٍ", "d. 198 AH"),
            link("Yahya adh-Dhimari", "يَحيَى الذِّمَارِيُّ", "d. 145 AH"),
        ], students: [
            student("Harun al-Akhfash", "هَارُونُ الأَخفَشُ", "d. 292 AH"),
            student("as-Suri", "الصُّورِيُّ", "d. 307 AH"),
        ]),
        // Hamzah
        Settings.Riwayah.khalaf: NarratorChain(links: [
            link("Sulaym ibn Isa", "سُلَيمُ بنُ عِيسَى", "d. 188 AH"),
        ], students: [
            student("Idris al-Haddad", "إِدرِيسُ الحَدَّادُ", "d. 292 AH"),
        ]),
        Settings.Riwayah.khallad: NarratorChain(links: [
            link("Sulaym ibn Isa", "سُلَيمُ بنُ عِيسَى", "d. 188 AH"),
        ], students: [
            student("Ibn Shadhan al-Jawhari", "ابنُ شَاذَانَ الجَوهَرِيُّ", "d. 286 AH"),
            student("al-Qasim al-Wazzan", "القَاسِمُ الوَزَّانُ", "d. c. 290 AH"),
        ]),
        // al-Kisai
        Settings.Riwayah.abuHarith: NarratorChain(links: [], students: [
            student("Muhammad ibn Yahya al-Kisa'i", "مُحَمَّدُ بنُ يَحيَى الكِسَائِيُّ", "d. 288 AH"),
            student("Salamah ibn Asim", "سَلَمَةُ بنُ عَاصِمٍ", "d. c. 270 AH"),
        ]),
        Settings.Riwayah.duriKisai: NarratorChain(links: [], students: [
            student("Ja'far an-Nasibi", "جَعفَرٌ النَّصِيبِيُّ", "d. 307 AH"),
            student("Abu Uthman ad-Darir", "أَبُو عُثمَانَ الضَّرِيرُ", "d. c. 290 AH"),
        ]),
        // Abu Ja'far
        Settings.Riwayah.ibnWardan: NarratorChain(links: [], students: [
            student("al-Fadl ibn Shadhan", "الفَضلُ بنُ شَاذَانَ", "d. c. 290 AH"),
            student("Hibat Allah ibn Ja'far", "هِبَةُ اللَّهِ بنُ جَعفَرٍ", "d. 350 AH"),
        ]),
        Settings.Riwayah.ibnJammaz: NarratorChain(links: [], students: [
            student("al-Hashimi", "الهَاشِمِيُّ", "d. c. 250 AH"),
            student("Hafs ad-Duri", "حَفصٌ الدُّورِيُّ", "d. 246 AH"),
        ]),
        // Ya'qub
        Settings.Riwayah.ruways: NarratorChain(links: [], students: [
            student("at-Tammar", "التَّمَّارُ", "d. c. 310 AH"),
        ]),
        Settings.Riwayah.rawh: NarratorChain(links: [], students: [
            student("Ibn Wahb", "ابنُ وَهبٍ", "d. c. 300 AH"),
            student("az-Zubayri", "الزُّبَيرِيُّ", "d. c. 300 AH"),
        ]),
        // Khalaf al-Ashir
        Settings.Riwayah.ishaq: NarratorChain(links: [], students: []),
        Settings.Riwayah.idris: NarratorChain(links: [], students: [
            student("ash-Shatti", "الشَّطِّيُّ", "d. 370 AH"),
            student("al-Mutawwi'i", "المُطَّوِّعِيُّ", "d. 371 AH"),
            student("al-Qati'i", "القَطِيعِيُّ", "d. 368 AH"),
        ]),
    ]

    // MARK: - The chains as layers

    private static func imamNode(_ master: QiraahMasterProfile) -> IsnadNode {
        IsnadNode(name: master.id, arabic: master.arabic, detail: "\(master.city) · d. \(master.diedAH) AH", role: .imam)
    }

    private static func narratorNode(_ narrator: RiwayahNarratorProfile, highlighted: Bool) -> IsnadNode {
        IsnadNode(name: narrator.name, arabic: narrator.arabic, detail: "\(narrator.city) · d. \(narrator.diedAH) AH",
                  role: highlighted ? .narrator : .student)
    }

    /// The Prophet ﷺ, the Companions and the imam's teachers: shared by every chain of one reading.
    private static func topLayers(master: QiraahMasterProfile) -> [IsnadLayer] {
        guard let chain = imamChains[master.id] else { return [] }
        var layers = [
            IsnadLayer(title: "THE PROPHET ﷺ", nodes: [prophet]),
            IsnadLayer(title: "THE COMPANIONS", nodes: chain.companions.map(\.node)),
        ]
        if !chain.teachers.isEmpty {
            layers.append(IsnadLayer(title: "THE IMAM'S TEACHERS", nodes: chain.teachers))
        }
        layers.append(IsnadLayer(title: "THE IMAM", nodes: [imamNode(master)]))
        return layers
    }

    /// The whole chain of a narrator: the Prophet ﷺ at the top, his students at the foot.
    static func chain(narrator tag: String) -> [IsnadLayer] {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        guard let narrator = QiraatProfiles.narrator(tag: canonical),
              let master = QiraatProfiles.master(id: narrator.masterID) else { return [] }
        var layers = topLayers(master: master)
        let chain = narratorChains[canonical] ?? NarratorChain(links: [], students: [])
        if !chain.links.isEmpty {
            layers.append(IsnadLayer(title: chain.links.count == 1 ? "THE LINK BETWEEN" : "THE LINKS BETWEEN", nodes: chain.links))
        }
        layers.append(IsnadLayer(title: "THE NARRATOR", nodes: [narratorNode(narrator, highlighted: true)]))
        if !chain.students.isEmpty {
            layers.append(IsnadLayer(title: "HIS STUDENTS", nodes: chain.students))
        }
        return layers
    }

    /// The chain of a reading: the Prophet ﷺ down to the imam, then his two narrators.
    static func chain(master id: String) -> [IsnadLayer] {
        guard let master = QiraatProfiles.master(id: id) else { return [] }
        var layers = topLayers(master: master)
        let narrators = QiraatProfiles.narrators(ofMaster: id).map { narratorNode($0, highlighted: true) }
        if !narrators.isEmpty {
            layers.append(IsnadLayer(title: "HIS TWO NARRATORS", nodes: narrators))
        }
        return layers
    }

    /// Whether a narrator read on the imam himself (no link between them).
    static func readsDirectly(narrator tag: String) -> Bool {
        (narratorChains[Settings.Riwayah.canonicalTag(tag)]?.links ?? []).isEmpty
    }

    /// One sentence for the narrator's page: how he reaches the imam.
    static func sentence(narrator tag: String) -> String {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        guard let narrator = QiraatProfiles.narrator(tag: canonical),
              let master = QiraatProfiles.master(id: narrator.masterID) else { return "" }
        let chain = narratorChains[canonical] ?? NarratorChain(links: [], students: [])
        if chain.links.isEmpty {
            return "\(narrator.name) read on \(master.id) himself, and \(master.id)'s chain runs through his teachers to the Companions and to the Prophet ﷺ."
        }
        let names = chain.links.map(\.name)
        let path = names.count == 1 ? names[0] : names.dropLast().joined(separator: ", ") + " and then " + names.last!
        return "\(narrator.name) did not meet \(master.id): the reading reached him through \(path), and from \(master.id) it runs through his teachers to the Companions and to the Prophet ﷺ."
    }
}

// MARK: - The diagram

/// The chain as a vertical diagram: one row per generation, connected top to bottom, the Prophet ﷺ
/// at the top and the narrator (or the two narrators) highlighted. Draws the same on the page and in
/// the shared image.
struct QiraatIsnadDiagram: View {
    @Environment(\.appearance) private var appearance

    let layers: [IsnadLayer]
    /// The rendered image's fixed light look (the page follows the app's theme).
    var forImage = false

    private var accent: Color { appearance.accent }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                layerBlock(layer)
                if index < layers.count - 1 {
                    connector
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var connector: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(accent.opacity(0.45))
                .frame(width: 2, height: 14)
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(accent.opacity(0.7))
            Rectangle()
                .fill(accent.opacity(0.45))
                .frame(width: 2, height: 14)
        }
        .padding(.vertical, 2)
    }

    private func layerBlock(_ layer: IsnadLayer) -> some View {
        VStack(spacing: 8) {
            Text(layer.title)
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(forImage ? Color.black.opacity(0.55) : Color.secondary)

            if layer.nodes.count == 1, let node = layer.nodes.first {
                nodeChip(node)
                    .frame(maxWidth: 300)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132, maximum: 200), spacing: 8)], spacing: 8) {
                    ForEach(layer.nodes) { node in
                        nodeChip(node)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func nodeChip(_ node: IsnadNode) -> some View {
        let filled = node.role == .prophet || node.role == .narrator
        let outlined = node.role == .imam || node.role == .companion
        let primaryText: Color = forImage ? .black : .primary
        let secondaryText: Color = forImage ? Color.black.opacity(0.6) : .secondary

        return VStack(spacing: 3) {
            Text(node.arabic)
                .font(appearance.islamArabicFont(base: node.role == .prophet ? 22 : 17, relativeTo: .body))
                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                .foregroundColor(filled ? .white : accent)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)

            Text(node.name)
                .font(.caption.weight(.semibold))
                .foregroundColor(filled ? .white : primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)

            if let detail = node.detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(filled ? Color.white.opacity(0.85) : secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(filled
                      ? AnyShapeStyle(LinearGradient(colors: [accent, accent.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(accent.opacity(node.role == .student ? 0.06 : 0.1)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accent.opacity(outlined ? 0.55 : 0), lineWidth: 1.5)
        )
    }
}

/// The diagram framed for sharing: a title, the chain, and the app's name at the foot, on paper.
struct QiraatIsnadShareCard: View {
    let title: String
    let subtitle: String
    let layers: [IsnadLayer]

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(Color.black.opacity(0.6))
            }
            .multilineTextAlignment(.center)

            QiraatIsnadDiagram(layers: layers, forImage: true)

            Text("Al-Islam · The Ten Qiraat")
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color.black.opacity(0.45))
        }
        .padding(24)
        .frame(width: 560)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
    }
}

/// The chain section on a narrator's or an imam's page: the sentence, the diagram, and the way to
/// share it as an image (iOS 16+, rendered on demand).
struct QiraatIsnadSection: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let subtitle: String
    let sentence: String?
    let layers: [IsnadLayer]

    @State private var rendered: UIImage?
    @State private var rendering = false

    var body: some View {
        Section {
            if let sentence, !sentence.isEmpty {
                Text(sentence)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            QiraatIsnadDiagram(layers: layers)
                .padding(.vertical, 4)

            if #available(iOS 16.0, *) {
                shareRow
            }
        } header: {
            Text("THE CHAIN TO THE PROPHET ﷺ")
        } footer: {
            Text("From the Prophet ﷺ down through the Companions, the Successors who taught the imam, the imam, and the narrator, to the students who carried the narration on: the isnad as the classical record gives it (al-Nashr, Ghayat al-Nihayah, and the turuq of al-Shatibiyyah and al-Durrah).")
        }
    }

    @available(iOS 16.0, *)
    private var shareRow: some View {
        Group {
            if let rendered {
                ShareLink(item: Image(uiImage: rendered), preview: SharePreview(title, image: Image(uiImage: rendered))) {
                    Label("Share the Chain as an Image", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(appearance.accent)
                }
            } else {
                Button {
                    Settings.shared.hapticFeedback()
                    render()
                } label: {
                    HStack {
                        Label("Share the Chain as an Image", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if rendering { ProgressView() }
                    }
                    .foregroundColor(appearance.accent)
                }
                .buttonStyle(.plain)
                .disabled(rendering)
            }
        }
    }

    @available(iOS 16.0, *)
    @MainActor
    private func render() {
        rendering = true
        let card = QiraatIsnadShareCard(title: title, subtitle: subtitle, layers: layers)
            .environment(\.appearance, appearance)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(width: 560, height: nil)
        rendered = renderer.uiImage
        rendering = false
    }
}

/// Every chain at once: the ten readings, each opening its diagram, from the Qiraat guide.
struct QiraatIsnadIndexView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section {
                    Text("Every one of the ten readings reaches the Prophet ﷺ through an unbroken chain: the narrator read on the imam (or on his students), the imam read on the Successors, the Successors on the Companions, and the Companions on the Prophet ﷺ himself. Tap a reading for its chain, or a narrator for his.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(QiraatProfiles.masters(in: QiraatProfiles.sevenIDs + QiraatProfiles.threeIDs)) { master in
                    Section(header: Text("\(master.id.uppercased()) · \(master.arabic)")) {
                        NavigationLink(destination: LazyDestination { QiraatIsnadPage(masterID: master.id) }) {
                            QiraatProfileRow(title: "The reading of \(master.id)", arabic: master.arabic,
                                             detail: "\(master.city) · d. \(master.diedAH) AH", ordinal: nil, systemImage: "point.3.connected.trianglepath.dotted")
                        }
                        ForEach(QiraatProfiles.narrators(ofMaster: master.id)) { narrator in
                            NavigationLink(destination: LazyDestination { QiraatIsnadPage(narratorTag: narrator.id) }) {
                                QiraatProfileRow(title: "\(narrator.name) an \(master.id)", arabic: narrator.arabic,
                                                 detail: QiraatIsnad.readsDirectly(narrator: narrator.id)
                                                     ? "Read on \(master.id) himself · d. \(narrator.diedAH) AH"
                                                     : "Through the students of \(master.id) · d. \(narrator.diedAH) AH",
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
            return "\(narrator.name) an \(master.id)"
        }
        if let masterID { return "The reading of \(masterID)" }
        return "Chain"
    }

    private var subtitle: String {
        if let narratorTag, let narrator = QiraatProfiles.narrator(tag: narratorTag) {
            return "\(narrator.arabic) · the chain of the narration to the Prophet ﷺ"
        }
        if let masterID, let master = QiraatProfiles.master(id: masterID) {
            return "\(master.arabic) · the chain of the reading to the Prophet ﷺ"
        }
        return ""
    }

    private var layers: [IsnadLayer] {
        if let narratorTag { return QiraatIsnad.chain(narrator: narratorTag) }
        if let masterID { return QiraatIsnad.chain(master: masterID) }
        return []
    }

    var body: some View {
        List {
            QiraatIsnadSection(title: title, subtitle: subtitle,
                               sentence: narratorTag.map { QiraatIsnad.sentence(narrator: $0) }, layers: layers)
                .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
