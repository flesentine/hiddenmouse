import Foundation

struct ProgressCount: Equatable, Sendable {
    let total: Int
    let started: Int
    let found: Int

    var remaining: Int {
        max(total - found, 0)
    }

    var completionFraction: Double {
        guard total > 0 else {
            return 0
        }

        return Double(found) / Double(total)
    }
}

struct LandProgressSummary: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let count: ProgressCount
}

struct CategoryProgressSummary: Equatable, Identifiable, Sendable {
    let category: DiscoveryCategory
    let count: ProgressCount

    var id: String {
        category.rawValue
    }
}

struct RecentProgressDiscovery: Equatable, Sendable {
    let discoveryID: String
    let title: String
    let landName: String?
    let areaName: String?
    let lastViewedAt: Date?
    let foundAt: Date?
}

struct ProgressSummary: Equatable, Sendable {
    let overall: ProgressCount
    let lands: [LandProgressSummary]
    let categories: [CategoryProgressSummary]
    let recentActivity: RecentProgressDiscovery?
    let recentFound: RecentProgressDiscovery?
    let lastUpdatedAt: Date?

    static func make(
        snapshot: ContentSnapshot,
        progress: UserProgress
    ) -> ProgressSummary {
        let discoveries = snapshot.discoveries

        let overall = count(
            discoveries: discoveries,
            progress: progress
        )

        let lands = snapshot.lands.compactMap { land in
            let landDiscoveries = discoveries.filter {
                $0.landID == land.id
            }

            guard !landDiscoveries.isEmpty else {
                return nil
            }

            return LandProgressSummary(
                id: land.id,
                name: land.name,
                count: count(
                    discoveries: landDiscoveries,
                    progress: progress
                )
            )
        }

        let categories = DiscoveryCategory.allCases.compactMap { category in
            let categoryDiscoveries = discoveries.filter {
                $0.category == category
            }

            guard !categoryDiscoveries.isEmpty else {
                return nil
            }

            return CategoryProgressSummary(
                category: category,
                count: count(
                    discoveries: categoryDiscoveries,
                    progress: progress
                )
            )
        }

        let recentActivity = discoveries.compactMap { discovery in
            recentItem(
                discovery: discovery,
                snapshot: snapshot,
                progress: progress.progress(for: discovery.id)
            )
        }
        .filter { $0.lastViewedAt != nil }
        .max {
            compareRecent(
                lhs: $0.lastViewedAt,
                lhsID: $0.discoveryID,
                rhs: $1.lastViewedAt,
                rhsID: $1.discoveryID
            )
        }

        let recentFound = discoveries.compactMap { discovery in
            recentItem(
                discovery: discovery,
                snapshot: snapshot,
                progress: progress.progress(for: discovery.id)
            )
        }
        .filter { $0.foundAt != nil }
        .max {
            compareRecent(
                lhs: $0.foundAt,
                lhsID: $0.discoveryID,
                rhs: $1.foundAt,
                rhsID: $1.discoveryID
            )
        }

        return ProgressSummary(
            overall: overall,
            lands: lands,
            categories: categories,
            recentActivity: recentActivity,
            recentFound: recentFound,
            lastUpdatedAt: progress.lastUpdatedAt
        )
    }

    private static func count(
        discoveries: [Discovery],
        progress: UserProgress
    ) -> ProgressCount {
        let states = discoveries.map {
            progress.progress(for: $0.id)
        }

        return ProgressCount(
            total: discoveries.count,
            started: states.filter(isStarted).count,
            found: states.filter(\.isFound).count
        )
    }

    private static func isStarted(
        _ progress: DiscoveryProgress
    ) -> Bool {
        progress.lastViewedAt != nil
            || progress.highestHintOrderViewed != nil
            || progress.didRevealLocation
            || progress.isFound
    }

    private static func recentItem(
        discovery: Discovery,
        snapshot: ContentSnapshot,
        progress: DiscoveryProgress
    ) -> RecentProgressDiscovery {
        RecentProgressDiscovery(
            discoveryID: discovery.id,
            title: discovery.title,
            landName: snapshot.land(id: discovery.landID)?.name,
            areaName: discovery.areaID
                .flatMap { snapshot.area(id: $0) }?
                .name,
            lastViewedAt: progress.lastViewedAt,
            foundAt: progress.foundAt
        )
    }

    private static func compareRecent(
        lhs: Date?,
        lhsID: String,
        rhs: Date?,
        rhsID: String
    ) -> Bool {
        switch (lhs, rhs) {
        case let (left?, right?) where left != right:
            return left < right
        case (_?, nil):
            return false
        case (nil, _?):
            return true
        default:
            return lhsID < rhsID
        }
    }
}
