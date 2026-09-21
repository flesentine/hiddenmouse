import XCTest
@testable import ParkHunt

final class NearbyContextResolverTests: XCTestCase {
    func testNearDiscoveryResolvesLandAndArea() {
        let snapshot = makeSnapshot()
        let fix = LocationFix(
            latitude: 33.8119,
            longitude: -117.9190,
            horizontalAccuracyMeters: 20,
            timestamp: Date()
        )

        let context = NearbyContextResolver.resolve(
            fix: fix,
            snapshot: snapshot
        )

        XCTAssertEqual(context?.parkID, "disneyland")
        XCTAssertEqual(context?.landID, "new-orleans-square")
        XCTAssertEqual(context?.landName, "New Orleans Square")
        XCTAssertEqual(context?.areaID, "pirates")
        XCTAssertEqual(context?.areaName, "Pirates of the Caribbean")
        XCTAssertEqual(context?.nearestDiscoveryID, "secret")
    }

    func testFartherWithinParkRangeResolvesLandWithoutArea() {
        let snapshot = makeSnapshot()
        let fix = LocationFix(
            latitude: 33.8180,
            longitude: -117.9190,
            horizontalAccuracyMeters: 20,
            timestamp: Date()
        )

        let context = NearbyContextResolver.resolve(
            fix: fix,
            snapshot: snapshot
        )

        XCTAssertEqual(context?.landID, "new-orleans-square")
        XCTAssertNil(context?.areaID)
        XCTAssertNil(context?.areaName)
    }

    func testTooFarFromCatalogReturnsNil() {
        let snapshot = makeSnapshot()
        let fix = LocationFix(
            latitude: 33.6500,
            longitude: -117.7500,
            horizontalAccuracyMeters: 20,
            timestamp: Date()
        )

        XCTAssertNil(
            NearbyContextResolver.resolve(
                fix: fix,
                snapshot: snapshot
            )
        )
    }

    func testDistanceCalculationIsZeroForSameCoordinate() {
        XCTAssertEqual(
            NearbyContextResolver.distanceMeters(
                fromLatitude: 33.8119,
                longitude: -117.9190,
                toLatitude: 33.8119,
                longitude: -117.9190
            ),
            0,
            accuracy: 0.001
        )
    }

    private func makeSnapshot() -> ContentSnapshot {
        let land = Land(
            id: "new-orleans-square",
            parkID: "disneyland",
            name: "New Orleans Square",
            sortOrder: 1
        )
        let area = AttractionArea(
            id: "pirates",
            landID: land.id,
            name: "Pirates of the Caribbean",
            kind: .attraction,
            sortOrder: 1
        )
        let discovery = Discovery(
            id: "secret",
            title: "Secret",
            parkID: "disneyland",
            landID: land.id,
            areaID: area.id,
            category: .hiddenMickey,
            difficulty: .easy,
            location: DiscoveryLocation(
                latitude: 33.8119,
                longitude: -117.9190,
                radiusMeters: 100
            ),
            hints: [
                Hint(id: "h1", order: 1, text: "Look nearby.")
            ],
            revealDescription: "Reveal.",
            revealImageName: nil,
            verificationStatus: .verified,
            lastVerifiedAt: nil,
            isIndoor: false,
            tags: []
        )

        return ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: [land],
                areas: [area],
                discoveries: [discovery]
            )
        )
    }
}
