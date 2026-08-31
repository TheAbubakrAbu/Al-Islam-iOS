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

/// The heirs this calculator handles: the ones who actually turn up in ordinary estates. Distant
/// residuaries (uncles, nephews, cousins) and the outer grandparents are deliberately out of scope -
/// see `InheritanceCalculatorView.scopeNote`.
enum FaraidHeir: String, CaseIterable, Hashable {
    case husband, wives
    case father, mother
    case grandfather, grandmothers
    case sons, daughters
    case grandsons, granddaughters
    case fullBrothers, fullSisters
    case paternalBrothers, paternalSisters
    case maternalSiblings

    /// Singular/plural handled by the caller; this is the row label.
    var title: String {
        switch self {
        case .husband: return "Husband"
        case .wives: return "Wives"
        case .father: return "Father"
        case .mother: return "Mother"
        case .grandfather: return "Paternal grandfather"
        case .grandmothers: return "Grandmothers"
        case .sons: return "Sons"
        case .daughters: return "Daughters"
        case .grandsons: return "Son's sons"
        case .granddaughters: return "Son's daughters"
        case .fullBrothers: return "Full brothers"
        case .fullSisters: return "Full sisters"
        case .paternalBrothers: return "Paternal half-brothers"
        case .paternalSisters: return "Paternal half-sisters"
        case .maternalSiblings: return "Maternal half-siblings"
        }
    }

    /// Heirs there can only ever be one of take a toggle; the rest take a stepper.
    var isSingular: Bool {
        switch self {
        case .husband, .father, .mother, .grandfather: return true
        default: return false
        }
    }

    /// The most the UI will let you enter. Four wives is the legal maximum; two grandmothers is the
    /// most that can inherit (the mother's mother and the father's mother).
    var maximum: Int {
        switch self {
        case .wives: return 4
        case .grandmothers: return 2
        default: return 20
        }
    }
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
    /// (ashab al-furud), then hand the residue to the nearest residuary (asabah), then correct with
    /// ‘awl or radd. Doing residue before blocking, or ‘awl before the residue, gives wrong answers
    /// on ordinary estates.
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

        // The mother shuts out every grandmother. The FATHER shuts out his own mother on the
        // majority view but never the mother's mother; this calculator does not ask which
        // grandmother survives, so it blocks only on the mother and flags the difference.
        var grandmothers = n(.grandmothers)
        if grandmothers > 0 && hasMother {
            blocked.append((.grandmothers, "blocked by the mother"))
            grandmothers = 0
        } else if grandmothers > 0 && hasFather {
            notes.append("A paternal grandmother is blocked by the father on the majority view, while a maternal grandmother is not. This calculator does not ask which grandmother survives, so check that share against your own case.")
        }

        let hasMaleDescendant = sons > 0 || grandsons > 0
        let hasDescendant = hasMaleDescendant || daughters > 0 || granddaughters > 0

        // Raw sibling head-count, BEFORE blocking: siblings cut the mother from 1/3 to 1/6 even when
        // they are themselves shut out by the father (hajb nuqsan - they diminish without inheriting).
        let siblingHeadCount = n(.fullBrothers) + n(.fullSisters)
            + n(.paternalBrothers) + n(.paternalSisters) + n(.maternalSiblings)

