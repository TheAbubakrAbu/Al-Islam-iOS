#if os(iOS)
import SwiftUI

// The Islamic law of inheritance (‘ilm al-fara’id): who inherits, and how much. The shares themselves
// are named in the Quran - 4:11, 4:12 and 4:176 - and the calculator below is an implementation of
// those verses plus the blocking rules the Sunnah and the Companions settled.
//
// Why exact fractions and not Double: the whole subject is fractions of a whole, and the two
// corrections that make it hard (‘awl and radd) are ratio arithmetic. A binary float turns 1/3 into
// something that does not sum back to 1, and a calculator whose shares do not add up is worse than
// no calculator. `Fraction` below is integer numerator/denominator, reduced at every step, so the
// result is exact and the sum is provably 1 (or provably ‘awl/radd, which is the point).

// MARK: - Exact fractions

/// A reduced rational. Small by construction here (denominators run to a few hundred even under
/// ‘awl), so `Int` never comes close to overflowing.
struct Fraction: Equatable, Hashable {
    private(set) var numerator: Int
    private(set) var denominator: Int

    init(_ numerator: Int, _ denominator: Int = 1) {
        precondition(denominator != 0, "a share cannot have a zero denominator")
        var n = numerator, d = denominator
        if d < 0 { n = -n; d = -d }
        let g = Fraction.gcd(abs(n), d)
        self.numerator = g == 0 ? 0 : n / g
        self.denominator = g == 0 ? 1 : d / g
    }

    static let zero = Fraction(0)
    static let one = Fraction(1)

    var isZero: Bool { numerator == 0 }
    var doubleValue: Double { Double(numerator) / Double(denominator) }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a, b = b
        while b != 0 { (a, b) = (b, a % b) }
        return a
    }

    static func + (l: Fraction, r: Fraction) -> Fraction {
        Fraction(l.numerator * r.denominator + r.numerator * l.denominator, l.denominator * r.denominator)
    }

    static func - (l: Fraction, r: Fraction) -> Fraction {
        Fraction(l.numerator * r.denominator - r.numerator * l.denominator, l.denominator * r.denominator)
    }

    static func * (l: Fraction, r: Fraction) -> Fraction {
        Fraction(l.numerator * r.numerator, l.denominator * r.denominator)
    }

    static func / (l: Fraction, r: Fraction) -> Fraction {
        Fraction(l.numerator * r.denominator, l.denominator * r.numerator)
    }

    static func < (l: Fraction, r: Fraction) -> Bool {
        l.numerator * r.denominator < r.numerator * l.denominator
    }

    static func > (l: Fraction, r: Fraction) -> Bool { r < l }

    /// "1/6", or a whole number where the fraction reduces to one.
    var displayString: String {
        if numerator == 0 { return "0" }
        if denominator == 1 { return "\(numerator)" }
        return "\(numerator)/\(denominator)"
    }
}

// MARK: - The heirs

/// The heirs this calculator handles. The Quranic heirs (ashab al-furud) and the whole male
/// residuary line (‘asabah bi'l-nafs) down to the uncle's sons, which is where the classical
/// chain ends before the estate passes to the wider relatives by kinship (dhawu al-arham).
enum FaraidHeir: String, CaseIterable, Hashable {
    case husband, wives
    case father, mother
    case grandfather
    case maternalGrandmother, paternalGrandmother
    case sons, daughters
    case grandsons, granddaughters
    case fullBrothers, fullSisters
    case paternalBrothers, paternalSisters
    case maternalSiblings
    case fullNephews, paternalNephews
    case fullUncles, paternalUncles
    case fullCousins, paternalCousins

    /// Singular/plural handled by the caller; this is the row label.
    var title: String {
        switch self {
        case .husband: return "Husband"
        case .wives: return "Wives"
        case .father: return "Father"
        case .mother: return "Mother"
        case .grandfather: return "Father's father"
        case .maternalGrandmother: return "Mother's mother"
        case .paternalGrandmother: return "Father's mother"
        case .sons: return "Sons"
        case .daughters: return "Daughters"
        case .grandsons: return "Son's sons"
        case .granddaughters: return "Son's daughters"
        case .fullBrothers: return "Full brothers"
        case .fullSisters: return "Full sisters"
        case .paternalBrothers: return "Paternal half-brothers"
        case .paternalSisters: return "Paternal half-sisters"
        case .maternalSiblings: return "Maternal half-siblings"
        case .fullNephews: return "Full brother's sons"
        case .paternalNephews: return "Half-brother's sons"
        case .fullUncles: return "Father's full brothers"
        case .paternalUncles: return "Father's half-brothers"
        case .fullCousins: return "Full uncle's sons"
        case .paternalCousins: return "Half-uncle's sons"
        }
    }

    /// Heirs there can only ever be one of take a toggle; the rest take a stepper.
    var isSingular: Bool {
        switch self {
        case .husband, .father, .mother, .grandfather, .maternalGrandmother, .paternalGrandmother:
            return true
        default:
            return false
        }
    }

    /// The most the UI will let you enter. Four wives is the legal maximum.
    var maximum: Int {
        switch self {
        case .wives: return 4
        default: return 20
        }
    }

    /// The male residuary line, nearest first: each tier takes the whole residue and shuts out
    /// every tier below it. The grandfather sits above the brothers on the view this calculator
    /// follows (see the note fired in `distribute`). The two sisters' slots are the places a
    /// sister stands in her brother's rank because a daughter made her a residuary.
    static let residuaryOrder: [FaraidHeir] = [
        .sons, .grandsons, .father, .grandfather,
        .fullBrothers, .fullSisters, .paternalBrothers, .paternalSisters,
        .fullNephews, .paternalNephews,
        .fullUncles, .paternalUncles, .fullCousins, .paternalCousins
    ]

