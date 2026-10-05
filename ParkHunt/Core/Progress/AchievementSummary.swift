import Foundation

enum AchievementKind: String, CaseIterable, Identifiable, Sendable {
    case firstFind
    case fiveFinds
    case tenFinds
    case twentyFiveFinds
    case fiftyFinds
    case landComplete
    case categoryExplorer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstFind: "First Find"
        case .fiveFinds: "Getting Warm"
        case .tenFinds: "Sharp Eyes"
        case .twentyFiveFinds: "Detail Hunter"
        case .fiftyFinds: "Park Sleuth"
        case .landComplete: "Land Complete"
        case .categoryExplorer: "Curious Explorer"
        }
    }

    var systemImage: String {
        switch self {
        case .firstFind: "sparkles"
        case .fiveFinds: "eye.fill"
        case .tenFinds: "binoculars.fill"
        case .twentyFiveFinds: "medal.fill"
        case .fiftyFinds: "trophy.fill"
        case .landComplete: "map.fill"
        case .categoryExplorer: "square.grid.2x2.fill"
        }
    }
}

struct AchievementProgress: Equatable, Identifiable, Sendable {
    let kind: AchievementKind
    let subtitle: String
    let current: Int
    let target: Int
    let isUnlocked: Bool

    var id: String { kind.rawValue }

    var fraction: Double {
        guard target > 0 else { return isUnlocked ? 1 : 0 }
        return min(max(Double(current) / Double(target), 0), 1)
    }
}

struct AchievementSummary: Equatable, Sendable {
    let achievements: [AchievementProgress]
    let unlockedCount: Int

    static func make(
        snapshot: ContentSnapshot,
        progress: UserProgress
    ) -> AchievementSummary {
        let found = snapshot.discoveries.filter {
            progress.progress(for: $0.id).isFound
        }
        let foundCount = found.count

        let completedLands = snapshot.lands.filter { land in
            let discoveries = snapshot.discoveries(inLand: land.id)
            return !discoveries.isEmpty
                && discoveries.allSatisfy {
                    progress.progress(for: $0.id).isFound
                }
        }

        let foundCategories = Set(found.map(\.category))

        let achievements = [
            milestone(
                kind: .firstFind,
                current: foundCount,
                target: 1,
                subtitle: "Find your first hidden detail."
            ),
            milestone(
                kind: .fiveFinds,
                current: foundCount,
                target: 5,
                subtitle: "Find 5 discoveries."
            ),
            milestone(
                kind: .tenFinds,
                current: foundCount,
                target: 10,
                subtitle: "Find 10 discoveries."
            ),
            milestone(
                kind: .twentyFiveFinds,
                current: foundCount,
                target: 25,
                subtitle: "Find 25 discoveries."
            ),
            milestone(
                kind: .fiftyFinds,
                current: foundCount,
                target: 50,
                subtitle: "Find 50 discoveries."
            ),
            AchievementProgress(
                kind: .landComplete,
                subtitle: completedLands.isEmpty
                    ? "Complete every hunt in one land."
                    : "Completed \(completedLands.count) land\(completedLands.count == 1 ? "" : "s").",
                current: completedLands.count,
                target: 1,
                isUnlocked: !completedLands.isEmpty
            ),
            AchievementProgress(
                kind: .categoryExplorer,
                subtitle: "Find discoveries from 3 different categories.",
                current: foundCategories.count,
                target: 3,
                isUnlocked: foundCategories.count >= 3
            )
        ]

        return AchievementSummary(
            achievements: achievements,
            unlockedCount: achievements.filter(\.isUnlocked).count
        )
    }

    private static func milestone(
        kind: AchievementKind,
        current: Int,
        target: Int,
        subtitle: String
    ) -> AchievementProgress {
        AchievementProgress(
            kind: kind,
            subtitle: subtitle,
            current: min(current, target),
            target: target,
            isUnlocked: current >= target
        )
    }
}
