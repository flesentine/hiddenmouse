import Foundation

enum CollectionProgressState: String, CaseIterable, Identifiable, Sendable {
    case found
    case started
    case unstarted

    var id: String {
        rawValue
    }
}

enum CollectionStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case found
    case unfound
    case started

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .all:
            "All"
        case .found:
            "Found"
        case .unfound:
            "Unfound"
        case .started:
            "Started"
        }
    }
}

struct CollectionFilters: Equatable, Sendable {
    var status: CollectionStatusFilter
    var landID: String?
    var category: DiscoveryCategory?

    init(
        status: CollectionStatusFilter = .all,
        landID: String? = nil,
        category: DiscoveryCategory? = nil
    ) {
        self.status = status
        self.landID = landID
        self.category = category
    }

    var isDefault: Bool {
        status == .all
            && landID == nil
            && category == nil
    }
}

struct CollectionItem: Equatable, Identifiable, Sendable {
    let discovery: Discovery
    let landName: String
    let areaName: String?
    let progressState: CollectionProgressState
    let foundAt: Date?
    let lastViewedAt: Date?

    var id: String {
        discovery.id
    }
}

struct CollectionSnapshot: Equatable, Sendable {
    let items: [CollectionItem]
    let lands: [Land]
    let categories: [DiscoveryCategory]

    static func make(
        snapshot: ContentSnapshot,
        progress: UserProgress,
        filters: CollectionFilters = CollectionFilters()
    ) -> CollectionSnapshot {
        let availableDiscoveries = snapshot.discoveries

        let filteredItems = availableDiscoveries
            .filter { discovery in
                matches(
                    discovery: discovery,
                    progress: progress.progress(for: discovery.id),
                    filters: filters
                )
            }
            .map { discovery in
                let discoveryProgress = progress.progress(for: discovery.id)

                return CollectionItem(
                    discovery: discovery,
                    landName: snapshot.land(id: discovery.landID)?.name
                        ?? discovery.landID,
                    areaName: discovery.areaID
                        .flatMap { snapshot.area(id: $0) }?
                        .name,
                    progressState: progressState(discoveryProgress),
                    foundAt: discoveryProgress.foundAt,
                    lastViewedAt: discoveryProgress.lastViewedAt
                )
            }
            .sorted { lhs, rhs in
                compare(
                    lhs,
                    rhs,
                    snapshot: snapshot
                )
            }

        let lands = snapshot.lands.filter { land in
            availableDiscoveries.contains {
                $0.landID == land.id
            }
        }

        let categories = DiscoveryCategory.allCases.filter { category in
            availableDiscoveries.contains {
                $0.category == category
            }
        }

        return CollectionSnapshot(
            items: filteredItems,
            lands: lands,
            categories: categories
        )
    }

    private static func matches(
        discovery: Discovery,
        progress: DiscoveryProgress,
        filters: CollectionFilters
    ) -> Bool {
        if let landID = filters.landID,
           discovery.landID != landID {
            return false
        }

        if let category = filters.category,
           discovery.category != category {
            return false
        }

        let state = progressState(progress)

        switch filters.status {
        case .all:
            return true
        case .found:
            return state == .found
        case .unfound:
            return state != .found
        case .started:
            return state == .started
        }
    }

    private static func progressState(
        _ progress: DiscoveryProgress
    ) -> CollectionProgressState {
        if progress.isFound {
            return .found
        }

        if progress.lastViewedAt != nil
            || progress.highestHintOrderViewed != nil
            || progress.didRevealLocation {
            return .started
        }

        return .unstarted
    }

    private static func compare(
        _ lhs: CollectionItem,
        _ rhs: CollectionItem,
        snapshot: ContentSnapshot
    ) -> Bool {
        let lhsLandOrder = snapshot.land(
            id: lhs.discovery.landID
        )?.sortOrder ?? .max
        let rhsLandOrder = snapshot.land(
            id: rhs.discovery.landID
        )?.sortOrder ?? .max

        if lhsLandOrder != rhsLandOrder {
            return lhsLandOrder < rhsLandOrder
        }

        let lhsAreaOrder = lhs.discovery.areaID
            .flatMap { snapshot.area(id: $0)?.sortOrder }
            ?? .max
        let rhsAreaOrder = rhs.discovery.areaID
            .flatMap { snapshot.area(id: $0)?.sortOrder }
            ?? .max

        if lhsAreaOrder != rhsAreaOrder {
            return lhsAreaOrder < rhsAreaOrder
        }

        let titleComparison = lhs.discovery.title
            .localizedCaseInsensitiveCompare(rhs.discovery.title)

        if titleComparison != .orderedSame {
            return titleComparison == .orderedAscending
        }

        return lhs.discovery.id < rhs.discovery.id
    }
}