    /// The tail of that line: pure residuaries with no Quranic share of their own, so their whole
    /// story is "the nearest one takes what is left, the rest take nothing".
    static let distantResiduaries: Set<FaraidHeir> = [
        .fullNephews, .paternalNephews, .fullUncles, .paternalUncles, .fullCousins, .paternalCousins
    ]
}

// MARK: - The distribution

enum Faraid {

    /// One heir's outcome. `share` is the fraction of the whole estate the whole GROUP takes;
    /// `each` is one person's cut of it.
    struct Award: Identifiable {
        let heir: FaraidHeir
        let count: Int
        let share: Fraction
        let each: Fraction
        /// Why this heir got this - the Quranic share, the residue, or both.
        let basis: String

        var id: FaraidHeir { heir }
    }

    struct Result {
        let awards: [Award]
        /// The fixed shares overflowed the estate and every share was scaled down proportionally.
        let didAwl: Bool
        /// The fixed shares left a surplus with no residuary, so the surplus went back to them.
        let didRadd: Bool
        /// Surplus nobody in scope can claim (only a spouse survives, or no heir at all).
        let unclaimed: Fraction
        /// Heirs who are present but inherit nothing, with the reason.
        let blocked: [(heir: FaraidHeir, reason: String)]
        let notes: [String]

        var isEmpty: Bool { awards.isEmpty }
    }

    // MARK: Entry point

