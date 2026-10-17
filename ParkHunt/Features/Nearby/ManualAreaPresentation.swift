import Foundation

struct ManualParkOption: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let landCount: Int
    let discoveryCount: Int
}

struct ManualLandOption: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let discoveryCount: Int
}

enum ManualAreaPresentation {
    static func parks(from snapshot: ContentSnapshot) -> [ManualParkOption] {
        ParkCatalog.options(in: snapshot).map { park in
            let lands = snapshot.lands(inPark: park.id)
            let discoveryCount = snapshot.discoveries(
                inPark: park.id
            ).count

            return ManualParkOption(
                id: park.id,
                name: park.name,
                landCount: lands.count,
                discoveryCount: discoveryCount
            )
        }
    }

    static func lands(
        inPark parkID: String,
        snapshot: ContentSnapshot
    ) -> [ManualLandOption] {
        snapshot.lands
            .filter { $0.parkID == parkID }
            .map { land in
                ManualLandOption(
                    id: land.id,
                    name: land.name,
                    discoveryCount: snapshot.discoveries(inLand: land.id).count
                )
            }
    }

    static func discoveryCountText(_ count: Int) -> String {
        switch count {
        case 0:
            "No hunts ready"
        case 1:
            "1 hunt ready"
        default:
            "\(count) hunts ready"
        }
    }
}
