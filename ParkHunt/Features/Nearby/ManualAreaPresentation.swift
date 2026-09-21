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
        let grouped = Dictionary(grouping: snapshot.lands, by: \.parkID)

        return grouped.map { parkID, lands in
            let discoveryCount = lands.reduce(into: 0) { total, land in
                total += snapshot.discoveries(inLand: land.id).count
            }

            return ManualParkOption(
                id: parkID,
                name: displayName(forParkID: parkID),
                landCount: lands.count,
                discoveryCount: discoveryCount
            )
        }
        .sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
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

    static func displayName(forParkID parkID: String) -> String {
        switch parkID {
        case "disneyland":
            return "Disneyland"
        default:
            return parkID
                .replacingOccurrences(of: "-", with: " ")
                .split(separator: " ")
                .map { $0.capitalized }
                .joined(separator: " ")
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