    /// The whole distribution, from a count per heir. Pure: same input, same output, no state.
    ///
    /// Order matters and follows the classical sequence - block first, then pay the fixed shares
    /// (ashab al-furud), then hand the residue to the nearest residuary (‘asabah), then correct
    /// with ‘awl or radd. Doing residue before blocking, or ‘awl before the residue, gives wrong
    /// answers on ordinary estates.
    static func distribute(counts: [FaraidHeir: Int]) -> Result {
        func n(_ heir: FaraidHeir) -> Int { max(0, counts[heir] ?? 0) }

        var blocked: [(heir: FaraidHeir, reason: String)] = []
        var notes: [String] = []

        // ---- 1. Presence, after blocking (hajb) ----

        let sons = n(.sons)
        let daughters = n(.daughters)

        // A son blocks his brother's children: the nearer male descendant shuts out the further.
        var grandsons = n(.grandsons)
        var granddaughters = n(.granddaughters)
        if sons > 0 {
            if grandsons > 0 { blocked.append((.grandsons, "blocked by the son")) }
            if granddaughters > 0 { blocked.append((.granddaughters, "blocked by the son")) }
            grandsons = 0
            granddaughters = 0
        }

        let hasFather = n(.father) > 0
        let hasMother = n(.mother) > 0

        // The grandfather inherits only in the father's absence - he is an heir by substitution.
        var hasGrandfather = n(.grandfather) > 0
        if hasGrandfather && hasFather {
            blocked.append((.grandfather, "blocked by the father"))
            hasGrandfather = false
        }

        // Grandmothers take a sixth between them: "the Prophet (peace be upon him) gave the
        // grandmother a sixth" (Abu Dawud 2894, at-Tirmidhi 2101, sahih). The mother shuts out
        // both of them; the father shuts out only his own mother, never the mother's mother.
        var maternalGrandmother = n(.maternalGrandmother) > 0
        var paternalGrandmother = n(.paternalGrandmother) > 0
        if hasMother {
            if maternalGrandmother {
                blocked.append((.maternalGrandmother, "blocked by the mother"))
                maternalGrandmother = false
            }
            if paternalGrandmother {
                blocked.append((.paternalGrandmother, "blocked by the mother"))
                paternalGrandmother = false
            }
        }
        if hasFather && paternalGrandmother {
            blocked.append((.paternalGrandmother, "blocked by the father, her own son"))
            paternalGrandmother = false
        }
        let grandmothers = (maternalGrandmother ? 1 : 0) + (paternalGrandmother ? 1 : 0)

        let hasMaleDescendant = sons > 0 || grandsons > 0
        let hasDescendant = hasMaleDescendant || daughters > 0 || granddaughters > 0

        // Raw sibling head-count, BEFORE blocking: siblings cut the mother from 1/3 to 1/6 even when
        // they are themselves shut out by the father (hajb nuqsan - they diminish without inheriting).
        let siblingHeadCount = n(.fullBrothers) + n(.fullSisters)
            + n(.paternalBrothers) + n(.paternalSisters) + n(.maternalSiblings)

        // Full and paternal siblings fall to a male descendant or to the father. The grandfather is
        // the classical dispute (Abu Bakr shut them out, Zayd shared with them); this follows Abu
        // Bakr, the view Ibn Taymiyyah chose.
        let agnaticSiblingsBlocked = hasMaleDescendant || hasFather || hasGrandfather
        // Maternal siblings fall to ANY descendant, daughters included, and to the father/grandfather:
        // they inherit only in a kalalah estate (4:12), one with no parent and no child.
        let maternalBlocked = hasDescendant || hasFather || hasGrandfather

        var fullBrothers = n(.fullBrothers), fullSisters = n(.fullSisters)
        var paternalBrothers = n(.paternalBrothers), paternalSisters = n(.paternalSisters)
        var maternalSiblings = n(.maternalSiblings)

        if agnaticSiblingsBlocked {
            let reason = hasMaleDescendant ? "blocked by a male descendant" : "blocked by the father or grandfather"
            if fullBrothers > 0 { blocked.append((.fullBrothers, reason)) }
            if fullSisters > 0 { blocked.append((.fullSisters, reason)) }
            if paternalBrothers > 0 { blocked.append((.paternalBrothers, reason)) }
            if paternalSisters > 0 { blocked.append((.paternalSisters, reason)) }
            fullBrothers = 0; fullSisters = 0; paternalBrothers = 0; paternalSisters = 0
            if hasGrandfather && !hasFather && siblingHeadCount > n(.maternalSiblings) {
                notes.append("Siblings alongside a grandfather is a genuine difference among the Companions. Abu Bakr shut them out, and Ibn ‘Abbas, ‘A’ishah and later Ibn Taymiyyah held the same; that is the view applied here. Zayd ibn Thabit divided the estate between them instead, and Malik, ash-Shafi‘i and Ahmad followed him, so a court may well answer differently. Take an estate with both to a scholar.")
            }
        }
        if maternalBlocked && maternalSiblings > 0 {
            blocked.append((.maternalSiblings, hasDescendant ? "blocked by a descendant" : "blocked by the father or grandfather"))
            maternalSiblings = 0
        }

        // A full brother shuts out the paternal siblings entirely.
        if fullBrothers > 0 {
            if paternalBrothers > 0 { blocked.append((.paternalBrothers, "blocked by the full brother")) }
            if paternalSisters > 0 { blocked.append((.paternalSisters, "blocked by the full brother")) }
            paternalBrothers = 0; paternalSisters = 0
        }

        // A sister with no brother of her own becomes a residuary behind a daughter or a son's
        // daughter (‘asabah ma‘a al-ghayr) instead of taking a fixed share, and in that rank she
        // shuts out everyone her brother would have.
        let fullSistersTakeResidueWithDaughters = fullSisters > 0 && fullBrothers == 0
            && (daughters > 0 || granddaughters > 0)
        let paternalSistersTakeResidueWithDaughters = paternalSisters > 0 && paternalBrothers == 0
            && fullSisters == 0 && (daughters > 0 || granddaughters > 0)
        if fullSistersTakeResidueWithDaughters && paternalSisters > 0 && paternalBrothers == 0 {
            blocked.append((.paternalSisters, "blocked by the full sister, who inherits here as a residuary"))
            paternalSisters = 0
        }

        // ---- 2. The residuary line (‘asabah), nearest first ----

        // Walking it once fixes both halves of the same question: who takes the residue, and which
        // of the wider male relatives is shut out by someone nearer.
        let present: [FaraidHeir: Bool] = [
            .sons: sons > 0,
            .grandsons: grandsons > 0,
            .father: hasFather,
            .grandfather: hasGrandfather,
            .fullBrothers: fullBrothers > 0,
            .fullSisters: fullSistersTakeResidueWithDaughters,
            .paternalBrothers: paternalBrothers > 0,
            .paternalSisters: paternalSistersTakeResidueWithDaughters,
            .fullNephews: n(.fullNephews) > 0,
            .paternalNephews: n(.paternalNephews) > 0,
            .fullUncles: n(.fullUncles) > 0,
            .paternalUncles: n(.paternalUncles) > 0,
            .fullCousins: n(.fullCousins) > 0,
            .paternalCousins: n(.paternalCousins) > 0
        ]
        let residuary = FaraidHeir.residuaryOrder.first { present[$0] == true }
        if let residuary {
            for heir in FaraidHeir.residuaryOrder
            where heir != residuary && FaraidHeir.distantResiduaries.contains(heir) && n(heir) > 0 {
                blocked.append((heir, "blocked by a nearer relative on the father's side (\(residuary.title.lowercased()))"))
            }
        }

        // ---- 3. The fixed shares (ashab al-furud) ----

        var fard: [FaraidHeir: (share: Fraction, basis: String)] = [:]

        // Spouses - 4:12. Halved by the existence of ANY child, this marriage's or another's.
        if n(.husband) > 0 {
            fard[.husband] = hasDescendant
                ? (Fraction(1, 4), "1/4 as husband, with a child (4:12)")
                : (Fraction(1, 2), "1/2 as husband, no child (4:12)")
        }
        if n(.wives) > 0 {
            fard[.wives] = hasDescendant
                ? (Fraction(1, 8), "1/8 shared among the wives, with a child (4:12)")
                : (Fraction(1, 4), "1/4 shared among the wives, no child (4:12)")
        }

        // Mother - 4:11. A sixth if the deceased left a child or two or more siblings; a third if not.
        if hasMother {
            fard[.mother] = (hasDescendant || siblingHeadCount >= 2)
                ? (Fraction(1, 6), hasDescendant ? "1/6 as mother, with a child (4:11)" : "1/6 as mother, with two or more siblings (4:11)")
                : (Fraction(1, 3), "1/3 as mother, no child and fewer than two siblings (4:11)")
        }

        if grandmothers > 0 {
            let each = Fraction(1, 6) / Fraction(grandmothers)
            let basis = grandmothers == 1
                ? "1/6 as grandmother (Abu Dawud 2894)"
                : "1/6 shared between the two grandmothers (Abu Dawud 2894)"
            if maternalGrandmother { fard[.maternalGrandmother] = (each, basis) }
            if paternalGrandmother { fard[.paternalGrandmother] = (each, basis) }
        }

        // Father - 4:11. A sixth whenever there is a child; he takes the residue on top of it when
        // that child is female, and takes it as a pure residuary when there is no child at all.
        if hasFather && hasDescendant {
            fard[.father] = (Fraction(1, 6), hasMaleDescendant ? "1/6 as father, with a son (4:11)" : "1/6 as father, with a daughter (4:11)")
        }
        if hasGrandfather && hasDescendant {
            fard[.grandfather] = (Fraction(1, 6), "1/6 as grandfather, standing in for the father")
        }

        // Daughters - 4:11. A son turns them into residuaries at two shares to her one.
        if daughters > 0 && sons == 0 {
            fard[.daughters] = daughters == 1
                ? (Fraction(1, 2), "1/2 as the only daughter (4:11)")
                : (Fraction(2, 3), "2/3 shared among the daughters (4:11)")
        }

        // Son's daughters. Alone they take the daughters' shares; behind a single daughter they take
        // the 1/6 that completes her half to two-thirds; behind two daughters the two-thirds is
        // already spent and they take nothing unless a son's son makes them residuaries.
        if granddaughters > 0 && grandsons == 0 && sons == 0 {
            if daughters == 0 {
                fard[.granddaughters] = granddaughters == 1
                    ? (Fraction(1, 2), "1/2 as the only son's daughter")
                    : (Fraction(2, 3), "2/3 shared among the son's daughters")
            } else if daughters == 1 {
                fard[.granddaughters] = (Fraction(1, 6), "1/6, completing the daughter's half to two-thirds")
            } else {
                blocked.append((.granddaughters, "the daughters already take the full two-thirds"))
                granddaughters = 0
            }
        }

        // Maternal siblings - 4:12. Male and female take EQUALLY here, the one place in fara'id
        // where they do.
        if maternalSiblings > 0 {
            fard[.maternalSiblings] = maternalSiblings == 1
                ? (Fraction(1, 6), "1/6 as the only maternal half-sibling (4:12)")
                : (Fraction(1, 3), "1/3 shared equally among the maternal half-siblings (4:12)")
        }

        // Full sisters - 4:176. With a daughter or son's daughter they become residuaries instead
        // (‘asabah ma‘a al-ghayr), handled in the residue step below.
        if fullSisters > 0 && fullBrothers == 0 && !fullSistersTakeResidueWithDaughters {
            fard[.fullSisters] = fullSisters == 1
                ? (Fraction(1, 2), "1/2 as the only full sister (4:176)")
                : (Fraction(2, 3), "2/3 shared among the full sisters (4:176)")
        }

        // Paternal half-sisters, behind whatever the full sisters took.
        if paternalSisters > 0 && paternalBrothers == 0 && !paternalSistersTakeResidueWithDaughters {
            if fullSisters >= 2 {
                blocked.append((.paternalSisters, "the full sisters already take the full two-thirds"))
                paternalSisters = 0
            } else if fullSisters == 1 {
                fard[.paternalSisters] = (Fraction(1, 6), "1/6, completing the full sister's half to two-thirds")
            } else {
                fard[.paternalSisters] = paternalSisters == 1
                    ? (Fraction(1, 2), "1/2 as the only paternal half-sister")
                    : (Fraction(2, 3), "2/3 shared among the paternal half-sisters")
            }
        }

        // The ‘Umariyyatan: spouse + both parents and nobody else. The mother takes a third of what
        // is LEFT after the spouse, not a third of the estate, so the father is never left with less
        // than her. Named for ‘Umar, who judged it, and followed by the four schools.
        let onlySpouseAndParents = hasMother && hasFather && !hasDescendant && siblingHeadCount == 0
            && grandmothers == 0 && (n(.husband) > 0 || n(.wives) > 0)
        if onlySpouseAndParents {
            let spouseShare = (fard[.husband]?.share ?? .zero) + (fard[.wives]?.share ?? .zero)
            let remainder = Fraction.one - spouseShare
            fard[.mother] = (remainder * Fraction(1, 3), "1/3 of what remains after the spouse (the ‘Umariyyatan)")
        }
        // The same family with the grandfather in the father's place is NOT the ‘Umariyyatan: the
        // mother takes a third of the whole estate, because the rule is about the father himself.
        if hasGrandfather && hasMother && !hasDescendant && siblingHeadCount == 0
            && (n(.husband) > 0 || n(.wives) > 0) {
            notes.append("With the grandfather standing in the father's place the mother takes a third of the WHOLE estate, not a third of what remains after the spouse: the ‘Umariyyatan rule is about the father himself. Malik, ash-Shafi‘i and Ahmad read it that way; Abu Hanifa applied the rule to the grandfather too.")
        }

        // ---- 4. Residue to the nearest residuary (‘asabah) ----

        var fardTotal = fard.values.reduce(Fraction.zero) { $0 + $1.share }
        var residue = Fraction.one - fardTotal
        var residueAwards: [FaraidHeir: (share: Fraction, basis: String)] = [:]

        if residue > .zero, let residuary {
            switch residuary {
            case .sons:
                // "To the male, a portion equal to that of two females" (4:11).
                let parts = sons * 2 + daughters
                residueAwards[.sons] = (residue * Fraction(sons * 2, parts), daughters > 0 ? "residue, two shares to the daughter's one (4:11)" : "residue as the sons")
                if daughters > 0 {
                    residueAwards[.daughters] = (residue * Fraction(daughters, parts), "residue, one share to the son's two (4:11)")
                }
            case .grandsons:
                let parts = grandsons * 2 + granddaughters
                residueAwards[.grandsons] = (residue * Fraction(grandsons * 2, parts), "residue as the son's sons")
                if granddaughters > 0 {
                    residueAwards[.granddaughters] = (residue * Fraction(granddaughters, parts), "residue, one share to the son's son's two")
                }
            case .father:
                residueAwards[.father] = (residue, hasDescendant ? "the residue on top of his sixth" : "the whole residue as father")
            case .grandfather:
                residueAwards[.grandfather] = (residue, hasDescendant ? "the residue on top of his sixth" : "the whole residue as grandfather")
            case .fullBrothers:
                let parts = fullBrothers * 2 + fullSisters
                residueAwards[.fullBrothers] = (residue * Fraction(fullBrothers * 2, parts), fullSisters > 0 ? "residue, two shares to the sister's one (4:176)" : "residue as the full brothers")
                if fullSisters > 0 {
                    residueAwards[.fullSisters] = (residue * Fraction(fullSisters, parts), "residue, one share to the brother's two (4:176)")
                }
            case .fullSisters:
                residueAwards[.fullSisters] = (residue, "residue as full sisters alongside a daughter (‘asabah ma‘a al-ghayr)")
            case .paternalBrothers:
                let parts = paternalBrothers * 2 + paternalSisters
                residueAwards[.paternalBrothers] = (residue * Fraction(paternalBrothers * 2, parts), "residue as the paternal half-brothers")
                if paternalSisters > 0 {
                    residueAwards[.paternalSisters] = (residue * Fraction(paternalSisters, parts), "residue, one share to the brother's two")
                }
            case .paternalSisters:
                residueAwards[.paternalSisters] = (residue, "residue as paternal half-sisters alongside a daughter (‘asabah ma‘a al-ghayr)")
            default:
                residueAwards[residuary] = (residue, "the residue, as the nearest surviving male relative in the father's line")
            }
        }

        // Al-Mushtarakah, the case they argued over in front of ‘Umar: the fixed shares leave the
        // full siblings with nothing while the maternal half-siblings take their third.
        if maternalSiblings >= 2 && (fullBrothers > 0 || fullSisters > 0) && !(residue > .zero) {
            notes.append("This is the case the scholars call al-Mushtarakah. The fixed shares leave nothing for the full siblings while the maternal half-siblings take their third. ‘Umar first ruled exactly that, and Abu Hanifa and Ahmad kept it, which is what is shown here. ‘Umar later shared the third among them all, and Malik and ash-Shafi‘i followed that. Take a real case to a scholar.")
        }

        // ---- 5. ‘Awl and radd ----

        var didAwl = false
        var didRadd = false
        var unclaimed = Fraction.zero

        if fardTotal > .one {
            // ‘Awl: the fixed shares claim more than the estate, so the denominator is raised and
            // every share shrinks in proportion. ‘Umar's judgment in the first such case.
            didAwl = true
            let scale = Fraction.one / fardTotal
            // The basis keeps naming the Quranic share and says it was cut: the share shown is 1/5
            // where the verse says 1/4, and a reader must be able to see why those are both true.
            for (heir, value) in fard { fard[heir] = (value.share * scale, value.basis + ", reduced by ‘awl") }
            fardTotal = .one
            residue = .zero
            notes.append("The fixed shares add up to more than the estate, so every share is reduced in proportion (‘awl). The shares below are the reduced ones.")
        } else if residue > .zero && residueAwards.isEmpty {
            // Radd: a surplus with nobody to take it. It goes back to the fixed-share heirs in
            // proportion - except a spouse, who takes their fixed share and no more.
            let spouseShare = (fard[.husband]?.share ?? .zero) + (fard[.wives]?.share ?? .zero)
            let eligible = fard.filter { $0.key != .husband && $0.key != .wives }
            let eligibleTotal = eligible.values.reduce(Fraction.zero) { $0 + $1.share }

            if eligibleTotal > .zero {
                didRadd = true
                let pot = Fraction.one - spouseShare
                for (heir, value) in eligible {
                    fard[heir] = (pot * (value.share / eligibleTotal), value.basis + ", increased by radd")
                }
                notes.append("Nobody is left to take the residue, so it returns to the fixed-share heirs in proportion to their shares (radd). A spouse does not share in the return.")
            } else {
                unclaimed = residue
                notes.append("No heir in this calculator can take the remaining share. In classical law it passes to the relatives who inherit by kinship (dhawu al-arham: a daughter's children, a sister's children, a maternal uncle) and, failing them, to the public treasury. Most courts today give it to the spouse when there is nobody else at all.")
            }
        }

        // ---- 6. Merge, and split each group's share per person ----

        var merged: [FaraidHeir: (share: Fraction, basis: String)] = fard
        for (heir, value) in residueAwards {
            if let existing = merged[heir] {
                merged[heir] = (existing.share + value.share, existing.basis + ", plus " + value.basis)
            } else {
                merged[heir] = value
            }
        }

        let order = FaraidHeir.allCases
        let awards: [Award] = order.compactMap { heir in
            guard let value = merged[heir], !value.share.isZero else { return nil }
            let count = heir.isSingular ? 1 : max(1, n(heir))
            return Award(heir: heir, count: count, share: value.share,
                         each: value.share / Fraction(count), basis: value.basis)
        }

        // Anyone entered who ends with nothing and no reason yet is a residuary who arrived to find
        // the estate already spent. Saying so matters: an heir who simply vanishes from the screen
        // reads as a bug in the calculator rather than as the answer.
        let awarded = Set(awards.map { $0.heir })
        var named = Set(blocked.map { $0.heir })
        for heir in order where n(heir) > 0 && !awarded.contains(heir) && !named.contains(heir) {
            blocked.append((heir, didAwl
                ? "nothing left: the fixed shares already overflow the estate (‘awl)"
                : "nothing left: the fixed shares use up the whole estate"))
            named.insert(heir)
        }

        // One row per heir, whatever path put them there.
        var seen = Set<FaraidHeir>()
        let uniqueBlocked = blocked.filter { seen.insert($0.heir).inserted }

        return Result(awards: awards, didAwl: didAwl, didRadd: didRadd,
                      unclaimed: unclaimed, blocked: uniqueBlocked, notes: notes)
    }
}

