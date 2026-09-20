import Foundation

enum ContentCatalogValidator {
    static func validate(_ catalog: ContentCatalog) -> [ContentCatalogValidationIssue] {
        var issues: [ContentCatalogValidationIssue] = []

        if catalog.schemaVersion != ContentCatalog.currentSchemaVersion {
            issues.append(
                .unsupportedSchemaVersion(
                    expected: ContentCatalog.currentSchemaVersion,
                    actual: catalog.schemaVersion
                )
            )
        }

        issues.append(
            contentsOf: duplicateIDs(in: catalog.lands, id: \.id).map {
                .duplicateLandID($0)
            }
        )
        issues.append(
            contentsOf: duplicateIDs(in: catalog.areas, id: \.id).map {
                .duplicateAreaID($0)
            }
        )
        issues.append(
            contentsOf: duplicateIDs(in: catalog.discoveries, id: \.id).map {
                .duplicateDiscoveryID($0)
            }
        )

        for land in catalog.lands {
            issues.append(contentsOf: DomainValidator.validate(land).map(ContentCatalogValidationIssue.domain))
        }

        for area in catalog.areas {
            issues.append(contentsOf: DomainValidator.validate(area).map(ContentCatalogValidationIssue.domain))
        }

        for discovery in catalog.discoveries {
            issues.append(contentsOf: DomainValidator.validate(discovery).map(ContentCatalogValidationIssue.domain))
        }

        let landByID = Dictionary(grouping: catalog.lands, by: \.id).mapValues { $0[0] }
        let areaByID = Dictionary(grouping: catalog.areas, by: \.id).mapValues { $0[0] }

        for area in catalog.areas where landByID[area.landID] == nil {
            issues.append(
                .unknownLandReference(
                    entityID: area.id,
                    landID: area.landID
                )
            )
        }

        for discovery in catalog.discoveries {
            if landByID[discovery.landID] == nil {
                issues.append(
                    .unknownLandReference(
                        entityID: discovery.id,
                        landID: discovery.landID
                    )
                )
            }

            guard let areaID = discovery.areaID else {
                continue
            }

            guard let area = areaByID[areaID] else {
                issues.append(
                    .unknownAreaReference(
                        discoveryID: discovery.id,
                        areaID: areaID
                    )
                )
                continue
            }

            if area.landID != discovery.landID {
                issues.append(
                    .areaLandMismatch(
                        discoveryID: discovery.id,
                        areaID: area.id,
                        discoveryLandID: discovery.landID,
                        areaLandID: area.landID
                    )
                )
            }
        }

        return issues
    }

    private static func duplicateIDs<T>(
        in values: [T],
        id: (T) -> String
    ) -> [String] {
        var seen: Set<String> = []
        var duplicates: Set<String> = []

        for value in values {
            let identifier = id(value)
            if !seen.insert(identifier).inserted {
                duplicates.insert(identifier)
            }
        }

        return duplicates.sorted()
    }
}

enum ContentCatalogValidationIssue: Equatable, Sendable {
    case unsupportedSchemaVersion(expected: Int, actual: Int)
    case duplicateLandID(String)
    case duplicateAreaID(String)
    case duplicateDiscoveryID(String)
    case unknownLandReference(entityID: String, landID: String)
    case unknownAreaReference(discoveryID: String, areaID: String)
    case areaLandMismatch(
        discoveryID: String,
        areaID: String,
        discoveryLandID: String,
        areaLandID: String
    )
    case domain(DomainValidationIssue)
}
