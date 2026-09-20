import Foundation

struct HomePresentation: Equatable, Sendable {
    let landName: String
    let discoveryCount: Int
    let primaryDiscoveryID: String?
    let primaryDiscoveryTitle: String?
    let primaryDifficulty: Difficulty?

    static func make(from snapshot: ContentSnapshot) -> Self {
        let firstLand = snapshot.lands.first
        let discoveries: [Discovery]

        if let firstLand {
            discoveries = snapshot.discoveries(inLand: firstLand.id)
        } else {
            discoveries = snapshot.discoveries
        }

        let firstDiscovery = discoveries.first

        return HomePresentation(
            landName: firstLand?.name ?? "Disneyland",
            discoveryCount: discoveries.count,
            primaryDiscoveryID: firstDiscovery?.id,
            primaryDiscoveryTitle: firstDiscovery?.title,
            primaryDifficulty: firstDiscovery?.difficulty
        )
    }

    var discoveryCountText: String {
        switch discoveryCount {
        case 0:
            "No discoveries ready"
        case 1:
            "1 discovery ready"
        default:
            "\(discoveryCount) discoveries ready"
        }
    }
}

extension Difficulty {
    var displayName: String {
        rawValue.capitalized
    }
}