// MARK: - The screen

/// A calculator for the Quranic shares: enter who survived, and it works out each heir's fraction of
/// the estate, applying the blocking rules, ‘awl and radd. The estate figures are optional - without
/// them the answer is fractions and percentages, which is what the law actually specifies.
struct InheritanceCalculatorView: View {
    #if os(iOS)
    @State private var aboutDoor: SignsAboutDoor?
    #endif

    @ObservedObject private var settings = Settings.shared

    // Persisted so a half-entered family survives leaving the screen, matching the zakah calculator.
    @AppStorage("faraidEstate") private var estate = ""
    @AppStorage("faraidFuneral") private var funeral = ""
    @AppStorage("faraidDebts") private var debts = ""
    @AppStorage("faraidBequest") private var bequest = ""
    @AppStorage("faraidCounts") private var storedCounts = ""
    @AppStorage("faraidShowWider") private var showWider = false

    @FocusState private var amountFocused: Bool

    /// `heir.rawValue:count` pairs. One key rather than twenty-two: the set of heirs is likely to
    /// grow, and a stored dictionary does not need a schema migration each time it does.
    private var counts: [FaraidHeir: Int] {
        get {
            var out: [FaraidHeir: Int] = [:]
            for pair in storedCounts.split(separator: ",") {
                let parts = pair.split(separator: ":")
                guard parts.count == 2, let heir = FaraidHeir(rawValue: String(parts[0])),
                      let value = Int(parts[1]) else { continue }
                out[heir] = max(0, min(value, heir.maximum))
            }
            return out
        }
        nonmutating set {
            storedCounts = newValue
                .filter { $0.value > 0 }
                .map { "\($0.key.rawValue):\($0.value)" }
                .sorted()
                .joined(separator: ",")
        }
    }

