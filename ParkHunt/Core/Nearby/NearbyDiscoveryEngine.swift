import Foundation

struct NearbyDiscoveryContext: Equatable, Sendable {
    let parkID: String?
    let landID: String?
    let areaID: String?
    let locationFix: LocationFix?

    init(
        parkID: String? = nil,
        landID: String? = nil,
        areaID: String? = nil,
        locationFix: LocationFix? = nil
    ) {
        self.parkID = parkID
        self.landID = landID
        self.areaID = areaID
        self.locationFix = locationFix
    }
}

enum NearbyDiscoveryScope: Equatable, Sendable {
    case all
    case park(String)
    case land(String)
    case area(String)
}

enum DiscoveryFoundFilter: Equatable, Sendable {
    case any
    case unfound
    case found
}

struct NearbyDiscoveryFilters: Equatable, Sendable {
    let scope: NearbyDiscoveryScope
    let difficulties: Set<Difficulty>
    let found: DiscoveryFoundFilter
    let maximumDistanceMeters: Double?

    init(
        scope: NearbyDiscoveryScope = .all,
        difficulties: Set<Difficulty> = [],
        found: DiscoveryFoundFilter = .any,
        maximumDistanceMeters: Double? = nil
    ) {
        self.scope = scope
        self.difficulties = difficulties
        self.found = found
        self.maximumDistanceMeters = maximumDistanceMeters
    }
}

struct NearbyDiscoveryResult: Equatable, Identifiable, Sendable {
    let discovery: Discovery
    let distanceMeters: Double?
    let isFound: Bool
    let matchesPark: Bool
    let matchesLand: Bool
    let matchesArea: Bool

    var id: String {
        discovery.id
    }
}

enum NearbyDiscoveryEngine {
    static func results(
        snapshot: ContentSnapshot,
        context: NearbyDiscoveryContext = NearbyDiscoveryContext(),
        filters: NearbyDiscoveryFilters = NearbyDiscoveryFilters(),
        progress: UserProgress = UserProgress()
    ) -> [NearbyDiscoveryResult] {
        snapshot.discoveries
            .compactMap { discovery in
                makeResult(
                    discovery: discovery,
                    context: context,
                    progress: progress
                )
            }
            .filter { result in
                matchesScope(result.discovery, scope: filters.scope)
            }
            .filter { result in
                filters.difficulties.isEmpty
                    || filters.difficulties.contains(result.discovery.difficulty)
            }
            .filter { result in
                switch filters.found {
                case .any:
                    true
                case .unfound:
                    !result.isFound
                case .found:
                    result.isFound
                }
            }
            .filter { result in
                guard let maximumDistanceMeters = filters.maximumDistanceMeters else {
                    return true
                }

                guard let distanceMeters = result.distanceMeters else {
                    return false
                }

                return distanceMeters <= maximumDistanceMeters
            }
            .sorted(by: compare)
    }

    private static func makeResult(
        discovery: Discovery,
        context: NearbyDiscoveryContext,
        progress: UserProgress
    ) -> NearbyDiscoveryResult {
        let distanceMeters: Double?

        if let fix = context.locationFix,
           let location = discovery.location {
            distanceMeters = NearbyContextResolver.distanceMeters(
                fromLatitude: fix.latitude,
                longitude: fix.longitude,
                toLatitude: location.latitude,
                longitude: location.longitude
            )
        } else {
            distanceMeters = nil
        }

        return NearbyDiscoveryResult(
            discovery: discovery,
            distanceMeters: distanceMeters,
            isFound: progress.progress(for: discovery.id).isFound,
            matchesPark: context.parkID == discovery.parkID,
            matchesLand: context.landID == discovery.landID,
            matchesArea: context.areaID != nil
                && context.areaID == discovery.areaID
        )
    }

    private static func matchesScope(
        _ discovery: Discovery,
        scope: NearbyDiscoveryScope
    ) -> Bool {
        switch scope {
        case .all:
            true
        case let .park(parkID):
            discovery.parkID == parkID
        case let .land(landID):
            discovery.landID == landID
        case let .area(areaID):
            discovery.areaID == areaID
        }
    }

    private static func compare(
        _ lhs: NearbyDiscoveryResult,
        _ rhs: NearbyDiscoveryResult
    ) -> Bool {
        if lhs.matchesArea != rhs.matchesArea {
            return lhs.matchesArea
        }

        if lhs.matchesLand != rhs.matchesLand {
            return lhs.matchesLand
        }

        if lhs.matchesPark != rhs.matchesPark {
            return lhs.matchesPark
        }

        if lhs.isFound != rhs.isFound {
            return !lhs.isFound
        }

        switch (lhs.distanceMeters, rhs.distanceMeters) {
        case let (left?, right?) where left != right:
            return left < right
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            break
        }

        if lhs.discovery.difficulty.rank != rhs.discovery.difficulty.rank {
            return lhs.discovery.difficulty.rank < rhs.discovery.difficulty.rank
        }

        let titleComparison = lhs.discovery.title
            .localizedCaseInsensitiveCompare(rhs.discovery.title)

        if titleComparison != .orderedSame {
            return titleComparison == .orderedAscending
        }

        return lhs.discovery.id < rhs.discovery.id
    }
}
