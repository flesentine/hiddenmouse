import Foundation

enum FieldTestIterationPriority: Int, Comparable, Sendable {
    case monitor = 0
    case medium = 1
    case high = 2
    case critical = 3

    static func < (
        lhs: FieldTestIterationPriority,
        rhs: FieldTestIterationPriority
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .monitor: "Monitor"
        case .medium: "Medium"
        case .high: "High"
        case .critical: "Critical"
        }
    }
}

struct FieldTestIterationItem: Equatable, Identifiable, Sendable {
    let discoveryID: String
    let discoveryTitle: String
    let priority: FieldTestIterationPriority
    let reportCount: Int
    let latestReportAt: Date
    let reasons: [String]
    let suggestedActions: [String]

    var id: String { discoveryID }
}

enum FieldTestIterationAnalyzer {
    static func makeQueue(
        records: [FieldTestFeedbackRecord]
    ) -> [FieldTestIterationItem] {
        Dictionary(grouping: records, by: \.discoveryID)
            .compactMap { _, grouped in
                makeItem(records: grouped)
            }
            .sorted {
                if $0.priority != $1.priority {
                    return $0.priority > $1.priority
                }

                if $0.reportCount != $1.reportCount {
                    return $0.reportCount > $1.reportCount
                }

                return $0.latestReportAt > $1.latestReportAt
            }
    }

    private static func makeItem(
        records: [FieldTestFeedbackRecord]
    ) -> FieldTestIterationItem? {
        guard let latest = records.max(by: { $0.timestamp < $1.timestamp }) else {
            return nil
        }

        var reasons: [String] = []
        var actions: [String] = []
        var priority: FieldTestIterationPriority = .monitor

        let wrongLocationCount = records.filter {
            $0.accuracy == .wrong || $0.issues.contains(.locationWrong)
        }.count
        let closeLocationCount = records.filter {
            $0.accuracy == .close
        }.count
        let confusingClueCount = records.filter {
            $0.clueQuality == .confusing || $0.issues.contains(.clueConfusing)
        }.count
        let revealWrongCount = records.filter {
            $0.issues.contains(.revealWrong)
        }.count
        let inaccessibleCount = records.filter {
            $0.issues.contains(.inaccessible)
        }.count
        let duplicateCount = records.filter {
            $0.issues.contains(.duplicate)
        }.count
        let nearbyPoorCount = records.filter {
            $0.nearbyUsefulness == .poor || $0.issues.contains(.nearbyRanking)
        }.count

        if wrongLocationCount > 0 || revealWrongCount > 0 || inaccessibleCount > 0 {
            priority = .critical
        } else if duplicateCount > 0 || confusingClueCount >= 2 || nearbyPoorCount >= 2 {
            priority = .high
        } else if confusingClueCount > 0 || nearbyPoorCount > 0 || closeLocationCount > 0 {
            priority = .medium
        }

        if wrongLocationCount > 0 {
            reasons.append("\(wrongLocationCount) wrong-location report\(wrongLocationCount == 1 ? "" : "s")")
            actions.append("Re-verify the physical target and Nearby coordinate in person.")
        }

        if closeLocationCount > 0 {
            reasons.append("\(closeLocationCount) location marked close")
            actions.append("Tighten the approximate coordinate or search radius if field verification supports it.")
        }

        if revealWrongCount > 0 {
            reasons.append("\(revealWrongCount) reveal mismatch report\(revealWrongCount == 1 ? "" : "s")")
            actions.append("Correct the reveal text/image before shipping.")
        }

        if inaccessibleCount > 0 {
            reasons.append("\(inaccessibleCount) accessibility/availability report\(inaccessibleCount == 1 ? "" : "s")")
            actions.append("Confirm the target is publicly reachable and stable enough for a hunt.")
        }

        if duplicateCount > 0 {
            reasons.append("\(duplicateCount) possible duplicate report\(duplicateCount == 1 ? "" : "s")")
            actions.append("Compare this discovery against the catalog and merge or retire duplicates.")
        }

        if confusingClueCount > 0 {
            reasons.append("\(confusingClueCount) confusing-clue report\(confusingClueCount == 1 ? "" : "s")")
            actions.append("Rewrite clue wording and recheck spoiler progression in the park.")
        }

        if nearbyPoorCount > 0 {
            reasons.append("\(nearbyPoorCount) poor-Nearby report\(nearbyPoorCount == 1 ? "" : "s")")
            actions.append("Review Nearby ordering, coordinate quality, and distance assumptions.")
        }

        if reasons.isEmpty {
            reasons.append("No blocking field issues reported.")
            actions.append("Keep the hunt as-is unless later field reports disagree.")
        }

        return FieldTestIterationItem(
            discoveryID: latest.discoveryID,
            discoveryTitle: latest.discoveryTitle,
            priority: priority,
            reportCount: records.count,
            latestReportAt: latest.timestamp,
            reasons: reasons,
            suggestedActions: actions.reduce(into: []) { result, action in
                if !result.contains(action) {
                    result.append(action)
                }
            }
        )
    }
}
