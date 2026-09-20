import XCTest
@testable import ParkHunt

final class ContentCatalogTests: XCTestCase {
    func testBundledCatalogLoadsOffline() throws {
        let catalog = try BundledContentStore().loadCatalog()

        XCTAssertEqual(catalog.schemaVersion, ContentCatalog.currentSchemaVersion)
        XCTAssertFalse(catalog.lands.isEmpty)
        XCTAssertFalse(catalog.areas.isEmpty)
        XCTAssertFalse(catalog.discoveries.isEmpty)
    }

    func testCatalogRoundTripsThroughJSON() throws {
        let catalog = makeCatalog()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(catalog)
        let decoded = try ContentCatalogCodec.decode(data)

        XCTAssertEqual(decoded, catalog)
    }

    func testCodecRejectsUnsupportedSchemaVersion() throws {
        let catalog = ContentCatalog(
            schemaVersion: 999,
            lands: [],
            areas: [],
            discoveries: []
        )
        let data = try JSONEncoder().encode(catalog)

        XCTAssertThrowsError(try ContentCatalogCodec.decode(data)) { error in
            guard case let ContentStoreError.validationFailed(issues) = error else {
                return XCTFail("Expected validationFailed, got \(error)")
            }

            XCTAssertTrue(
                issues.contains(
                    .unsupportedSchemaVersion(
                        expected: ContentCatalog.currentSchemaVersion,
                        actual: 999
                    )
                )
            )
        }
    }

    func testValidatorRejectsDuplicateAndBrokenReferences() {
        let land = Land(
            id: "land-a",
            parkID: "park",
            name: "Land A",
            sortOrder: 1
        )
        let area = AttractionArea(
            id: "area-a",
            landID: "missing-land",
            name: "Area A",
            kind: .area,
            sortOrder: 1
        )
        let discovery = makeDiscovery(
            id: "secret-a",
            landID: "land-a",
            areaID: "area-a"
        )
        let catalog = ContentCatalog(
            schemaVersion: ContentCatalog.currentSchemaVersion,
            lands: [land, land],
            areas: [area],
            discoveries: [discovery, discovery]
        )

        let issues = ContentCatalogValidator.validate(catalog)

        XCTAssertTrue(issues.contains(.duplicateLandID("land-a")))
        XCTAssertTrue(issues.contains(.duplicateDiscoveryID("secret-a")))
        XCTAssertTrue(
            issues.contains(
                .unknownLandReference(
                    entityID: "area-a",
                    landID: "missing-land"
                )
            )
        )
        XCTAssertTrue(
            issues.contains(
                .areaLandMismatch(
                    discoveryID: "secret-a",
                    areaID: "area-a",
                    discoveryLandID: "land-a",
                    areaLandID: "missing-land"
                )
            )
        )
    }

    func testFileStoreLoadsCatalogWithoutNetwork() throws {
        let catalog = makeCatalog()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(catalog)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("catalog.json")
        try data.write(to: url)

        XCTAssertEqual(try FileContentStore(url: url).loadCatalog(), catalog)
    }

    private func makeCatalog() -> ContentCatalog {
        let land = Land(
            id: "land-a",
            parkID: "park",
            name: "Land A",
            sortOrder: 1
        )
        let area = AttractionArea(
            id: "area-a",
            landID: land.id,
            name: "Area A",
            kind: .area,
            sortOrder: 1
        )

        return ContentCatalog(
            schemaVersion: ContentCatalog.currentSchemaVersion,
            lands: [land],
            areas: [area],
            discoveries: [
                makeDiscovery(
                    id: "secret-a",
                    landID: land.id,
                    areaID: area.id
                )
            ]
        )
    }

    private func makeDiscovery(
        id: String,
        landID: String,
        areaID: String?
    ) -> Discovery {
        Discovery(
            id: id,
            title: "Secret",
            parkID: "park",
            landID: landID,
            areaID: areaID,
            category: .easterEgg,
            difficulty: .medium,
            location: DiscoveryLocation(
                latitude: 33.81,
                longitude: -117.92,
                radiusMeters: 75
            ),
            hints: [
                Hint(id: "\(id)-h1", order: 1, text: "Look around.")
            ],
            revealDescription: "Reveal.",
            revealImageName: nil,
            verificationStatus: .verified,
            lastVerifiedAt: Date(timeIntervalSince1970: 1_700_000_000),
            isIndoor: false,
            tags: []
        )
    }
}