        // Full and paternal siblings fall to a male descendant or to the father. The grandfather is
        // the classical dispute (Abu Bakr shut them out, Zayd shared with them); this follows Abu
        // Bakr's view, which is what most published calculators use.
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
            if hasGrandfather && !hasFather && siblingHeadCount > 0 {
                notes.append("Siblings alongside a grandfather is a genuine difference among the Companions: Abu Bakr shut them out (followed here), while Zayd ibn Thabit shared the estate between them. If this estate has both, consult a scholar.")
            }
        }
        if maternalBlocked && maternalSiblings > 0 {
            blocked.append((.maternalSiblings, hasDescendant ? "blocked by a descendant" : "blocked by the father or grandfather"))
            maternalSiblings = 0
        }

        // A full brother shuts out the paternal siblings entirely.
        if fullBrothers > 0 {
            if paternalBrothers > 0 { blocked.append((.paternalBrothers, "blocked by the full brother")) }
            if paternalSisters > 0 { blocked.append((.paternalSisters, "blocked by the full sister's brother")) }
            paternalBrothers = 0; paternalSisters = 0
        }

        // ---- 2. The fixed shares (ashab al-furud) ----

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
            fard[.grandmothers] = (Fraction(1, 6), grandmothers == 1 ? "1/6 as grandmother" : "1/6 shared between the grandmothers")
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
        let fullSistersTakeResidueWithDaughters = fullSisters > 0 && fullBrothers == 0 && (daughters > 0 || granddaughters > 0)
        if fullSisters > 0 && fullBrothers == 0 && !fullSistersTakeResidueWithDaughters {
            fard[.fullSisters] = fullSisters == 1
                ? (Fraction(1, 2), "1/2 as the only full sister (4:176)")
                : (Fraction(2, 3), "2/3 shared among the full sisters (4:176)")
        }

        // Paternal half-sisters, behind whatever the full sisters took.
        let paternalSistersTakeResidueWithDaughters = paternalSisters > 0 && paternalBrothers == 0
            && fullSisters == 0 && (daughters > 0 || granddaughters > 0)
        if paternalSisters > 0 && paternalBrothers == 0 && !paternalSistersTakeResidueWithDaughters {
            if fullSisters >= 2 && !fullSistersTakeResidueWithDaughters {
                blocked.append((.paternalSisters, "the full sisters already take the full two-thirds"))
                paternalSisters = 0
            } else if fullSisters == 1 && !fullSistersTakeResidueWithDaughters {
                fard[.paternalSisters] = (Fraction(1, 6), "1/6, completing the full sister's half to two-thirds")
            } else if fullSisters == 0 {
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

        // ---- 3. Residue to the nearest residuary (‘asabah) ----

        var fardTotal = fard.values.reduce(Fraction.zero) { $0 + $1.share }
        var residue = Fraction.one - fardTotal
        var residueAwards: [FaraidHeir: (share: Fraction, basis: String)] = [:]

        if residue > .zero {
            // Strict order of nearness. The first tier that exists takes the whole residue.
            if sons > 0 {
                // "To the male, a portion equal to that of two females" (4:11).
                let parts = sons * 2 + daughters
                residueAwards[.sons] = (residue * Fraction(sons * 2, parts), daughters > 0 ? "residue, two shares to the daughter's one (4:11)" : "residue as the sons")
                if daughters > 0 {
                    residueAwards[.daughters] = (residue * Fraction(daughters, parts), "residue, one share to the son's two (4:11)")
                }
            } else if grandsons > 0 {
                let parts = grandsons * 2 + granddaughters
                residueAwards[.grandsons] = (residue * Fraction(grandsons * 2, parts), "residue as the son's sons")
                if granddaughters > 0 {
                    residueAwards[.granddaughters] = (residue * Fraction(granddaughters, parts), "residue, one share to the son's son's two")
                }
            } else if hasFather {
                residueAwards[.father] = (residue, hasDescendant ? "the residue on top of his sixth" : "the whole residue as father")
            } else if hasGrandfather {
                residueAwards[.grandfather] = (residue, hasDescendant ? "the residue on top of his sixth" : "the whole residue as grandfather")
            } else if fullBrothers > 0 {
                let parts = fullBrothers * 2 + fullSisters
                residueAwards[.fullBrothers] = (residue * Fraction(fullBrothers * 2, parts), fullSisters > 0 ? "residue, two shares to the sister's one (4:176)" : "residue as the full brothers")
                if fullSisters > 0 {
                    residueAwards[.fullSisters] = (residue * Fraction(fullSisters, parts), "residue, one share to the brother's two (4:176)")
                }
            } else if fullSistersTakeResidueWithDaughters {
                residueAwards[.fullSisters] = (residue, "residue as full sisters alongside a daughter (‘asabah ma‘a al-ghayr)")
            } else if paternalBrothers > 0 {
                let parts = paternalBrothers * 2 + paternalSisters
                residueAwards[.paternalBrothers] = (residue * Fraction(paternalBrothers * 2, parts), "residue as the paternal half-brothers")
                if paternalSisters > 0 {
                    residueAwards[.paternalSisters] = (residue * Fraction(paternalSisters, parts), "residue, one share to the brother's two")
                }
            } else if paternalSistersTakeResidueWithDaughters {
                residueAwards[.paternalSisters] = (residue, "residue as paternal half-sisters alongside a daughter")
            }
        }

        // ---- 4. ‘Awl and radd ----

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
                notes.append("No heir in this calculator can take the remaining share. In classical law it passes to the wider male relatives (uncles, nephews, cousins) and, failing them, to the public treasury.")
            }
        }

        // ---- 5. Merge, and split each group's share per person ----

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

        return Result(awards: awards, didAwl: didAwl, didRadd: didRadd,
                      unclaimed: unclaimed, blocked: blocked, notes: notes)
    }
}

// MARK: - The screen

/// A calculator for the Quranic shares: enter who survived, and it works out each heir's fraction of
/// the estate, applying the blocking rules, ‘awl and radd. The estate value is optional - without it
/// the answer is fractions and percentages, which is what the law actually specifies.
struct InheritanceCalculatorView: View {
    @ObservedObject private var settings = Settings.shared

