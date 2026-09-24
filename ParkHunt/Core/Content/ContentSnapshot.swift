import Foundation

struct ContentSnapshot: Sendable {
    let catalog: ContentCatalog

    private let landByID: [String: Land]
    private let areaByID: [String: AttractionArea]
    private let discoveryByID: [String: Discovery]

    private let sortedLands: [Land]
    private let sortedAreas: [AttractionArea]
    private let availableDiscoveries: [Discovery]

    private let areasByLandID: [String: [AttractionArea]]
    private let availableDiscoveriesByLandID: [String: [Discovery]]
    private let allDiscoveriesByLandID: [String: [Discovery]]
    private let availableDiscoveriesByAreaID: [String: [Discovery]]
    private let allDiscoveriesByAreaID: [String: [Discovery]]
    private let availableDiscoveriesByCategory: [DiscoveryCategory: [Discovery]]
    private let allDiscoveriesByCategory: [DiscoveryCategory: [Discovery]]

    init(catalog: ContentCatalog) {
        self.catalog = catalog

        let sortedLands = catalog.lands.sorted(by: Self.compareLands)
        let sortedAreas = catalog.areas.sorted(by: Self.compareAreas)
        let availableDiscoveries = catalog.discoveries.filter(\.isAvailableForHunt)

        self.landByID = Self.index(catalog.lands, by: \.id)
        self.areaByID = Self.index(catalog.areas, by: \.id)
        self.discoveryByID = Self.index(catalog.discoveries, by: \.id)

        self.sortedLands = sortedLands
        self.sortedAreas = sortedAreas
        self.availableDiscoveries = availableDiscoveries

        self.areasByLandID = Dictionary(
            grouping: sortedAreas,
            by: \.landID
        )
        self.availableDiscoveriesByLandID = Dictionary(
            grouping: availableDiscoveries,
            by: \.landID
        )
        self.allDiscoveriesByLandID = Dictionary(
            grouping: catalog.discoveries,
            by: \.landID
        )
        self.availableDiscoveriesByAreaID = Dictionary(
            grouping: availableDiscoveries.compactMap { discovery in
                discovery.areaID.map { ($0, discovery) }
            },
            by: \.0
        )
        .mapValues { values in
            values.map(\.1)
        }
        self.allDiscoveriesByAreaID = Dictionary(
            grouping: catalog.discoveries.compactMap { discovery in
                discovery.areaID.map { ($0, discovery) }
            },
            by: \.0
        )
        .mapValues { values in
            values.map(\.1)
        }
        self.availableDiscoveriesByCategory = Dictionary(
            grouping: availableDiscoveries,
            by: \.category
        )
        self.allDiscoveriesByCategory = Dictionary(
            grouping: catalog.discoveries,
            by: \.category
        )
    }

    var lands: [Land] {
        sortedLands
    }

    var areas: [AttractionArea] {
        sortedAreas
    }

    var discoveries: [Discovery] {
        availableDiscoveries
    }

    func land(id: String) -> Land? {
        landByID[id]
    }

    func area(id: String) -> AttractionArea? {
        areaByID[id]
    }

    func discovery(
        id: String,
        includeUnavailable: Bool = false
    ) -> Discovery? {
        guard let discovery = discoveryByID[id] else {
            return nil
        }

        if includeUnavailable || discovery.isAvailableForHunt {
            return discovery
        }

        return nil
    }

    func areas(inLand landID: String) -> [AttractionArea] {
        areasByLandID[landID] ?? []
    }

    func discoveries(
        inLand landID: String,
        includeUnavailable: Bool = false
    ) -> [Discovery] {
        if includeUnavailable {
            return allDiscoveriesByLandID[landID] ?? []
        }

        return availableDiscoveriesByLandID[landID] ?? []
    }

    func discoveries(
        inArea areaID: String,
        includeUnavailable: Bool = false
    ) -> [Discovery] {
        if includeUnavailable {
            return allDiscoveriesByAreaID[areaID] ?? []
        }

        return availableDiscoveriesByAreaID[areaID] ?? []
    }

    func discoveries(
        category: DiscoveryCategory,
        includeUnavailable: Bool = false
    ) -> [Discovery] {
        if includeUnavailable {
            return allDiscoveriesByCategory[category] ?? []
        }

        return availableDiscoveriesByCategory[category] ?? []
    }

    private static func compareLands(
        _ lhs: Land,
        _ rhs: Land
    ) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                == .orderedAscending
        }

        return lhs.sortOrder < rhs.sortOrder
    }

    private static func compareAreas(
        _ lhs: AttractionArea,
        _ rhs: AttractionArea
    ) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                == .orderedAscending
        }

        return lhs.sortOrder < rhs.sortOrder
    }

    private static func index<T>(
        _ values: [T],
        by identifier: (T) -> String
    ) -> [String: T] {
        var result: [String: T] = [:]
        for value in values where result[identifier(value)] == nil {
            result[identifier(value)] = value
        }
        return result
    }
}

extension Discovery {
    var isAvailableForHunt: Bool {
        switch verificationStatus {
        case .removed, .temporarilyUnavailable:
            false
        case .verified, .needsRecheck, .unverified:
            true
        }
    }
}
