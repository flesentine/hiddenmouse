import XCTest
@testable import ParkHunt

final class DomainModelTests: XCTestCase {
    func testDiscoveryRoundTripsThroughJSON() throws {
        let discovery = makeDiscovery()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(discovery)
        let decoded = try decoder.decode(Discovery.self, from: data)

        XCTAssertEqual(decoded, discovery)
    }

    func testHintsHaveDeterministicProgressionOrder() {
        let discovery = makeDiscovery(
            hints: [
                Hint(id: "h3", order: 3, text: "Detailed clue"),
                Hint(id: "h1", order: 1, text: "First clue"),
                Hint(id: "h2", order: 2, text: "Second clue")
            ]
        )

        XCTAssertEqual(discovery.sortedHints.map(\.id), ["h1", "h2", "h3"])
    }

    func testValidDiscoveryHasNoValidationIssues() {
        XCTAssertTrue(DomainValidator.validate(makeDiscovery()).isEmpty)
    }

    func testValidatorRejectsBadCoordinatesRadiusAndHintOrdering() {
        let discovery = makeDiscovery(
            location: DiscoveryLocation(
                latitude: 95,
                longitude: -181,
                radiusMeters: 0
            ),
            hints: [
                Hint(id: "same", order: 1, text: "One"),
                Hint(id: "same", order: 1, text: "Two")
            ]
        )

        let issues = DomainValidator.validate(discovery)

        XCTAssertTrue(issues.contains(.duplicateHintIdentifier(discoveryID: discovery.id)))
        XCTAssertTrue(issues.contains(.duplicateHintOrder(discoveryID: discovery.id, order: 1)))
        XCTAssertTrue(issues.contains(.invalidLatitude(discoveryID: discovery.id, value: 95)))
        XCTAssertTrue(issues.contains(.invalidLongitude(discoveryID: discovery.id, value: -181)))
        XCTAssertTrue(issues.contains(.invalidRadius(discoveryID: discovery.id, value: 0)))
    }

    func testUserProgressSeparatesFoundAndUnfoundDiscoveries() {
        let foundAt = Date(timeIntervalSince1970: 1_700_000_000)
        let progress = UserProgress(
            discoveries: [
                "found": DiscoveryProgress(discoveryID: "found", foundAt: foundAt),
                "looking": DiscoveryProgress(
                    discoveryID: "looking",
                    highestHintOrderViewed: 2
                )
            ],
            lastUpdatedAt: foundAt
        )

        XCTAssertEqual(progress.foundDiscoveryIDs, Set(["found"]))
        XCTAssertTrue(progress.progress(for: "found").isFound)
        XCTAssertFalse(progress.progress(for: "looking").isFound)
        XCTAssertFalse(progress.progress(for: "new").isFound)
    }

    func testPlaceModelsRoundTripThroughJSON() throws {
        let land = Land(
            id: "new-orleans-square",
            parkID: "disneyland",
            name: "New Orleans Square",
            sortOrder: 2
        )
        let area = AttractionArea(
            id: "pirates",
            landID: land.id,
            name: "Pirates of the Caribbean",
            kind: .attraction,
            sortOrder: 1
        )

        let encodedLand = try JSONEncoder().encode(land)
        let encodedArea = try JSONEncoder().encode(area)

        XCTAssertEqual(try JSONDecoder().decode(Land.self, from: encodedLand), land)
        XCTAssertEqual(try JSONDecoder().decode(AttractionArea.self, from: encodedArea), area)
    }

    private func makeDiscovery(
        location: DiscoveryLocation? = DiscoveryLocation(
            latitude: 33.8119,
            longitude: -117.9190,
            radiusMeters: 75
        ),
        hints: [Hint] = [
            Hint(id: "h1", order: 1, text: "Look above eye level."),
            Hint(id: "h2", order: 2, text: "Look near the attraction entrance.")
        ]
    ) -> Discovery {
        Discovery(
            id: "prototype-secret-001",
            title: "Prototype Secret",
            parkID: "disneyland",
            landID: "new-orleans-square",
            areaID: "pirates",
            category: .hiddenMickey,
            difficulty: .medium,
            location: location,
            hints: hints,
            revealDescription: "The exact reveal description goes here.",
            revealImageName: "prototype-secret-001",
            verificationStatus: .verified,
            lastVerifiedAt: Date(timeIntervalSince1970: 1_700_000_000),
            isIndoor: false,
            tags: ["prototype"]
        )
    }
}
