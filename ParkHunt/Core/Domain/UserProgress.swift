import Foundation

struct UserProgress: Codable, Equatable, Sendable {
    var discoveries: [String: DiscoveryProgress]
    var lastUpdatedAt: Date?

    init(
        discoveries: [String: DiscoveryProgress] = [:],
        lastUpdatedAt: Date? = nil
    ) {
        self.discoveries = discoveries
        self.lastUpdatedAt = lastUpdatedAt
    }

    func progress(for discoveryID: String) -> DiscoveryProgress {
        discoveries[discoveryID] ?? DiscoveryProgress(discoveryID: discoveryID)
    }

    mutating func recordHintViewed(
        discoveryID: String,
        order: Int,
        at date: Date = Date()
    ) {
        var current = progress(for: discoveryID)
        current.highestHintOrderViewed = max(
            current.highestHintOrderViewed ?? order,
            order
        )
        current.lastViewedAt = date
        discoveries[discoveryID] = current
        lastUpdatedAt = date
    }

    mutating func recordRevealViewed(
        discoveryID: String,
        at date: Date = Date()
    ) {
        var current = progress(for: discoveryID)
        current.didRevealLocation = true
        current.lastViewedAt = date
        discoveries[discoveryID] = current
        lastUpdatedAt = date
    }

    mutating func recordFound(
        discoveryID: String,
        at date: Date = Date()
    ) {
        var current = progress(for: discoveryID)

        guard current.foundAt == nil else {
            return
        }

        current.foundAt = date
        current.lastViewedAt = date
        discoveries[discoveryID] = current
        lastUpdatedAt = date
    }

    var foundDiscoveryIDs: Set<String> {
        Set(
            discoveries.values
                .filter(\.isFound)
                .map(\.discoveryID)
        )
    }
}

struct DiscoveryProgress: Codable, Equatable, Sendable {
    let discoveryID: String
    var highestHintOrderViewed: Int?
    var didRevealLocation: Bool
    var foundAt: Date?
    var lastViewedAt: Date?

    init(
        discoveryID: String,
        highestHintOrderViewed: Int? = nil,
        didRevealLocation: Bool = false,
        foundAt: Date? = nil,
        lastViewedAt: Date? = nil
    ) {
        self.discoveryID = discoveryID
        self.highestHintOrderViewed = highestHintOrderViewed
        self.didRevealLocation = didRevealLocation
        self.foundAt = foundAt
        self.lastViewedAt = lastViewedAt
    }

    var isFound: Bool {
        foundAt != nil
    }
}