    private func count(_ heir: FaraidHeir) -> Int { counts[heir] ?? 0 }

    private func setCount(_ heir: FaraidHeir, _ value: Int) {
        var next = counts
        next[heir] = max(0, min(value, heir.maximum))
        // A marriage is one or the other: entering a husband clears the wives and vice versa.
        if value > 0 {
            if heir == .husband { next[.wives] = 0 }
            if heir == .wives { next[.husband] = 0 }
        }
        counts = next
    }

    private var result: Faraid.Result { Faraid.distribute(counts: counts) }

    // MARK: The estate, in the order the law spends it

    private func amount(_ text: String) -> Double {
        let cleaned = text.filter { $0.isNumber || $0 == "." || $0 == "," }
        let normalized = cleaned.contains(".")
            ? cleaned.replacingOccurrences(of: ",", with: "")
            : cleaned.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    private var estateValue: Double { amount(estate) }
    /// What is left once the burial and the debts are settled. The shares are never taken from this
    /// directly: the bequest comes out of it first.
    private var afterDebts: Double { max(estateValue - amount(funeral) - amount(debts), 0) }
    /// "A third, and a third is a lot" (al-Bukhari 2744): the cap the Prophet (peace be upon him)
    /// put on Sa‘d ibn Abi Waqqas, and the reason a bequest can never eat an heir's share.
    private var bequestCap: Double { afterDebts / 3 }
    private var bequestApplied: Double { min(amount(bequest), bequestCap) }
    private var bequestOverThird: Bool { amount(bequest) > bequestCap + 0.005 }
    /// The tarikah the shares actually divide.
    private var distributable: Double { max(afterDebts - bequestApplied, 0) }
    private var hasEstateFigures: Bool { estateValue > 0 }

    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private func formattedAmount(_ value: Double) -> String {
        Self.amountFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private func percent(_ fraction: Fraction) -> String {
        String(format: "%.2f%%", fraction.doubleValue * 100)
    }

    private static let widerHeirs: [FaraidHeir] = [
        .fullNephews, .paternalNephews, .fullUncles, .paternalUncles, .fullCousins, .paternalCousins
    ]

    private var widerEntered: Int {
        Self.widerHeirs.reduce(0) { $0 + count($1) }
    }

    /// "-faraidSection <name>": render one section alone, so a simulator screenshot can reach the
    /// parts that sit below the fold (the shares themselves, most of the time).
    private func shows(_ name: String) -> Bool {
        #if DEBUG
        return Self.debugSection == nil || Self.debugSection == name
        #else
        return true
        #endif
    }

    #if DEBUG
    private static let debugSection: String? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-faraidSection"),
              index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }()
    #endif

    var body: some View {
        List {
            Group {
                // The ANSWER first (Abu, 2026-09-19): who inherits and what each gets, before the
                // estate arithmetic and the five heir groups it is worked out from.
                if shows("shares") { resultSection }
                if shows("estate") { estateSection }
                if shows("heirs") {
                heirSection("SPOUSE", heirs: [.husband, .wives])
                heirSection("PARENTS & GRANDPARENTS", heirs: [.father, .mother, .grandfather, .maternalGrandmother, .paternalGrandmother],
                            footer: "The mother shuts out both grandmothers. The father shuts out his own mother only, never the mother's mother.")
                heirSection("CHILDREN & GRANDCHILDREN", heirs: [.sons, .daughters, .grandsons, .granddaughters],
                            footer: "Son's sons and son's daughters inherit only when there is no surviving son.")
                heirSection("SIBLINGS", heirs: [.fullBrothers, .fullSisters, .paternalBrothers, .paternalSisters, .maternalSiblings],
                            footer: "Maternal half-siblings are the children of the mother only. They inherit only when there is no child and no father.")
                }
                if shows("heirs") || shows("wider") { widerSection }
                if shows("shares"), !result.blocked.isEmpty { blockedSection }
                if shows("shares"), !result.notes.isEmpty { notesSection }
                if shows("scope") { scopeSection }

                // The shares themselves come from the Quran, and the estate is settled after the
                // obligations Islam names. The calculator does the arithmetic; these say what it is
                // arithmetic ABOUT (Abu, 2026-09-19).
                #if os(iOS)
                AboutSignsSection(heading: "About Inheritance in Islam",
                                  systemImage: "divide.circle",
                                  doors: [.quran, .islam, .muslim],
                                  openDoor: $aboutDoor)
                #endif
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        .aboutSignsDestination($aboutDoor)
        #endif
        .navigationTitle("Inheritance Calculator")
        .applyConditionalListStyle()
        #if DEBUG
        // "-focusEstate": focus the amount fields after appear (keyboard toolbar screenshot runs).
        // "-faraidSeed": the Minbariyyah, the case ‘Ali answered from the pulpit, with figures.
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-faraidSeed") {
                storedCounts = "daughters:2,father:1,mother:1,wives:1"
                estate = "120000"
                funeral = "5000"
                debts = "10000"
                bequest = "40000"
            }
            if arguments.contains("-faraidWiderSeed") {
                storedCounts = "fullNephews:2,fullUncles:1,husband:1,maternalGrandmother:1"
                estate = ""
                showWider = true
            }
            if arguments.contains("-focusEstate") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { amountFocused = true }
            }
        }
        #endif
        .toolbar {
            // Content only while the field is focused: with no keyboard up, SwiftUI laid the
            // accessory bar's item out with a negative width ("Invalid frame dimension" runtime
            // issue, lldb-verified in `InputAccessoryBar.body` 2026-09-04; removing the item
            // cleared it). A group, because its content is a ViewBuilder on iOS 15.
            ToolbarItemGroup(placement: .keyboard) {
                if amountFocused {
                    Spacer(minLength: 0)
                    Button("Done") { amountFocused = false }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    storedCounts = ""
                    estate = ""
                    funeral = ""
                    debts = ""
                    bequest = ""
                } label: {
                    Text("Reset")
                }
                .disabled(storedCounts.isEmpty && estate.isEmpty && funeral.isEmpty && debts.isEmpty && bequest.isEmpty)
            }
        }
    }

