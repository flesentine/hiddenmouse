import Foundation

enum TodayRouteLength: Int, CaseIterable, Identifiable, Sendable {
    case short = 3
    case medium = 5
    case long = 8

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .short: "3 hunts"
        case .medium: "5 hunts"
        case .long: "8 hunts"
        }
    }
}

struct TodayRouteItem: Equatable, Identifiable, Sendable {
    let discovery: Discovery
    let landName: String
    let isFound: Bool
    let sequence: Int

    var id: String { discovery.id }
}

struct TodayRoute: Equatable, Sendable {
    let items: [TodayRouteItem]
    let requestedCount: Int
    let focusLandName: String?

    var isComplete: Bool {
        !items.isEmpty && items.allSatisfy(\.isFound)
    }
}

enum TodayRouteBuilder {
    static func build(
        snapshot: ContentSnapshot,
        progress: UserProgress,
        length: TodayRouteLength,
        parkID: String? = nil
    ) -> TodayRoute {
        let available = snapshot.discoveries.filter {
            parkID == nil || $0.parkID == parkID
        }
        let requested = length.rawValue

        let unfinished = available.filter {
            !progress.progress(for: $0.id).isFound
        }

        let source = unfinished.isEmpty ? available : unfinished
        let grouped = Dictionary(grouping: source, by: \.landID)

        let preferredLandID = snapshot.lands
            .compactMap { land -> (String, Int)? in
                guard let discoveries = grouped[land.id], !discoveries.isEmpty else {
                    return nil
                }
                return (land.id, discoveries.count)
            }
            .sorted {
                if $0.1 == $1.1 {
                    let lhsOrder = snapshot.land(id: $0.0)?.sortOrder ?? .max
                    let rhsOrder = snapshot.land(id: $1.0)?.sortOrder ?? .max
                    return lhsOrder < rhsOrder
                }
                return $0.1 > $1.1
            }
            .first?
            .0

        var selected: [Discovery] = []

        if let preferredLandID {
            let sameLand = (grouped[preferredLandID] ?? [])
                .sorted(by: compareDiscoveries)
            selected.append(contentsOf: sameLand.prefix(requested))
        }

        if selected.count < requested {
            let selectedIDs = Set(selected.map(\.id))
            let remainder = source
                .filter { !selectedIDs.contains($0.id) }
                .sorted { lhs, rhs in
                    let lhsOrder = snapshot.land(id: lhs.landID)?.sortOrder ?? .max
                    let rhsOrder = snapshot.land(id: rhs.landID)?.sortOrder ?? .max
                    if lhsOrder != rhsOrder {
                        return lhsOrder < rhsOrder
                    }
                    return compareDiscoveries(lhs, rhs)
                }
            selected.append(
                contentsOf: remainder.prefix(requested - selected.count)
            )
        }

        let items = selected.enumerated().map { index, discovery in
            TodayRouteItem(
                discovery: discovery,
                landName: snapshot.land(id: discovery.landID)?.name
                    ?? discovery.landID,
                isFound: progress.progress(for: discovery.id).isFound,
                sequence: index + 1
            )
        }

        let focusLandName: String?
        if let firstLand = items.first?.discovery.landID,
           items.allSatisfy({ $0.discovery.landID == firstLand }) {
            focusLandName = snapshot.land(id: firstLand)?.name
        } else {
            focusLandName = nil
        }

        return TodayRoute(
            items: items,
            requestedCount: requested,
            focusLandName: focusLandName
        )
    }

    private static func compareDiscoveries(
        _ lhs: Discovery,
        _ rhs: Discovery
    ) -> Bool {
        if lhs.difficulty.rank != rhs.difficulty.rank {
            return lhs.difficulty.rank < rhs.difficulty.rank
        }

        let titleComparison = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        if titleComparison != .orderedSame {
            return titleComparison == .orderedAscending
        }

        return lhs.id < rhs.id
    }
}
