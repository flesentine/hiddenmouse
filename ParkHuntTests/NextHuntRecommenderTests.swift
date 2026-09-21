import XCTest
@testable import ParkHunt

final class NextHuntRecommenderTests: XCTestCase {
    func testPrefersUnfinishedDiscoveryInSameArea() {
        let current = makeDiscovery(
            id: "current",
            landID: "land-a",
            areaID: "area-a",
            latitude: 33.8119
        )
        let sameArea = makeDiscovery(
            id: "same-area",
            landID: "land-a",
            areaID: "area-a",
            latitude: 33.8125
        )
        let sameLand = makeDiscovery(
            id: "same-land",
            landID: "land-a",
            areaID: nil,
            latitude: 33.8120
        )
        let snapshot = makeSnapshot(
            discoveries: [current, sameLand, sameArea]
        )
        var progress = UserProgress()
        progress.recordFound(discoveryID: current.id)

        let result = NextHuntRecommender.select(
            currentDiscovery: current,
            snapshot: snapshot,
            progress: progress
        )

        XCTAssertEqual(result?.discovery.id, "same-area")
    }

    func testSkipsAlreadyFoundDiscovery() {
        let current = makeDiscovery(
            id: "current",
            latitude: 33.8119
        )
        let foundNearby = makeDiscovery(
            id: "found-nearby",
            latitude: 33.81191
        )
        let unfinished = makeDiscovery(
            id: "unfinished",
            latitude: 33.8120
        )
        let snapshot = makeSnapshot(
            discoveries: [current, foundNearby, unfinished]
        )
        var progress = UserProgress()
        progress.recordFound(discoveryID: current.id)
        progress.recordFound(discoveryID: foundNearby.id)

        let result = NextHuntRecommender.select(
            currentDiscovery: current,
            snapshot: snapshot,
            progress: progress
        )

        XCTAssertEqual(result?.discovery.id, "unfinished")
    }

    func testCurrentDiscoveryIsNeverRepeated() {
        let current = makeDiscovery(
            id: "current",
            latitude: 33.8119
        )
        let snapshot = makeSnapshot(
            discoveries: [current]
        )
        let progress = UserProgress()

        XCTAssertNil(
            NextHuntRecommender.select(
                currentDiscovery: current,
                snapshot: snapshot,
                progress: progress
            )
        )
    }

    func testFarDiscoveryIsNotRecommendedWhenCoordinatesExist() {
        let current = makeDiscovery(
            id: "current",
            latitude: 33.8119
        )
        let far = makeDiscovery(
            id: "far",
            latitude: 33.8400
        )
        let snapshot = makeSnapshot(
            discoveries: [current, far]
        )

        XCTAssertNil(
            NextHuntRecommender.select(
                currentDiscovery: current,
                snapshot: snapshot,
                progress: UserProgress()
            )
        )
    }

    func testMissingCoordinatesFallsBackToLandAndParkContext() {
        let current = makeDiscovery(
            id: "current",
            landID: "land-a",
            areaID: nil,
            latitude: nil
        )
        let sameLand = makeDiscovery(
            id: "same-land",
            landID: "land-a",
            areaID: nil,
            latitude: nil
        )
        let otherLand = makeDiscovery(
            id: "other-land",
            landID: "land-b",
            areaID: "area-b",
            latitude: nil
        )
        let snapshot = makeSnapshot(
            discoveries: [current, otherLand, sameLand]
        )

        let result = NextHuntRecommender.select(
            currentDiscovery: current,
            snapshot: snapshot,
            progress: UserProgress()
        )

        XCTAssertEqual(result?.discovery.id, "same-land")
    }

    func testAllEligibleHuntsCompletedReturnsNil() {
        let current = makeDiscovery(
            id: "current",
            latitude: 33.8119
        )
        let other = makeDiscovery(
            id: "other",
            latitude: 33.8120
        )
        let snapshot = makeSnapshot(
            discoveries: [current, other]
        )
        var progress = UserProgress()
        progress.recordFound(discoveryID: current.id)
        progress.recordFound(discoveryID: other.id)

        XCTAssertNil(
            NextHuntRecommender.select(
                currentDiscovery: current,
                snapshot: snapshot,
                progress: progress
            )
        )
    }

    func testDistanceTextUsesMetersAndKilometers() {
        XCTAssertEqual(
            NextHuntRecommender.distanceText(126),
            "130 m"
        )
        XCTAssertEqual(
            NextHuntRecommender.distanceText(1_250),
            "1.2 km"
        )
    }

    private func makeSnapshot(
        discoveries: [Discovery]
    ) -> ContentSnapshot {
        let landA = Land(
            id: "land-a",
            parkID: "park",
            name: "Land A",
            sortOrder: 1
        )
        let landB = Land(
            id: "land-b",
            parkID: "park",
            name: "Land B",
            sortOrder: 2
        )
        let areaA = AttractionArea(
            id: "area-a",
            landID: landA.id,
            name: "Area A",
            kind: .area,
            sortOrder: 1
        )
        let areaB = AttractionArea(
            id: "area-b",
            landID: landB.id,
            name: "Area B",
            kind: .area,
            sortOrder: 1
        )

        return ContentSnapshot(
            catalog: ContentCatalog(
                schemaVersion: ContentCatalog.currentSchemaVersion,
                lands: [landA, landB],
                areas: [areaA, areaB],
                discoveries: discoveries
            )
        )
    }

    private func makeDiscovery(
        id: String,
        landID: String = "land-a",
        areaID: String? = "area-a",
        latitude: Double?
    ) -> Discovery {
        Discovery(
            id: id,
            title: id,
            parkID: "park",
            landID: landID,
            areaID: areaID,
            category: .secretFeature,
            difficulty: .medium,
            location: latitude.map {
                DiscoveryLocation(
                    latitude: $0,
                    longitude: -117.9190,
                    radiusMeters: 100
                )
            },
            hints: [
                Hint(id: "\(id)-h1", order: 1, text: "Look nearby.")
            ],
            revealDescription: "Reveal.",
            revealImageName: nil,
            verificationStatus: .verified,
            lastVerifiedAt: nil,
            isIndoor: false,
            tags: []
        )
    }
}