    // MARK: Sections

    private var estateSection: some View {
        Section(header: Text("THE ESTATE (OPTIONAL)")) {
            amountRow("Total estate", systemImage: "banknote", text: $estate)
            amountRow("Funeral costs", systemImage: "leaf", text: $funeral)
            amountRow("Debts owed", systemImage: "creditcard", text: $debts)
            amountRow("Bequest (wasiyyah)", systemImage: "doc.text", text: $bequest)

            if hasEstateFigures {
                resultRow("After funeral and debts", value: afterDebts)
                if amount(bequest) > 0 {
                    resultRow("Bequest applied", value: bequestApplied)
                }
                HStack {
                    Text("To divide among the heirs")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(formattedAmount(distributable))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(settings.accentColor.accent2)
                }

                if bequestOverThird {
                    Label("A bequest above a third of the estate binds nobody unless the heirs agree to it, so only \(formattedAmount(bequestCap)) is applied here. \"A third, and a third is a lot\" (al-Bukhari 2744).", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ExplainerButton(
                title: "The order of payment",
                body_: "The order is fixed and it is not the heirs' to change: the burial first, then every debt, then a bequest of up to a third of what is left, and only then the shares below. A bequest to somebody who already inherits is not valid unless the other heirs agree to it.\n\nLeave these fields empty to see the shares as fractions only.",
                caption: "Burial, then debts, then a bequest up to a third, then the shares."
            )
        }
    }

    /// A group of heirs. Any rule about who blocks whom rides as a short caption rather than a
    /// footer paragraph - the long form is in "Before you divide anything" at the foot of the screen.
    private func heirSection(_ title: String, heirs: [FaraidHeir], footer: String? = nil) -> some View {
        Section(header: Text(title)) {
            ForEach(heirs, id: \.self) { heir in
                heirRow(heir)
            }

            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
            }
        }
    }

    /// The wider male line is folded away by default: it decides an estate only when nobody nearer
    /// survives, and six more steppers above the answer would cost every ordinary case.
    private var widerSection: some View {
        Section(header: Text("WIDER RELATIVES")) {
            Button {
                settings.hapticFeedback()
                withAnimation { showWider.toggle() }
            } label: {
                HStack {
                    Text("Brother's sons, uncles, cousins")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer(minLength: 8)

                    if widerEntered > 0 && !showWider {
                        Text("\(widerEntered)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(settings.accentColor.accent2)
                    }

                    Image(systemName: showWider ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showWider {
                ForEach(Self.widerHeirs, id: \.self) { heir in
                    heirRow(heir)
                }

                ExplainerButton(
                    title: "Who counts as a wider relative",
                    body_: "Half here always means through the father: a maternal half-brother's sons are not heirs at all, and neither is a maternal uncle. The nearest of these takes whatever the fixed shares leave and shuts out everyone below him.\n\nA sister's children and a daughter's children are outside these rules too: they inherit as dhawu al-arham, once nobody above them survives.",
                    caption: "Half always means through the father."
                )
            }
        }
    }

    private func heirRow(_ heir: FaraidHeir) -> some View {
        HStack(spacing: 10) {
            Text(heir.title)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 8)

            if heir.isSingular {
                Toggle("", isOn: Binding(
                    get: { count(heir) > 0 },
                    set: { setCount(heir, $0 ? 1 : 0) }
                ))
                .labelsHidden()
                .fixedSize()
                .tint(settings.accentColor.color)
            } else {
                Text("\(count(heir))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(count(heir) > 0 ? settings.accentColor.accent2 : .secondary)
                    .frame(minWidth: 22)

                Stepper("") {
                    settings.hapticFeedback()
                    setCount(heir, count(heir) + 1)
                } onDecrement: {
                    settings.hapticFeedback()
                    setCount(heir, count(heir) - 1)
                }
                .labelsHidden()
                .fixedSize()
            }
        }
        .padding(.vertical, 2)
    }

    private func amountRow(_ title: String, systemImage: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(settings.accentColor.color)
                .frame(width: 24, alignment: .center)

            Text(title)
                .font(.subheadline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 8)

            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.subheadline.monospacedDigit())
                .frame(maxWidth: 120)
                .focused($amountFocused)
        }
        .padding(.vertical, 2)
    }

    private func resultRow(_ title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(formattedAmount(value))
                .font(.subheadline.monospacedDigit())
                .foregroundColor(.secondary)
        }
    }

    private var resultSection: some View {
        Section(header: Text("WHO INHERITS")) {
            if result.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nothing to divide yet.")
                        .font(.subheadline.weight(.semibold))
                    Text("Add the surviving heirs below and their shares appear here as you go.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            } else {
                ForEach(result.awards) { award in
                    awardRow(award)
                }

                if !result.unclaimed.isZero {
                    HStack {
                        Text("Unassigned")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(result.unclaimed.displayString)
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }

                if result.didAwl {
                    resultBadge("Shares reduced in proportion (‘awl)", systemImage: "arrow.down.right.and.arrow.up.left")
                }
                if result.didRadd {
                    resultBadge("Surplus returned to the heirs (radd)", systemImage: "arrow.uturn.backward")
                }
            }
        }
    }

    private func awardRow(_ award: Faraid.Award) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(award.count > 1 ? "\(award.heir.title) (\(award.count))" : award.heir.title)
                    .font(.headline)

                Spacer()

                Text(award.share.displayString)
                    .font(.headline.monospacedDigit())
                    .foregroundColor(settings.accentColor.accent2)
            }

            HStack {
                Text(award.basis)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Text(percent(award.share))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            if distributable > 0 {
                HStack {
                    Text(award.count > 1 ? "Each of the \(award.count)" : "Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formattedAmount(award.each.doubleValue * distributable))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = distributable > 0
                    ? "\(award.heir.title): \(award.share.displayString) (\(formattedAmount(award.share.doubleValue * distributable)))"
                    : "\(award.heir.title): \(award.share.displayString)"
            } label: {
                Label("Copy Share", systemImage: "doc.on.doc")
            }
        }
    }

    private func resultBadge(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(settings.accentColor.color)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var blockedSection: some View {
        Section(header: Text("PRESENT BUT NOT INHERITING")) {
            ForEach(result.blocked, id: \.heir) { entry in
                HStack {
                    Text(entry.heir.title)
                        .font(.subheadline)
                    Spacer(minLength: 8)
                    Text(entry.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 1)
            }
        }
    }

    private var notesSection: some View {
        Section(header: Text("NOTES ON THIS CASE")) {
            ForEach(result.notes, id: \.self) { note in
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var scopeSection: some View {
        Section(header: Text("BEFORE YOU DIVIDE ANYTHING")) {
            Text(Self.scopeNote)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    static let scopeNote = "The shares are fixed by Allah in Surah an-Nisa: 4:11, 4:12 and 4:176. يُوصِيكُمُ ٱللَّهُ فِىٓ أَولَـٰدِكُم \"Allah instructs you concerning your children\" (4:11), and the verses close with تِلكَ حُدُودُ ٱللَّهِ \"these are the limits set by Allah\" (4:13).\n\nTwo things stop a relative inheriting however close they are. A killer takes nothing from the one he killed, and there is no inheritance between a Muslim and a non-Muslim: \"The Muslim does not inherit from the disbeliever, nor the disbeliever from the Muslim\" (al-Bukhari 6764). An heir must also be alive when the death happens, which is why an unborn child's share is held back until the birth.\n\nThis is a quick guide for the ordinary case, and nothing more. It is not a fatwa. It covers the Quranic heirs and the male line on the father's side down to the uncle's sons. It does NOT handle the relatives who inherit by kinship alone (a daughter's children, a sister's children, a maternal uncle), great-grandparents, a missing or unborn heir, an estate divided across countries, or the places the Companions themselves differed, such as the grandfather inheriting alongside siblings.\n\nInheritance is the branch of knowledge the Prophet (peace be upon him) singled out for careful learning, and a real estate is somebody's wealth and somebody's grief at once. Take yours to a knowledgeable scholar of Ahl as-Sunnah wa al-Jamaʿah, and to a court where one is needed, before anything is divided on these numbers."
}

#Preview {
    AlIslamPreviewContainer {
        InheritanceCalculatorView()
    }
}
#endif
