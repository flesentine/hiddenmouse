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
