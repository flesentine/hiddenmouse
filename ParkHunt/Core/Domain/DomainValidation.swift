import Foundation

enum DomainValidator {
    static func validate(_ discovery: Discovery) -> [DomainValidationIssue] {
        var issues: [DomainValidationIssue] = []

        if discovery.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyIdentifier(entity: "Discovery"))
        }

        if discovery.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyTitle(discoveryID: discovery.id))
        }

        if discovery.parkID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyReference(discoveryID: discovery.id, field: "parkID"))
        }

        if discovery.landID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyReference(discoveryID: discovery.id, field: "landID"))
        }

        if discovery.hints.isEmpty {
            issues.append(.missingHints(discoveryID: discovery.id))
        }

        let hintIDs = discovery.hints.map(\.id)
        let uniqueHintIDs = Set(hintIDs)
        if hintIDs.count != uniqueHintIDs.count {
            issues.append(.duplicateHintIdentifier(discoveryID: discovery.id))
        }

        let hintOrders = discovery.hints.map(\.order)
        let uniqueHintOrders = Set(hintOrders)
        for duplicateOrder in uniqueHintOrders where hintOrders.filter({ $0 == duplicateOrder }).count > 1 {
            issues.append(.duplicateHintOrder(discoveryID: discovery.id, order: duplicateOrder))
        }

        for hint in discovery.hints {
            if hint.order <= 0 {
                issues.append(.nonPositiveHintOrder(discoveryID: discovery.id, order: hint.order))
            }

            if hint.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.emptyHintText(discoveryID: discovery.id, hintID: hint.id))
            }
        }

        if discovery.revealDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyRevealDescription(discoveryID: discovery.id))
        }

        if let location = discovery.location {
            if !(-90.0 ... 90.0).contains(location.latitude) {
                issues.append(.invalidLatitude(discoveryID: discovery.id, value: location.latitude))
            }

            if !(-180.0 ... 180.0).contains(location.longitude) {
                issues.append(.invalidLongitude(discoveryID: discovery.id, value: location.longitude))
            }

            if location.radiusMeters <= 0 {
                issues.append(.invalidRadius(discoveryID: discovery.id, value: location.radiusMeters))
            }
        }

        return issues
    }

    static func validate(_ land: Land) -> [DomainValidationIssue] {
        var issues: [DomainValidationIssue] = []

        if land.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyIdentifier(entity: "Land"))
        }

        if land.parkID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyReference(discoveryID: land.id, field: "parkID"))
        }

        if land.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyName(entity: "Land", id: land.id))
        }

        return issues
    }

    static func validate(_ area: AttractionArea) -> [DomainValidationIssue] {
        var issues: [DomainValidationIssue] = []

        if area.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyIdentifier(entity: "AttractionArea"))
        }

        if area.landID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyReference(discoveryID: area.id, field: "landID"))
        }

        if area.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyName(entity: "AttractionArea", id: area.id))
        }

        return issues
    }
}

enum DomainValidationIssue: Equatable, Sendable {
    case emptyIdentifier(entity: String)
    case emptyTitle(discoveryID: String)
    case emptyName(entity: String, id: String)
    case emptyReference(discoveryID: String, field: String)
    case missingHints(discoveryID: String)
    case duplicateHintIdentifier(discoveryID: String)
    case duplicateHintOrder(discoveryID: String, order: Int)
    case nonPositiveHintOrder(discoveryID: String, order: Int)
    case emptyHintText(discoveryID: String, hintID: String)
    case emptyRevealDescription(discoveryID: String)
    case invalidLatitude(discoveryID: String, value: Double)
    case invalidLongitude(discoveryID: String, value: Double)
    case invalidRadius(discoveryID: String, value: Double)
}
