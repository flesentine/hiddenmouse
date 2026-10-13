import Foundation

struct ParkOption: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let sortOrder: Int
}

enum ParkCatalog {
    static func name(for parkID: String) -> String {
        parkID
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { token in
                let value = String(token)
                if value.count <= 3,
                   value == value.lowercased() {
                    return value.uppercased()
                }
                return value.capitalized
            }
            .joined(separator: " ")
    }

    static func options(in snapshot: ContentSnapshot) -> [ParkOption] {
        let ids = Set(snapshot.lands.map(\.parkID))
            .union(snapshot.discoveries.map(\.parkID))

        return ids.map { parkID in
            let landOrder = snapshot.lands(inPark: parkID)
                .map(\.sortOrder)
                .min() ?? Int.max

            return ParkOption(
                id: parkID,
                name: name(for: parkID),
                sortOrder: landOrder
            )
        }
        .sorted {
            if $0.sortOrder == $1.sortOrder {
                let nameComparison = $0.name
                    .localizedCaseInsensitiveCompare($1.name)
                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }
                return $0.id < $1.id
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    static func defaultParkID(
        in snapshot: ContentSnapshot
    ) -> String? {
        options(in: snapshot).first?.id
    }
}
