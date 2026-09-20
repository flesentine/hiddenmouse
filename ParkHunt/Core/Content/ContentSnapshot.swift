import Foundation

struct ContentSnapshot: Sendable {
    let catalog: ContentCatalog

    private let landByID: [String: Land]
    private let areaByID: [String: AttractionArea]
    private let discoveryByID: [String: Discovery]

    init(catalog: ContentCatalog) {
        self.catalog = catalog
        self.landByID = Dictionary(
            uniqueKeysWithValues: catalog.lands.map { ($0.id, $0) }
        )
        self.areaByID = Dictionary(
            uniqueKeysWithValues: catalog.areas.map { ($0.id, $0) }
        )
        self.discoveryByID = Dictionary(
            uniqueKeysWithValues: catalog.discoveries.map { ($0.id, $0) }
        )
    }

    var lands: [Land] {
        catalog.lands.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    var areas: [AttractionArea] {
        catalog.areas.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    var discoveries: [Discovery] {
        available(catalog.discoveries)
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
        areas.filter { $0.landID == landID }
    }

    func discoveries(
        inLand landID: String,
        includeUnavailable: Bool = false
    ) -> [Discovery] {
        filtered(
            catalog.discoveries.filter { $0.landID == landID },
            includeUnavailable: includeUnavailable
        )
    }

    func discoveries(
        inArea areaID: String,
        includeUnavailable: Bool = false
    ) -> [Discovery] {
        filtered(
            catalog.discoveries.filter { $0.areaID == areaID },
            includeUnavailable: includeUnavailable
        )
    }

    func discoveries(
        category: DiscoveryCategory,
        includeUnavailable: Bool = false
    ) -> [Discovery] {
        filtered(
            catalog.discoveries.filter { $0.category == category },
            includeUnavailable: includeUnavailable
        )
    }

    private func available(_ discoveries: [Discovery]) -> [Discovery] {
        discoveries.filter(\.isAvailableForHunt)
    }

    private func filtered(
        _ discoveries: [Discovery],
        includeUnavailable: Bool
    ) -> [Discovery] {
        includeUnavailable ? discoveries : available(discoveries)
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