    // Persisted so a half-entered family survives leaving the screen, matching the zakah calculator.
    @AppStorage("faraidEstate") private var estate = ""
    @AppStorage("faraidCounts") private var storedCounts = ""

    @FocusState private var estateFocused: Bool

    /// `heir.rawValue:count` pairs. One key rather than fifteen: the set of heirs is likely to grow,
    /// and a stored dictionary does not need a schema migration each time it does.
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

    private var estateValue: Double {
        let cleaned = estate.filter { $0.isNumber || $0 == "." || $0 == "," }
        let normalized = cleaned.contains(".")
            ? cleaned.replacingOccurrences(of: ",", with: "")
            : cleaned.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

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

    var body: some View {
        List {
            Group {
                estateSection
                heirSection("SPOUSE", heirs: [.husband, .wives])
                heirSection("PARENTS & GRANDPARENTS", heirs: [.father, .mother, .grandfather, .grandmothers])
                heirSection("CHILDREN & GRANDCHILDREN", heirs: [.sons, .daughters, .grandsons, .granddaughters],
                            footer: "Son's sons and son's daughters inherit only when there is no surviving son.")
                heirSection("SIBLINGS", heirs: [.fullBrothers, .fullSisters, .paternalBrothers, .paternalSisters, .maternalSiblings],
                            footer: "Maternal half-siblings are the children of the mother only. They inherit only when there is no child and no father.")
                resultSection
                if !result.blocked.isEmpty { blockedSection }
                if !result.notes.isEmpty { notesSection }
                scopeSection
            }
            .themedListRowBackground()
        }
        .navigationTitle("Inheritance Calculator")
        .applyConditionalListStyle()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { estateFocused = false }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    storedCounts = ""
                    estate = ""
                } label: {
                    Text("Reset")
                }
                .disabled(storedCounts.isEmpty && estate.isEmpty)
            }
        }
    }

    private var estateSection: some View {
        Section(header: Text("ESTATE (OPTIONAL)"),
                footer: Text("What is left AFTER the funeral costs, then the debts, then any bequest of up to a third. Leave it empty to see the shares as fractions only.")) {
            HStack(spacing: 10) {
                Image(systemName: "banknote")
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 24, alignment: .center)

                Text("Net estate")
                    .font(.subheadline)

                Spacer(minLength: 8)

                TextField("0", text: $estate)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline.monospacedDigit())
                    .frame(maxWidth: 120)
                    .focused($estateFocused)
            }
            .padding(.vertical, 2)
        }
    }

    private func heirSection(_ title: String, heirs: [FaraidHeir], footer: String? = nil) -> some View {
        Section(header: Text(title), footer: footer.map { Text($0) }) {
            ForEach(heirs, id: \.self) { heir in
                heirRow(heir)
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
            }
        }
        .padding(.vertical, 2)
    }

    private var resultSection: some View {
        Section(header: Text("SHARES")) {
            if result.isEmpty {
                Text("Add the surviving heirs above and their shares appear here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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

            if estateValue > 0 {
                HStack {
                    Text(award.count > 1 ? "Each of the \(award.count)" : "Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formattedAmount(award.each.doubleValue * estateValue))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = estateValue > 0
                    ? "\(award.heir.title): \(award.share.displayString) (\(formattedAmount(award.share.doubleValue * estateValue)))"
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
        Section {
            Text(Self.scopeNote)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    static let scopeNote = "The shares are fixed by Allah in Surah an-Nisa: 4:11, 4:12 and 4:176. يُوصِيكُمُ ٱللَّهُ فِىٓ أَوْلَـٰدِكُمْ \"Allah instructs you concerning your children\" (4:11). Settle the funeral costs first, then the debts, then any bequest of up to a third of what is left, and only then divide what remains.\n\nThis is a quick, rough guide for the simple case, and nothing more. It is not a fatwa and it is not the final answer. It covers the heirs who turn up in ordinary estates and it does NOT handle the wider male relatives (uncles, nephews, cousins), great-grandparents, a missing or unborn heir, an estate with no relative at all, or the places the schools genuinely differ, such as the grandfather inheriting alongside siblings.\n\nInheritance is the branch of knowledge the Prophet (peace be upon him) singled out for careful learning, and a real estate is somebody's wealth and somebody's grief at once. Take yours to a knowledgeable scholar of Ahl as-Sunnah wa al-Jamaʿah, and to a court where one is needed, before anything is divided on these numbers."
}

#Preview {
    AlIslamPreviewContainer {
        InheritanceCalculatorView()
    }
}
#endif
