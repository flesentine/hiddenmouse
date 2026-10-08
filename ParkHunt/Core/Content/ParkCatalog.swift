import Foundation

struct ParkOption: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let sortOrder: Int
}

enum ParkCatalog {
    static func name(for parkID: String) -> String {
        switch parkID {
        case "disneyland":
            "Disneyland Park"
        case "disney-california-adventure":
            "Disney California Adventure"
        default:
            parkID
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }
    }

    static func sortOrder(for parkID: String) -> Int {
        switch parkID {
        case "disneyland": 1
        case "disney-california-adventure": 2
        default: 100
        }
    }

    static func options(in snapshot: ContentSnapshot) -> [ParkOption] {
        let ids = Set(snapshot.lands.map(\.parkID))
            .union(snapshot.discoveries.map(\.parkID))

        return ids.map {
            ParkOption(
                id: $0,
                name: name(for: $0),
                sortOrder: sortOrder(for: $0)
            )
        }
        .sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
            }
            return $0.sortOrder < $1.sortOrder
        }
    }
}
